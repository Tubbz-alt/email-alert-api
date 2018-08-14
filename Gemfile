source 'https://rubygems.org'

gem 'pg', '~> 0.21'
gem 'rails', '~> 5.2'

gem 'activerecord-import', '~> 0.25'
gem 'with_advisory_lock', '~> 4.0'

gem 'aws-sdk-s3', '~> 1'
gem 'faraday', '0.12.2'
gem 'foreman', '~> 0.85'
gem 'gds-api-adapters', '~> 52.8'
gem 'gds-sso', '~> 13.6'
gem 'govuk_app_config', '~> 1.8'
# This is pinned < 2 until gds-sso supports JWT > 2
gem 'jwt', '~> 1.5'
gem 'nokogiri', '~> 1.8'
gem 'notifications-ruby-client', '~> 2.7'
gem 'plek', '~> 2.1'
gem 'redcarpet', '~> 3.4'

gem 'govuk_sidekiq', '~> 3.0'
gem 'ratelimit', '~> 1.0'
gem 'sidekiq-scheduler', '~> 3.0'

group :test do
  gem 'climate_control'
  gem 'equivalent-xml'
  gem 'factory_bot_rails'
  gem 'timecop'
  gem 'webmock'
end

group :development, :test do
  gem 'govuk-lint', '~> 3.8'
  gem 'listen', '3.1.5'
  gem 'pry-byebug'
  gem 'rspec-rails', '3.8.0'
  gem 'ruby-prof', '~> 0.17'
end
