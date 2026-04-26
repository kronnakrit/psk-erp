require "rails_helper"

RSpec.describe "Dashboard UI consistency", type: :request do
  let(:role) do
    create(:role, permissions: %w[view_users view_roles])
  end
  let(:user) { create(:user) }

  before do
    user.profile.update!(role: role)
    sign_in user
    get root_path
  end

  it "returns 200" do
    expect(response).to have_http_status(:ok)
  end

  it "renders btn-secondary on quick links" do
    expect(response.body).to include("btn-secondary")
  end

  it "does not include bg-purple-600" do
    expect(response.body).not_to include("bg-purple-600")
  end

  it "does not include text-purple-700" do
    expect(response.body).not_to include("text-purple-700")
  end

  it "does not include bg-purple-50" do
    expect(response.body).not_to include("bg-purple-50")
  end
end
