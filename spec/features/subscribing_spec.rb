RSpec.describe "Subscribing to a subscriber_list", type: :request do
  scenario "subscribing to a subscriber_list" do
    login_with_internal_app

    subscriber_list_id = create_and_joined_facet_subscriber_list

    subscribe_to_subscriber_list(subscriber_list_id, expected_status: 201)
    subscribe_to_subscriber_list(subscriber_list_id, expected_status: 200)
    subscribe_to_subscriber_list("missing",          expected_status: 404)
  end
end
