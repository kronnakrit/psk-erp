# frozen_string_literal: true
# E2E System Spec — TC-01-01: Username/Password Login
# Based on: testcases/TC-01-authentication.md

require "rails_helper"

RSpec.describe "TC-01-01 — Username/Password Login", type: :system do
  let(:admin_role) { create(:role, :admin) }
  let(:admin)      { create(:user).tap { |u| u.profile.update!(role: admin_role) } }

  # TC-01-01-01
  it "TC-01-01-01: redirects to dashboard on valid credentials" do
    visit "/login"
    fill_in "Username", with: admin.username
    fill_in "Password", with: "Password1!"
    click_button "Sign in"

    expect(page).to have_current_path("/", ignore_query: true)
  end

  # TC-01-01-02
  it "TC-01-01-02: shows error on wrong password" do
    visit "/login"
    fill_in "Username", with: admin.username
    fill_in "Password", with: "wrongpassword"
    click_button "Sign in"

    expect(page).to have_current_path("/login", ignore_query: true)
    expect(page).to have_text("หรือรหัสผ่านไม่ถูกต้อง")
  end

  # TC-01-01-03
  it "TC-01-01-03: shows error for non-existent username" do
    visit "/login"
    fill_in "Username", with: "nobody_#{SecureRandom.hex(4)}"
    fill_in "Password", with: "Password1!"
    click_button "Sign in"

    expect(page).to have_current_path("/login", ignore_query: true)
    expect(page).to have_text("หรือรหัสผ่านไม่ถูกต้อง")
  end

  # TC-01-01-04
  it "TC-01-01-04: rejects login for inactive user" do
    inactive = create(:user, :inactive)

    visit "/login"
    fill_in "Username", with: inactive.username
    fill_in "Password", with: "Password1!"
    click_button "Sign in"

    expect(page).to have_current_path("/login", ignore_query: true)
    expect(page).to have_text("บัญชีของคุณยังไม่ได้รับการเปิดใช้งาน")
  end

  # TC-01-01-05
  it "TC-01-01-05: redirects unauthenticated access to login with flash" do
    visit "/orders"

    expect(page).to have_current_path("/login", ignore_query: true)
    expect(page).to have_text("คุณต้องเข้าสู่ระบบ")
  end

  # TC-01-01-06
  it "TC-01-01-06: remember me checkbox sets persistent cookie", js: true do
    visit "/login"
    fill_in "Username", with: admin.username
    fill_in "Password", with: "Password1!"
    check "Remember me"
    click_button "Sign in"

    expect(page).to have_current_path("/", ignore_query: true)
    cookie = page.driver.browser.cookies.all.values.find { |c| c.name == "remember_user_token" }
    expect(cookie).to be_present
  end

  # TC-01-01-07
  # After logout, Devise redirects to root which requires auth → redirect to /login
  # The unauthenticated flash overwrites the signed_out flash in this app configuration.
  it "TC-01-01-07: logout destroys session and redirects to login" do
    sign_in_as(admin)

    click_button "Logout"

    expect(page).to have_current_path("/login", ignore_query: true)
    # Session is destroyed; attempting to visit protected page redirects back to login
    visit "/orders"
    expect(page).to have_current_path("/login", ignore_query: true)
  end
end
