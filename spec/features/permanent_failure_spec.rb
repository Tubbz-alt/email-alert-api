RSpec.describe "Failing to deliver an email via Notify (permanent failure)", type: :request do
  scenario "automatically unsubscribing a user if delivery permanently failed" do
    login_with(%w[internal_app status_updates])

    subscriber_list_id = create_subscriber_list
    subscribe_to_subscriber_list(subscriber_list_id)
    create_content_change
    email_data = expect_an_email_was_sent

    send_status_update(status: "permanent-failure",
                       to: email_data.fetch(:email_address),
                       expected_status: 204)
    clear_any_requests_that_have_been_recorded!

    3.times { create_content_change }
    expect_an_email_was_not_sent
  end
end
