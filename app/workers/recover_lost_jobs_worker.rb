class RecoverLostJobsWorker
  include Sidekiq::Worker

  def perform
    recover(ProcessContentChangeWorker, old_unprocessed(ContentChange).pluck(:id))
    recover(ProcessMessageWorker, old_unprocessed(Message).pluck(:id))
    recover(DigestEmailGenerationWorker, old_unprocessed(DigestRunSubscriber).pluck(:id))
    recover(DailyDigestInitiatorWorker, old_unprocessed(DigestRun.daily).pluck(:date).map(&:to_s))
    recover(WeeklyDigestInitiatorWorker, old_unprocessed(DigestRun.weekly).pluck(:date).map(&:to_s))
  end

private

  def old_unprocessed(scope)
    scope.where(processed_at: nil).where("created_at <= ?", 1.hour.ago)
  end

  def recover(worker, work)
    work.each { |arg| worker.perform_async(arg) }
  end
end
