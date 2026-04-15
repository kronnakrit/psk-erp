# frozen_string_literal: true

class OrderPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end

  def report?
    permission?("see_sale_graph")
  end

  def export?
    permission?("view_orders")
  end

  def export_token?
    permission?("view_orders")
  end

  def download?
    permission?("view_orders")
  end

  def combine_bills?
    permission?("view_orders")
  end

  def bulk_update_status?
    permission?("change_orders")
  end

  def dashboard?
    permission?("view_orders")
  end

  def delivery_order?
    permission?("view_orders")
  end

  def duplicate?
    permission?("add_orders")
  end

  def price_monitor?
    permission?("see_price_monitor")
  end

  def audit?
    permission?("view_order_audit")
  end
end
