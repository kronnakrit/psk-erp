require "rails_helper"

RSpec.describe "CSS rebuild output contains design tokens", type: :request do
  let(:css_content) do
    built_css = Rails.root.join("app/assets/builds/tailwind.css")
    built_css.exist? ? built_css.read : ""
  end

  it "compiled CSS includes btn-primary after rebuild" do
    expect(css_content).to include(".btn-primary")
  end

  it "compiled CSS includes btn-secondary after rebuild" do
    expect(css_content).to include(".btn-secondary")
  end

  it "compiled CSS includes btn-danger after rebuild" do
    expect(css_content).to include(".btn-danger")
  end
end
