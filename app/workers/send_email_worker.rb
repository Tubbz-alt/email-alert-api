class SendEmailWorker < ApplicationWorker
  # More information around the rate limit can be found here ->
  # https://docs.publishing.service.gov.uk/manual/govuk-notify.html under "GOV.UK Emails".
  RATE_LIMIT_THRESHOLD = 21_600 # max requests in a minute, equates to 350 a second
  RATE_LIMIT_INTERVAL = 60

  sidekiq_options retry: 9

  sidekiq_retries_exhausted do |msg|
    Email.find_by(id: msg["args"].first, status: :pending)
         &.update!(status: :failed)
  end

  def perform(email_id, metrics, queue)
    if rate_limit_exceeded?
      logger.warn("Rescheduling email #{email_id} due to exceeding rate limit")
      SendEmailWorker.set(queue: queue || "send_email_immediate")
                           .perform_in(5.minutes, email_id, metrics, queue)
      return
    end

    ActiveRecord::Base.transaction do
      email = GovukStatsd.time("send_email_worker.lookup_email") do
        Email.lock.find_by(id: email_id, status: :pending)
      end
      return unless email

      GovukStatsd.time("send_email_worker.increment_rate_limiter") do
        increment_rate_limiter
      end

      GovukStatsd.time("send_email_worker.send_email") do
        SendEmailService.call(email: email, metrics: parsed_metrics(metrics))
      end
    end
  end

  def self.perform_async_in_queue(email_id, metrics = {}, queue:)
    set(queue: queue).perform_async(email_id, metrics, queue)
  end

private

  def rate_limit_exceeded?
    rate_limiter.exceeded?("requests",
                           threshold: RATE_LIMIT_THRESHOLD,
                           interval: RATE_LIMIT_INTERVAL)
  end

  # Sidekiq uses JSON for a workers arguments, so richer objects are not
  # available. This converts the scalar values to objects.
  def parsed_metrics(metrics)
    content_change_created_at = metrics["content_change_created_at"]
      &.then { |t| Time.zone.iso8601(t) }

    { content_change_created_at: content_change_created_at }.compact
  end

  def increment_rate_limiter
    rate_limiter.add("requests")
  end

  def rate_limiter
    Services.rate_limiter
  end
end
