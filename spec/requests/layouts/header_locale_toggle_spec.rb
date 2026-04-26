require "rails_helper"

RSpec.describe "Header locale toggle", type: :request do
  let(:user) { create(:user) }

  before do
    sign_in user
    get root_path
  end

  it "returns 200" do
    expect(response).to have_http_status(:ok)
  end

  it "includes TH toggle button" do
    expect(response.body).to include("TH")
  end

  it "includes EN toggle button" do
    expect(response.body).to include("EN")
  end

  it "includes locale-toggle data-testid" do
    expect(response.body).to include("locale-toggle")
  end
end
