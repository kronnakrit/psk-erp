require "rails_helper"

RSpec.describe "Typography token CSS classes", type: :request do
  let(:css_content) do
    built_css = Rails.root.join("app/assets/builds/tailwind.css")
    built_css.exist? ? built_css.read : ""
  end

  it "compiled CSS includes .page-heading" do
    expect(css_content).to include(".page-heading")
  end

  it "compiled CSS includes .section-heading" do
    expect(css_content).to include(".section-heading")
  end

  it "compiled CSS includes .back-link" do
    expect(css_content).to include(".back-link")
  end
end
