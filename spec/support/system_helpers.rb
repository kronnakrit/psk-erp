# frozen_string_literal: true

module SystemHelpers
  DEFAULT_PASSWORD = "Password1!"

  def sign_in_as(user, password: DEFAULT_PASSWORD)
    visit "/login"
    fill_in "Username", with: user.username
    fill_in "Password", with: password
    click_button "Sign in"
    expect(page).to have_current_path("/", ignore_query: true)
  end

  # Build an admin user: role with Permissions::ALL, profile attached
  def create_admin_user
    role = create(:role, :admin)
    create(:user).tap { |u| u.profile.update!(role: role) }
  end

  # Build a user whose role has only the given permissions
  def create_user_with_permissions(*permissions)
    role = create(:role, permissions: permissions)
    create(:user).tap { |u| u.profile.update!(role: role) }
  end

  # Build a user with NO permissions
  def create_limited_user
    create_user_with_permissions
  end
end

RSpec.configure do |config|
  config.include SystemHelpers, type: :system
end
