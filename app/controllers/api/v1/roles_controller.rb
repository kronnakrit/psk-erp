module Api
  module V1
    class RolesController < Api::V1::BaseController
      before_action :set_role, only: %i[show update destroy]

      def index
        @ransack = policy_scope(Role).ransack(params[:q])
        @pagy, @roles = pagy(@ransack.result(distinct: true), limit: params.fetch(:per_page, 25).to_i)
        authorize Role
        render json: {
          roles: @roles.map { |r| role_json(r) },
          pagination: { page: @pagy.page, pages: @pagy.pages, total: @pagy.count }
        }
      end

      def show
        authorize @role
        render json: role_json(@role)
      end

      def create
        @role = Role.new(role_params)
        authorize @role
        if @role.save
          render json: role_json(@role), status: :created
        else
          render json: { errors: @role.errors }, status: :unprocessable_content
        end
      end

      def update
        authorize @role
        if @role.update(role_params)
          render json: role_json(@role)
        else
          render json: { errors: @role.errors }, status: :unprocessable_content
        end
      end

      def destroy
        authorize @role
        @role.destroy!
        head :no_content
      end

      private

      def set_role
        @role = Role.find(params[:id])
      end

      def role_params
        params.expect(role: [:name, :group_id, { permissions: [] }])
      end

      def role_json(role)
        {
          id: role.id,
          name: role.name,
          permissions: role.permissions
        }
      end
    end
  end
end
