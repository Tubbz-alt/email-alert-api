class ImmediateEmailGenerationWorker
  include Sidekiq::Worker

  sidekiq_options queue: :email_generation_immediate

  LOCK_NAME = "immediate_email_generation_worker".freeze

  attr_reader :content_changes

  def perform
    @content_changes = {}

    ensure_only_running_once do
      subscribers.find_in_batches do |group|
        # This pass through variable is a pain, refactor to make it a memoized method
        subscription_contents = grouped_subscription_contents(group.pluck(:id))
        update_content_change_cache(subscription_contents)
        import_and_associate_emails(group, subscription_contents)
      end
    end
  end

private

  # Here we create Email records that contain everything needed to send an email
  # and then mark the subscription contents with the email id
  # and then send the email ids off for sending
  def import_and_associate_emails(subscribers, subscription_contents)
    queue = []

    Subscriber.transaction do
      values = []

      email_ids = import_emails(subscribers, subscription_contents).ids

      subscriber_id_content_change_id_in_order = map_subscriber_content_change_id_in_order(subscribers, subscription_contents) do |subscriber, content_change_id|
        [subscriber.id, content_change_id]
      end

      email_ids.each_with_index do |email_id, i|
        subscriber_id = subscriber_id_content_change_id_in_order[i][0]
        content_change_id = subscriber_id_content_change_id_in_order[i][1]
        subscription_contents_in_this_email = subscription_contents[subscriber_id][content_change_id]

        queue << [email_id, content_changes[content_change_id].priority.to_sym]

        subscription_contents_in_this_email.each do |subscription_content|
          values << "(#{subscription_content.id}, '#{email_id}'::UUID)"
        end
      end

      update_subscription_contents(values)
    end

    queue_delivery_request_workers(queue)
  end

  def update_content_change_cache(subscription_contents)
    content_change_ids = subscription_contents.flat_map { |_k, v| v.keys }.uniq
    existing_content_change_ids = content_changes.keys
    missing_content_change_ids = content_change_ids - existing_content_change_ids

    if missing_content_change_ids.any?
      ContentChange.where(id: missing_content_change_ids).each do |cc|
        content_changes[cc.id] = cc
      end
    end
  end

  def ensure_only_running_once
    Subscriber.with_advisory_lock(LOCK_NAME, timeout_seconds: 0) do
      yield
    end
  end

  def queue_delivery_request_workers(queue)
    queue.each do |email_id, priority|
      DeliveryRequestWorker.perform_async_in_queue(
        email_id, queue: queue_for_priority(priority)
      )
    end
  end

  def queue_for_priority(priority)
    if priority == :high
      :delivery_immediate_high
    elsif priority == :normal
      :delivery_immediate
    else
      raise ArgumentError, "priority should be :high or :normal"
    end
  end


  # Here we get all the subscription content records for the subcscribers that
  # haven't been associated with an email record
  def grouped_subscription_contents(subscriber_ids)
    UnprocessedSubscriptionContentsBySubscriberQuery.call(subscriber_ids)
  end

  def subscribers
    # Here we grab subscribers where their subscription_content does not
    # have an associated Email record
    SubscribersForImmediateEmailQuery.call
  end


  def map_subscriber_content_change_id_in_order(subscribers, subscription_contents)
    subscribers.flat_map do |subscriber|
      subscription_contents[subscriber.id].keys.map do |content_change_id|
        yield subscriber, content_change_id
      end
    end
  end

  # This is where it generates the email records
  def import_emails(subscribers, subscription_contents)
    email_params = map_subscriber_content_change_id_in_order(subscribers, subscription_contents) do |subscriber, content_change_id|
      {
        address: subscriber.address,
        content_change: content_changes[content_change_id],
        subscriptions: subscription_contents[subscriber.id][content_change_id].map(&:subscription),
        subscriber_id: subscriber.id,
      }
    end

    ImmediateEmailBuilder.call(email_params)
  end

  def update_subscription_contents(values)
    ActiveRecord::Base.connection.execute(
      %(
        UPDATE subscription_contents SET email_id = v.email_id
        FROM (VALUES #{values.join(',')}) AS v(id, email_id)
        WHERE subscription_contents.id = v.id
      )
    )
  end
end
