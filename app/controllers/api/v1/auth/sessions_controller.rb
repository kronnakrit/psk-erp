module Api
  module V1
    module Auth
      class SessionsController < Devise::SessionsController
        respond_to :json

        private

        def respond_with(resource, _opts = {})
          if resource.persisted?
            render json: {
              user: {
                id: resource.id,
                email: resource.email,
                username: resource.username
              }
            }, status: :ok
          else
            render json: { error: "Invalid credentials" }, status: :unauthorized
          end
        end

        def respond_to_on_destroy
          if request.headers["Authorization"].present?
            render json: { message: "Logged out successfully" }, status: :ok
          else
            render json: { error: "No active session" }, status: :unauthorized
          end
        end
      end
    end
  end
end
