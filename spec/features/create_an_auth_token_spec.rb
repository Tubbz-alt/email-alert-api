RSpec.describe "Create an auth token", type: :request do
  include TokenHelpers

  around do |example|
    Sidekiq::Testing.inline! do
      freeze_time { example.run }
    end
  end

  let(:address) { "test@example.com" }
  let!(:subscriber) { create(:subscriber, address: address) }
  let(:destination) { "/authenticate" }

  scenario "successful auth token" do
    login_with_internal_app

    post "/subscribers/auth-token",
         params: {
           address: address,
           destination: destination,
         }

    notify_email_stub = notify_email(subscriber, destination)
    expect(response.status).to be 201
    expect(notify_email_stub).to have_been_requested
  end

  def notify_email(subscriber, destination)
    stub_request(:post, "https://api.notifications.service.gov.uk/v2/notifications/email")
      .with(
        "body" => hash_including(
          "email_address" => subscriber.address,
          "personalisation" => hash_including(
            "subject" => "Manage your GOV.UK email subscriptions",
            "body" => include("http://www.dev.gov.uk#{destination}?token="),
          ),
        ),
      )
      .with do |request|
        token = request.body.match(/token=([^&\\]+)/)[1]

        expect(decrypt_and_verify_token(token)).to eq(
          "subscriber_id" => subscriber.id,
        )
      end
  end
end
