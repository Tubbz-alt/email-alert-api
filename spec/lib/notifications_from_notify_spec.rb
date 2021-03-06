RSpec.describe NotificationsFromNotify do
  describe "notifications report" do
    context "when passing a reference which is found" do
      let!(:notifications_collection) { build :client_notifications_collection }
      let(:reference) { "ref_123" }

      before do
        stub_request(
          :get,
          "https://api.notifications.service.gov.uk/v2/notifications?template_type=email&reference=#{reference}",
        ).to_return(body: mocked_response.to_json)
      end

      let(:mocked_response) do
        attributes_for(
          :client_notifications_collection,
        )[:body]
      end

      it "prints details about one notification" do
        # We generate a unique reference for each email sent so we should only
        # expect to return one notification within the collection
        client = instance_double("Notifications::Client")
        notification = notifications_collection.collection.first
        allow(client).to receive(:get_notifications).and_return(notifications_collection)

        expect { described_class.call(reference) }
        .to output(
          <<~TEXT,
            Query Notify for emails with the reference #{reference}
            -------------------------------------------
            Notification ID: #{notification.id}
            Status: #{notification.status}
            created_at: #{notification.created_at}
            sent_at: #{notification.sent_at}
            completed_at: #{notification.completed_at}
          TEXT
        ).to_stdout
      end
    end

    context "when passing a reference which is not found" do
      let!(:empty_client_notifications_collection) { build :empty_client_notifications_collection }
      let(:reference) { "PPP" }

      before do
        stub_request(
          :get,
          "https://api.notifications.service.gov.uk/v2/notifications?template_type=email&reference=#{reference}",
        ).to_return(body: empty_response.to_json)
      end

      let(:empty_response) do
        attributes_for(:empty_client_notifications_collection)[:body]
      end

      it "does not return any notifications" do
        client = instance_double("Notifications::Client")
        allow(client).to receive(:get_notifications).and_return(empty_client_notifications_collection)

        expect { described_class.call(reference) }
        .to output(
          <<~TEXT,
            Query Notify for emails with the reference #{reference}
            No results found, empty collection returned
          TEXT
        ).to_stdout
      end
    end

    context "when passing a reference is not successful" do
      let!(:client_request_error) { build :client_request_error }
      let(:reference) { "ref_123" }

      before do
        stub_request(
          :get,
          "https://api.notifications.service.gov.uk/v2/notifications?template_type=email&reference=#{reference}",
        ).to_return(
          status: 400,
          body: error_response.to_json,
        )
      end

      let(:error_response) do
        attributes_for(:client_request_error)[:body]
      end

      it "returns a request error" do
        client = instance_double("Notifications::Client")
        error = client_request_error
        allow(client).to receive(:get_notifications).and_raise(client_request_error)

        expect { described_class.call(reference) }
        .to output(
          <<~TEXT,
            Query Notify for emails with the reference #{reference}
            Returns request error #{error.code}, message: #{error.message}
          TEXT
        ).to_stdout
      end
    end
  end
end
