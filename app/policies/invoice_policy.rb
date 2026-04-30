# frozen_string_literal: true

class InvoicePolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      permission?("view_invoices") ? scope.all : scope.none
    end
  end

  def index?   = permission?("view_invoices")
  def show?    = permission?("view_invoices")
  def new?     = permission?("add_invoices")
  def create?  = permission?("add_invoices")
  def edit?    = permission?("change_invoices")
  def update?  = permission?("change_invoices")
  def destroy? = permission?("delete_invoices")

  def cancel?
    permission?("change_invoices") && record.status == "Dr"
  end

  def mark_paid?
    permission?("change_invoices") && record.status == "Dr"
  end

  def reopen?
    permission?("change_invoices") && record.status == "Pd"
  end

  def print?
    permission?("view_invoices")
  end

  def audit?
    permission?("view_invoice_audit")
  end

  def bulk_update_status?
    permission?("change_invoices")
  end
end
