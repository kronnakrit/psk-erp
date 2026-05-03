# frozen_string_literal: true
# E2E System Spec — TC-01-02: User Management (Admin)
# Based on: testcases/TC-01-authentication.md

require "rails_helper"

RSpec.describe "TC-01-02 — User Management", type: :system do
  let(:admin_role) { create(:role, :admin) }
  let(:admin)      { create(:user).tap { |u| u.profile.update!(role: admin_role) } }

  before { sign_in_as(admin) }

  # TC-01-02-01
  it "TC-01-02-01: admin creates a new user and they appear in the list" do
    visit "/users/new"
    fill_in "ชื่อผู้ใช้", with: "newuser_tc0201"
    fill_in "อีเมล",    with: "newuser_tc0201@example.com"
    fill_in "รหัสผ่าน", with: "Password1!"
    fill_in "ยืนยันรหัสผ่าน", with: "Password1!"
    select admin_role.name, from: "บทบาท"
    click_button "สร้างผู้ใช้"

    expect(page).to have_current_path("/users", ignore_query: true)
    expect(page).to have_text("User created successfully.")
    expect(page).to have_text("newuser_tc0201")
  end

  # TC-01-02-02
  it "TC-01-02-02: duplicate username shows validation error" do
    existing = create(:user, username: "duplicate_user")

    visit "/users/new"
    fill_in "ชื่อผู้ใช้", with: existing.username
    fill_in "อีเมล",    with: "unique_#{SecureRandom.hex(4)}@example.com"
    fill_in "รหัสผ่าน", with: "Password1!"
    fill_in "ยืนยันรหัสผ่าน", with: "Password1!"
    click_button "สร้างผู้ใช้"

    expect(page).to have_text("has already been taken")
  end

  # TC-01-02-03
  it "TC-01-02-03: duplicate email shows validation error" do
    existing = create(:user, email: "dup@example.com")

    visit "/users/new"
    fill_in "ชื่อผู้ใช้", with: "unique_#{SecureRandom.hex(4)}"
    fill_in "อีเมล",    with: existing.email
    fill_in "รหัสผ่าน", with: "Password1!"
    fill_in "ยืนยันรหัสผ่าน", with: "Password1!"
    click_button "สร้างผู้ใช้"

    expect(page).to have_text("has already been taken")
  end

  # TC-01-02-04
  it "TC-01-02-04: admin edits user profile name and sees success flash" do
    target = create(:user)

    visit edit_user_path(target)
    fill_in "ชื่อ",    with: "UpdatedFirst"
    fill_in "นามสกุล", with: "UpdatedLast"
    click_button "อัปเดตผู้ใช้"

    expect(page).to have_text("User updated successfully.")
  end

  # TC-01-02-05
  it "TC-01-02-05: deactivating a user shows deactivation notice" do
    target = create(:user)

    visit users_path
    within("tr", text: target.username) do
      click_button "Deactivate"
    end

    expect(page).to have_text("User deactivated.")
    target.reload
    expect(target.is_active).to be false
  end

  # TC-01-02-06
  it "TC-01-02-06: reactivating an inactive user shows activation notice" do
    target = create(:user, :inactive)

    visit users_path
    within("tr", text: target.username) do
      click_button "Activate"
    end

    expect(page).to have_text("User activated.")
    target.reload
    expect(target.is_active).to be true
  end

  # TC-01-02-07
  it "TC-01-02-07: admin force-resets password via force_password form" do
    target = create(:user)

    visit edit_user_path(target)
    within("form[action*='force_password']") do
      fill_in "New Password",     with: "NewPass1!"
      fill_in "Confirm Password", with: "NewPass1!"
      click_button "Set Password"
    end

    # Can now log in with new password
    click_button "Logout"
    visit "/login"
    fill_in "Username", with: target.username
    fill_in "Password", with: "NewPass1!"
    click_button "Sign in"
    expect(page).to have_current_path("/", ignore_query: true)
  end

  # TC-01-02-08
  it "TC-01-02-08: user without manage_users permission is forbidden from /users" do
    limited = create_limited_user

    # Sign in as limited user (need to sign out first)
    click_button "Logout"
    sign_in_as(limited)

    visit "/users"

    expect(page).to have_text("403").or have_text("forbidden").or have_text("ไม่มีสิทธิ์")
  end
end
