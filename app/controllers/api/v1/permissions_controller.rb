module Api
  module V1
    class PermissionsController < Api::V1::BaseController
      def index
        authorize :permission, :index?
        render json: { permissions: Permissions::ALL }
      end
    end
  end
end
