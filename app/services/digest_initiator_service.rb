class DigestInitiatorService
  def initialize(range:)
    @range = range
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    digest_run = create_digest_run
    return if digest_run.nil?

    MetricsService.digest_initiator_service(range) do
      subscriber_ids = DigestRunSubscriberQuery.call(digest_run: digest_run).pluck(:id)

      subscriber_ids.each_slice(1000) do |subscriber_ids_chunk|
        digest_run_subscriber_params = build_digest_run_subscriber_params(
          digest_run.id,
          subscriber_ids_chunk
        )

        digest_run_subscriber_ids = import_digest_run_subscribers(
          digest_run_subscriber_params
        )

        enqueue_jobs(digest_run_subscriber_ids)
      end

      digest_run.update(subscriber_count: subscriber_ids.count)
    end
  end

  private_class_method :new

private

  attr_reader :range

  def create_digest_run
    run_with_advisory_lock do
      digest_run = DigestRun.find_or_initialize_by(
        date: Date.current, range: range
      )
      return if digest_run.persisted?

      digest_run.save!
      digest_run
    end
  end

  def enqueue_jobs(digest_run_subscriber_ids)
    Array(digest_run_subscriber_ids).each do |digest_run_subscriber_id|
      DigestEmailGenerationWorker.perform_async(digest_run_subscriber_id)
    end
  end

  def run_with_advisory_lock
    DigestRun.with_advisory_lock(lock_name, timeout_seconds: 0) do
      yield
    end
  end

  def lock_name
    "#{range}_digest_initiator"
  end

  def build_digest_run_subscriber_params(digest_run_id, subscriber_ids)
    subscriber_ids.map do |subscriber_id|
      [subscriber_id, digest_run_id]
    end
  end

  def import_digest_run_subscribers(params)
    columns = %i(subscriber_id digest_run_id)
    DigestRunSubscriber.import!(columns, params).ids
  end
end
