require_relative "boot"

require "active_model/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "gds_api/content_store"
require "notifications/client"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module EmailAlertApi
  class Application < Rails::Application
    config.time_zone = "London"
    config.api_only = true
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.eager_load_paths << Rails.root.join("lib")

    config.action_dispatch.rescue_responses["ActiveModel::ValidationError"] = :unprocessable_entity

    config.notify_template_id = ENV["GOVUK_NOTIFY_TEMPLATE_ID"]
  end
end
