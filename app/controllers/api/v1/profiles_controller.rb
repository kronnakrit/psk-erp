module Api
  module V1
    class ProfilesController < Api::V1::BaseController
      def show
        @profile = current_user.profile
        authorize @profile
        render json: profile_json(@profile)
      end

      def update
        @profile = current_user.profile
        authorize @profile
        if @profile.update(profile_params)
          render json: profile_json(@profile)
        else
          render json: { errors: @profile.errors }, status: :unprocessable_content
        end
      end

      private

      def profile_params
        params.expect(profile: %i[first_name last_name address remark telephone])
      end

      def profile_json(profile)
        {
          id: profile.id,
          first_name: profile.first_name,
          last_name: profile.last_name,
          full_name: profile.full_name,
          telephone: profile.telephone,
          address: profile.address,
          remark: profile.remark,
          role: profile.role&.name
        }
      end
    end
  end
end
