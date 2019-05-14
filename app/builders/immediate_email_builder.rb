class ImmediateEmailBuilder
  def initialize(recipients_and_content)
    @recipients_and_content = recipients_and_content
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    Email.import!(columns, records)
  end

  private_class_method :new

private

  attr_reader :recipients_and_content

  def records
    recipients_and_content.map do |recipient_and_content|
      [
        address = recipient_and_content.fetch(:address),
        subject(recipient_and_content.fetch(:content_change)),
        body(recipient_and_content.fetch(:content_change), recipient_and_content.fetch(:subscriptions), address),
        recipient_and_content.fetch(:subscriber_id),
      ]
    end
  end

  def columns
    %i(address subject body subscriber_id)
  end

  def subject(content_change)
    "GOV.UK update – #{content_change.title}"
  end

  def body(content_change, subscriptions, address)
    if Array(subscriptions).empty?
      <<~BODY
        #{presented_content_change(content_change)}
        ---
        #{feedback_link.strip}
      BODY
    else
      <<~BODY
        #{presented_content_change(content_change)}
        ---
        You’re getting this email because you subscribed to ‘#{subscriber_list_title(subscriptions)}’ updates on GOV.UK.

        #{presented_unsubscribe_links(subscriptions)}
        #{presented_manage_subscriptions_links(address)}

        &nbsp;

        #{feedback_link.strip}
      BODY
    end
  end

  def feedback_link
    <<~BODY
      ^Is this email useful? [Answer some questions to tell us more](https://www.smartsurvey.co.uk/s/govuk-email/?f=immediate).

      &nbsp;

      ^Do not reply to this email. Feedback? Visit #{Plek.new.website_root}/contact
    BODY
  end

  # Hacky but just for demonstration
  def subscriber_list_title(subscription)
    if subscription.or_joined_subscriber_list
      subscription.or_joined_subscriber_list.title
    else
      subscription.subscriber_list.title
    end
  end

  def presented_content_change(content_change)
    ContentChangePresenter.call(content_change, frequency: "immediate")
  end

  def presented_manage_subscriptions_links(address)
    ManageSubscriptionsLinkPresenter.call(address: address)
  end

  def presented_unsubscribe_links(subscriptions)
    links_array = subscriptions.map do |subscription|
      UnsubscribeLinkPresenter.call(
        id: subscription.id,
        title: subscriber_list_title(subscription),
      )
    end

    links_array.join("\n")
  end
end
