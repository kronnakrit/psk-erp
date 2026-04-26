require "rails_helper"

RSpec.describe "Row action token CSS classes", type: :request do
  let(:css_content) do
    built_css = Rails.root.join("app/assets/builds/tailwind.css")
    built_css.exist? ? built_css.read : ""
  end

  it "compiled CSS includes .row-action-primary" do
    expect(css_content).to include(".row-action-primary")
  end

  it "compiled CSS includes .row-action-muted" do
    expect(css_content).to include(".row-action-muted")
  end

  it "compiled CSS includes .row-action-danger" do
    expect(css_content).to include(".row-action-danger")
  end
end
