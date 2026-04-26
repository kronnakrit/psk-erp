require "rails_helper"

RSpec.describe "Button token CSS classes", type: :request do
  let(:css_content) do
    built_css = Rails.root.join("app/assets/builds/tailwind.css")
    built_css.exist? ? built_css.read : ""
  end

  it "compiled CSS includes .btn-primary" do
    expect(css_content).to include(".btn-primary")
  end

  it "compiled CSS includes .btn-secondary" do
    expect(css_content).to include(".btn-secondary")
  end

  it "compiled CSS includes .btn-danger" do
    expect(css_content).to include(".btn-danger")
  end

  it "compiled CSS includes .btn-outline" do
    expect(css_content).to include(".btn-outline")
  end

  it "compiled CSS includes .btn-sm-primary" do
    expect(css_content).to include(".btn-sm-primary")
  end

  it "compiled CSS includes .btn-sm-secondary" do
    expect(css_content).to include(".btn-sm-secondary")
  end
end
