module Api
  module V1
    module Auth
      class TokensController < Api::V1::BaseController
        # POST /api/v1/auth/refresh
        # POST /api/v1/auth/verify
        # Both endpoints simply confirm the token is valid (JWT auth happens via before_action).

        def refresh
          render json: {
            user: {
              id: current_user.id,
              email: current_user.email,
              username: current_user.username
            }
          }, status: :ok
        end

        def verify
          render json: {
            valid: true,
            user: {
              id: current_user.id,
              email: current_user.email,
              username: current_user.username
            }
          }, status: :ok
        end
      end
    end
  end
end
