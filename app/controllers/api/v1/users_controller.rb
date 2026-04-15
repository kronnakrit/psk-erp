module Api
  module V1
    class UsersController < Api::V1::BaseController
      before_action :set_user, only: %i[update destroy activate deactivate]

      def index
        @ransack = policy_scope(User).includes(:profile).ransack(params[:q])
        @ransack.sorts = "created_at desc" if @ransack.sorts.empty?
        @pagy, @users = pagy(@ransack.result, limit: params.fetch(:per_page, 25).to_i)
        authorize User
        render json: {
          users: @users.map { |u| user_json(u) },
          pagination: pagy_metadata(@pagy)
        }
      end

      def create
        @user = User.new(user_params)
        authorize @user
        if @user.save
          render json: { user: user_json(@user) }, status: :created
        else
          render json: { errors: @user.errors }, status: :unprocessable_content
        end
      end

      def update
        authorize @user
        if @user.update(user_params)
          render json: { user: user_json(@user) }
        else
          render json: { errors: @user.errors }, status: :unprocessable_content
        end
      end

      def destroy
        authorize @user
        @user.destroy!
        head :no_content
      end

      def activate
        authorize @user, :update?
        @user.update!(is_active: true)
        render json: { user: user_json(@user) }
      end

      def deactivate
        authorize @user, :update?
        @user.update!(is_active: false)
        render json: { user: user_json(@user) }
      end

      private

      def set_user
        @user = User.find(params[:id])
      end

      def user_params
        params.expect(
          user: [:email, :username, :password, :password_confirmation, :is_active,
                 { profile_attributes: %i[id first_name last_name address remark telephone role_id] }]
        )
      end

      def user_json(user)
        {
          id: user.id,
          email: user.email,
          username: user.username,
          is_active: user.is_active,
          full_name: user.profile&.full_name,
          role: user.profile&.role&.name
        }
      end

      def pagy_metadata(pagy)
        {
          page: pagy.page,
          per_page: pagy.limit,
          total: pagy.count,
          pages: pagy.pages
        }
      end
    end
  end
end
