admin_role = Role.find_or_create_by!(name: "Admin") do |role|
  role.permissions = Permissions::ALL
end

# Ensure existing admin role always has all permissions
admin_role.update!(permissions: Permissions::ALL) unless admin_role.permissions.sort == Permissions::ALL.sort

admin_user = User.find_or_initialize_by(email: "admin@psk.com")
admin_user.assign_attributes(
  username:  "admin",
  is_active: true,
  password:  if Rails.env.production?
               ENV.fetch("ADMIN_DEFAULT_PASSWORD") # raises KeyError if unset in production
             else
               ENV.fetch("ADMIN_DEFAULT_PASSWORD", "Dev@seed0!")
             end
)
admin_user.save!

admin_user.profile ||= admin_user.build_profile
admin_user.profile.update!(role: admin_role)

puts "Seeded admin user: #{admin_user.email}"
