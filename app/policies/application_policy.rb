# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    permission?("view_#{resource_name}")
  end

  def show?
    permission?("view_#{resource_name}")
  end

  def create?
    permission?("add_#{resource_name}")
  end

  def new?
    create?
  end

  def update?
    permission?("change_#{resource_name}")
  end

  def edit?
    update?
  end

  def destroy?
    permission?("delete_#{resource_name}")
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      raise NoMethodError, "You must define #resolve in #{self.class}"
    end

    private

    attr_reader :user, :scope
  end

  private

  # Returns the pluralised snake_case resource name used in permission codenames.
  # e.g. ProductPolicy -> "products", OrderPolicy -> "orders"
  def resource_name
    self.class.name.sub("Policy", "").underscore.pluralize
  end

  def permission?(codename)
    return false if user.nil?

    permissions = user.profile&.role&.permissions
    permissions&.include?(codename) || false
  end
end
