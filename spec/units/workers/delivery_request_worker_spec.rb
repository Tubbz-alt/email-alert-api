RSpec.describe DeliveryRequestWorker do
  class FakeLimiter
    def run
      yield
    end
  end

  let(:email_sender) { double }
  let(:fake_limiter) { FakeLimiter.new }

  before do
    Sidekiq::Worker.clear_all
    allow(email_sender).to receive(:provider_name).and_return(:pseudo)
    allow(Services).to receive(:email_sender).and_return(
      email_sender
    )
  end

  describe ".perform" do
    let(:email) { create(:email) }

    context "with an email and a subscriber" do
      it "sends the email to the subscriber" do
        expect(email_sender).to receive(:call)
          .with(
            address: email.address,
            subject: email.subject,
            body: email.body
          ).and_return(double(id: 0))

        subject.perform(email.id)
      end
    end

    context "with rate limit exceeded" do
      it "raises a RatelimitExceededError" do
        allow(Services).to receive(:rate_limiter).and_return(rate_limit = double)
        allow(rate_limit).to receive(:exceeded?).and_return(true)
        expect {
          subject.perform(email.id)
        }.to raise_error(RatelimitExceededError)
      end
    end
  end

  describe ".perform_async_with_priority" do
    let(:email) { double(id: 0) }
    let(:priority) { nil }

    before do
      Sidekiq::Testing.fake!
      described_class.perform_async_with_priority(
        email.id, priority: priority
      )
    end

    context "with a low priority" do
      let(:priority) { :low }

      it "adds a worker to the low priority queue" do
        expect(Sidekiq::Queues["low_delivery"].size).to eq(1)
      end
    end

    context "with a high priority" do
      let(:priority) { :high }

      it "adds a worker to the high priority queue" do
        expect(Sidekiq::Queues["high_delivery"].size).to eq(1)
      end
    end
  end
end
