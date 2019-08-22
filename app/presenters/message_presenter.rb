class MessagePresenter
  def initialize(message, frequency: "immediate")
    @message = message
    @frequency = frequency
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    [
      title_markdown,
      body,
    ].compact.join("\n\n") + "\n"
  end

  private_class_method :new

private

  attr_reader :message, :frequency

  delegate :title, :body, :url, to: :message

  def content_url
    query = {
      utm_source: message.id,
      utm_medium: "email",
      utm_campaign: "govuk-notifications-message",
      utm_content: frequency,
    }.to_query

    tracked_url = url + (url.include?("?") ? "&" : "?") + query

    PublicUrlService.url_for(base_path: tracked_url)
  end

  def title_markdown
    return title unless url

    "[#{title}](#{content_url})"
  end
end
