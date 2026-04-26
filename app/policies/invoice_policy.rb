# frozen_string_literal: true

class InvoicePolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end

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
