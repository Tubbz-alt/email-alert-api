RSpec.describe ImmediateEmailGenerationWorker do
  describe ".call" do
    def perform_with_fake_sidekiq
      Sidekiq::Testing.fake! do
        DeliveryRequestWorker.jobs.clear
        described_class.new.perform
      end
    end

    context "with many subscription contents" do
      before do
        50.times do
          create(:subscription_content)
        end
      end

      it "should match up with the right emails" do
        perform_with_fake_sidekiq

        SubscriptionContent.all.find_each do |subscription_content|
          expect(subscription_content.email.address)
            .to eq(subscription_content.subscription.subscriber.address)
        end
      end
    end

    context "with a subscription content" do
      let!(:subscription_content) { create(:subscription_content) }

      before do
        create(:subscription_content, email: create(:email))
        create(:subscription_content, subscription: create(:subscription, subscriber: create(:subscriber, address: nil)))
      end

      it "should create an email" do
        expect {
          perform_with_fake_sidekiq
        }
          .to change { Email.count }
          .from(1)
          .to(2)
      end

      it "should associate the subscription content with the email" do
        perform_with_fake_sidekiq
        expect(subscription_content.reload.email).to_not be_nil
      end

      it "should queue a delivery email job" do
        perform_with_fake_sidekiq
        expect(DeliveryRequestWorker.jobs.size).to eq(1)
      end

      context "with a high priority content change" do
        before do
          subscription_content.content_change.update(priority: "high")
        end

        it "should queue a delivery email job with a high priority" do
          expect(DeliveryRequestWorker).to receive(:perform_async_in_queue)
            .with(an_instance_of(Integer), queue: :delivery_immediate_high)

          perform_with_fake_sidekiq
        end
      end
    end
  end
end