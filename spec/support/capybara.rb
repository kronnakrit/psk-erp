# frozen_string_literal: true

require "capybara/cuprite"

Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(
    app,
    window_size: [1440, 900],
    browser_options: { "no-sandbox": nil },
    headless: true,
    timeout: 15
  )
end

Capybara.configure do |config|
  config.default_driver         = :rack_test
  config.javascript_driver      = :cuprite
  config.default_max_wait_time  = 5
  config.server                 = :puma, { Silent: true }
end

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:each, type: :system, js: true) do
    driven_by :cuprite
  end
end
