class DailyDigestInitiatorWorker < ApplicationWorker
  sidekiq_retry_in do |count|
    60 * (count + 1)
  end

  sidekiq_options retry: 3

  def perform(date = Date.current.to_s)
    run_with_advisory_lock(DigestRun, "#{date}-#{Frequency::DAILY}") do
      DigestInitiatorService.call(date: Date.parse(date), range: Frequency::DAILY)
    end
  end
end
