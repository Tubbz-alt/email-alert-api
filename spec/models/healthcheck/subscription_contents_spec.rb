RSpec.describe Healthcheck::SubscriptionContents do
  context "between 09:30 and 10:30" do
    shared_examples "an ok healthcheck" do
      specify { expect(subject.status).to eq(:ok) }
      specify { expect(subject.message).to match(/0 created over 900 seconds ago/) }
    end

    shared_examples "a critical healthcheck" do
      specify { expect(subject.status).to eq(:critical) }
      specify { expect(subject.message).to match(/1 created over 900 seconds ago/) }
    end

    around do |example|
      Timecop.freeze("10:00") { example.run }
    end

    context "when a subscription content was created 10 minutes ago" do
      before do
        create(:subscription_content, created_at: 10.minutes.ago)
      end

      it_behaves_like "an ok healthcheck"
    end

    context "when a subscription content was created over 15 minutes ago" do
      before do
        create(:subscription_content, created_at: 16.minutes.ago)
      end

      it_behaves_like "a critical healthcheck"
    end
  end

  context "when not scheduled publishing time" do
    shared_examples "an ok healthcheck" do
      specify { expect(subject.status).to eq(:ok) }
      specify { expect(subject.message).to match(/0 created over 300 seconds ago/) }
    end

    shared_examples "a critical healthcheck" do
      specify { expect(subject.status).to eq(:critical) }
      specify { expect(subject.message).to match(/1 created over 300 seconds ago/) }
    end

    around do |example|
      Timecop.freeze("12:00") { example.run }
    end

    context "when a subscription content was created 10 seconds ago" do
      before do
        create(:subscription_content, created_at: 10.seconds.ago)
      end

      it_behaves_like "an ok healthcheck"
    end

    context "when a subscription content was created over 5 minutes ago" do
      before do
        create(:subscription_content, created_at: 6.minutes.ago)
      end

      it_behaves_like "a critical healthcheck"
    end
  end
end
