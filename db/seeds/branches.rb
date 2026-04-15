# frozen_string_literal: true

Branch.find_or_create_by!(name: "Main Branch")
puts "  Branch: Main Branch seeded"
