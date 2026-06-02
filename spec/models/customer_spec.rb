require "rails_helper"

RSpec.describe Customer, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:first_name) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:country).optional }
    it { is_expected.to belong_to(:logistic_company).optional }
  end

  describe "#get_fullname" do
    it "returns first_name only when last_name is blank" do
      customer = build(:customer, first_name: "Alice", last_name: "")
      expect(customer.get_fullname).to eq("Alice")
    end

    it "returns full name when last_name is present" do
      customer = build(:customer, first_name: "Alice", last_name: "Smith")
      expect(customer.get_fullname).to eq("Alice Smith")
    end
  end

  describe "telephones" do
    it "strips blank entries on save" do
      customer = create(:customer, telephones: ["0811111111", "", "  ", "0822222222"])
      expect(customer.telephones_list).to eq(%w[0811111111 0822222222])
    end

    it "coerces hash-shaped telephones from params" do
      customer = build(:customer)
      customer.assign_attributes(telephones: { "0" => "0811111111", "1" => "0822222222" })
      customer.valid?
      expect(customer.telephones_list).to eq(%w[0811111111 0822222222])
    end

    it "#telephone returns the first number" do
      customer = build(:customer, telephones: %w[0811111111 0822222222])
      expect(customer.telephone).to eq("0811111111")
    end

    it "#telephones_display joins numbers for display" do
      customer = build(:customer, telephones: %w[0811111111 0822222222])
      expect(customer.telephones_display).to eq("0811111111, 0822222222")
    end
  end

  describe "soft delete" do
    let!(:customer) { create(:customer) }

    it "soft_delete! sets deleted_at" do
      expect { customer.soft_delete! }.to change { customer.reload.deleted_at }.from(nil)
    end

    it "is excluded from default scope after soft delete" do
      customer.soft_delete!
      expect(described_class.all).not_to include(customer)
    end

    it "restore! clears deleted_at" do
      customer.soft_delete!
      expect { customer.restore! }.to change { customer.reload.deleted_at }.to(nil)
    end
  end

  describe "scopes" do
    let!(:active_customer)  { create(:customer) }
    let!(:deleted_customer) { create(:customer).tap(&:soft_delete!) }

    it ".active returns only non-deleted records" do
      expect(described_class.active).to include(active_customer)
      expect(described_class.active).not_to include(deleted_customer)
    end

    it ".deleted returns only soft-deleted records" do
      expect(described_class.deleted).to include(deleted_customer)
      expect(described_class.deleted).not_to include(active_customer)
    end

    it ".with_deleted returns all records" do
      expect(described_class.with_deleted).to include(active_customer, deleted_customer)
    end
  end
end
