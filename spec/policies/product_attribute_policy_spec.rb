# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProductAttributePolicy, type: :policy do
  subject(:policy) { described_class.new(user, record) }

  let(:record) { ProductAttribute.new }

  context "when user has full product attribute permissions" do
    let(:role) do
      create(:role,
             permissions: %w[view_product_attributes add_product_attributes change_product_attributes
                             delete_product_attributes])
    end
    let(:user) { create(:user).tap { |u| u.profile.update!(role: role) } }

    it { is_expected.to be_index }
    it { is_expected.to be_show }
    it { is_expected.to be_create }
    it { is_expected.to be_update }
    it { is_expected.to be_destroy }
  end

  context "when user has no permissions" do
    let(:user) { create(:user) }

    it { is_expected.not_to be_index }
    it { is_expected.not_to be_create }
    it { is_expected.not_to be_update }
    it { is_expected.not_to be_destroy }
  end

  describe "Scope" do
    let(:role) { create(:role, permissions: %w[view_product_attributes]) }
    let(:user) { create(:user).tap { |u| u.profile.update!(role: role) } }

    it "resolves to all product attributes" do
      expect(described_class::Scope.new(user, ProductAttribute.all).resolve).to eq(ProductAttribute.all)
    end
  end
end
