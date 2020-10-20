RSpec.describe HistoricalDataDeletionWorker do
  describe "#perform" do
    let(:historic_date) { 2.years.ago }

    def perform
      described_class.new.perform
    end

    context "when deleting content changes" do
      it "should remove all old content changes" do
        create(:content_change, created_at: historic_date)
        expect { perform }.to change(ContentChange, :count).by(-1)
      end

      it "shouldn't remove recent content changes" do
        create(:content_change)
        expect { perform }.to_not change(ContentChange, :count)
      end
    end

    context "when deleting messages" do
      it "should remove all old messages" do
        create(:message, created_at: historic_date)
        expect { perform }.to change(Message, :count).by(-1)
      end

      it "shouldn't remove recent messages" do
        create(:content_change)
        expect { perform }.to_not change(Message, :count)
      end
    end

    context "when deleting digest runs" do
      it "should remove all old digest runs" do
        create(:digest_run, created_at: historic_date)
        expect { perform }.to change(DigestRun, :count).by(-1)
      end

      it "shouldn't remove recent digest runs" do
        create(:digest_run)
        expect { perform }.to_not change(DigestRun, :count)
      end
    end

    context "when deleting subscriptions" do
      it "should remove all old subscriptions which have ended" do
        create(:subscription, ended_at: historic_date)
        expect { perform }.to change(Subscription, :count).by(-1)
      end

      it "shouldn't remove active subscriptions" do
        create(:subscription)
        expect { perform }.to_not change(Subscription, :count)
      end
    end

    context "when deleting subscriber lists" do
      it "should remove all old subscriber lists which have no subscriptions" do
        create(:subscriber_list, created_at: historic_date)
        expect { perform }.to change(SubscriberList, :count).by(-1)
      end

      it "should remove all old subscriber lists which have no recent active subscriptions" do
        subscriber_list = create(:subscriber_list, created_at: historic_date)
        create(:subscription, ended_at: historic_date, subscriber_list: subscriber_list)
        expect { perform }.to change(SubscriberList, :count).by(-1)
      end

      it "shouldn't remove subscriber lists which have active subscriptions" do
        create(:subscription)
        expect { perform }.to_not change(SubscriberList, :count)
      end

      it "shouldn't remove subscriber lists which have recent active subscriptions" do
        subscriber_list = create(:subscriber_list, created_at: historic_date)
        create(:subscription, ended_at: 1.week.ago, subscriber_list: subscriber_list)
        expect { perform }.to_not change(SubscriberList, :count)
      end
    end

    context "when deleting subscribers" do
      it "should remove all old deactivated subscribers" do
        create(:subscriber, deactivated_at: historic_date)
        expect { perform }.to change(Subscriber, :count).by(-1)
      end

      it "shouldn't remove active subscribers" do
        create(:subscriber)
        expect { perform }.to_not change(Subscriber, :count)
      end
    end
  end
end
