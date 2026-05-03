source "https://rubygems.org"

gem "rails", "~> 8.1.3"
gem "dotenv-rails", groups: %i[development test]
gem "propshaft"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "tailwindcss-rails"

# Auth
gem "devise"
gem "devise-jwt"

# Authorization
gem "pundit"

# Rate limiting
gem "rack-attack"

# Pagination
gem "pagy"

# Search
gem "ransack"

# Excel generation & import
gem "caxlsx"
gem "caxlsx_rails"
gem "roo"

# Charts
gem "groupdate"

# API docs
gem "rswag-api"
gem "rswag-ui"

gem "tzinfo-data", platforms: %i[mswin mswin64 mingw x64_mingw jruby]
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"
gem "aws-sdk-s3", require: false
gem "bootsnap", require: false
gem "kamal", require: false
gem "thruster", require: false
gem "image_processing", "~> 1.2"

group :development, :test do
  gem "debug", platforms: %i[mri mswin mswin64 mingw x64_mingw], require: "debug/prelude"
  gem "bundler-audit", require: false
  gem "brakeman", require: false

  # Testing
  gem "rspec-rails"
  gem "capybara"
  gem "cuprite"
  gem "factory_bot_rails"
  gem "shoulda-matchers"
  gem "faker"
  gem "simplecov", require: false

  # Code quality
  gem "rubocop-rails"
  gem "rubocop-rspec"

  # rswag specs
  gem "rswag-specs"
end

group :development do
  gem "web-console"
end
