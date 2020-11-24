RSpec.describe "support" do
  describe "get_notifications_from_notify_by_email_id" do
    before { stub_request(:get, /notify/).to_return(status: 404) }

    it "outputs the status of notifications with a specified email ID" do
      expect { Rake::Task["support:get_notifications_from_notify_by_email_id"].invoke("1") }
        .to output.to_stdout
    end
  end

  describe "send_test_email" do
    it "queues a test email to a test email address" do
      expect(SendEmailWorker).to receive(:perform_async_in_queue)

      expect { Rake::Task["support:send_test_email"].invoke("foo@bar.com") }
        .to change { Email.count }.by 1
    end
  end

  describe "resend_failed_emails:by_id" do
    before { Rake::Task["support:resend_failed_emails:by_id"].reenable }

    it "queues specified failed emails to resend" do
      email = create :email, status: :failed

      expect(SendEmailWorker).to receive(:perform_async_in_queue)
        .with(email.id, queue: :send_email_immediate_high)

      expect { Rake::Task["support:resend_failed_emails:by_id"].invoke(email.id.to_s) }
        .to output.to_stdout
    end

    it "updates the failed emails' status to pending" do
      allow(SendEmailWorker).to receive(:perform_async_in_queue)

      email = create :email, status: :failed

      freeze_time do
        expect { Rake::Task["support:resend_failed_emails:by_id"].invoke(email.id.to_s) }
          .to output.to_stdout
          .and change { email.reload.status }.to("pending")
          .and change { email.reload.updated_at }.to(Time.zone.now)
      end
    end
  end

  describe "resend_failed_emails:by_date" do
    before { Rake::Task["support:resend_failed_emails:by_date"].reenable }

    let(:from) { 1.day.ago.iso8601 }
    let(:to) { 1.day.from_now.iso8601 }

    it "queues specified failed emails to resend" do
      email = create :email, status: :failed

      expect(SendEmailWorker).to receive(:perform_async_in_queue)
        .with(email.id, queue: :send_email_immediate_high)

      expect { Rake::Task["support:resend_failed_emails:by_date"].invoke(from, to) }
        .to output.to_stdout
    end

    it "updates the failed emails' status to pending" do
      allow(SendEmailWorker).to receive(:perform_async_in_queue)

      email = create :email, status: :failed

      freeze_time do
        expect { Rake::Task["support:resend_failed_emails:by_date"].invoke(from, to) }
          .to output.to_stdout
          .and change { email.reload.status }.to("pending")
          .and change { email.reload.updated_at }.to(Time.zone.now)
      end
    end
  end
end
