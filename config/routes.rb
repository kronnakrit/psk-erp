Rails.application.routes.draw do
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Sidekiq Web UI — protected by admin authentication
  require "sidekiq/web"
  authenticate :user, ->(u) { u.respond_to?(:admin?) && u.admin? } do
    mount Sidekiq::Web => "/sidekiq"
  end

  # Defines the root path route ("/")
  root to: "dashboard#index"
end
