class SubscriptionConfirmationEmailBuilder
  def initialize(subscription:)
    @subscription = subscription
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    Email.create!(
      subject: subject,
      body: body,
      address: subscriber.address,
      subscriber_id: subscriber.id,
    )
  end

  private_class_method :new

private

  attr_reader :subscription

  def subscriber
    @subscriber ||= subscription.subscriber
  end

  def subscriber_list
    @subscriber_list ||= subscription.subscriber_list
  end

  def subject
    "You've subscribed to #{subscriber_list.title}"
  end

  def body
    title = if subscriber_list.url
              "[#{subscriber_list.title}](#{Plek.new.website_root}#{subscriber_list.url})"
            else
              subscriber_list.title
            end

    <<~BODY
      You’ll get an email each time there are changes to #{title}.

      #{subscriber_list.description}

      ---

      #{ManageSubscriptionsLinkPresenter.call(subscriber.address)}
    BODY
  end
end
