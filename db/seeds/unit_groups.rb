# frozen_string_literal: true

# Seed the system default unit group with canonical definitions.
# Idempotent — safe to run multiple times.

group = UnitGroup.find_or_create_by!(name: "Standard") do |g|
  g.is_default = false # set default after units are created
end

[
  { name: "Pc", ratio: 1  },
  { name: "Dz", ratio: 12 }
].each do |attrs|
  group.unit_definitions.find_or_create_by!(name: attrs[:name]) do |ud|
    ud.ratio = attrs[:ratio]
  end
end

# Now mark as default (validation requires a base unit to already exist)
unless group.is_default?
  group.is_default = true
  group.save!
end

puts "Seeded unit group '#{group.name}' with #{group.unit_definitions.count} definitions."
