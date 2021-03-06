class BulkSubscriberListEmailBuilder < ApplicationBuilder
  def initialize(subject:, body:, subscriber_lists:)
    @subject = subject
    @body = body
    @subscriber_lists = subscriber_lists
  end

  def call
    records.any? ? Email.insert_all!(records).pluck("id") : []
  end

private

  attr_reader :subject, :body, :subscriber_lists

  def records
    @records ||= begin
      now = Time.zone.now
      subscribers.map do |address, subscriber_id|
        {
          address: address,
          subject: subject,
          body: body,
          subscriber_id: subscriber_id,
          created_at: now,
          updated_at: now,
        }
      end
    end
  end

  def subscribers
    Subscriber
      .not_nullified
      .joins(:subscriptions)
      .where(subscriptions: { ended_at: nil, subscriber_list: subscriber_lists })
      .distinct
      .pluck(:address, :id)
  end
end
