class SeedDefaultUnitGroupAndMigrateOrderLines < ActiveRecord::Migration[8.1]
  # Maps legacy enum code → { name, ratio, is_migration_placeholder }
  UNIT_MAP = {
    "Dz" => { name: "dozen", ratio: 12,  placeholder: false },
    "Pc" => { name: "pcs",   ratio: 1,   placeholder: false },
    "Pa" => { name: "pack",  ratio: 1,   placeholder: true  },
    "Se" => { name: "set",   ratio: 1,   placeholder: true  },
    "Ct" => { name: "carton", ratio: 1,  placeholder: true  }
  }.freeze

  def up
    ActiveRecord::Base.transaction do
      # 1. Ensure a UnitGroup named "Standard" exists (not yet default — units come first)
      default_group = UnitGroup.find_by(is_default: true)

      unless default_group
        default_group = UnitGroup.find_or_initialize_by(name: "Standard")
        default_group.is_default = false
        default_group.save!(validate: false)
      end

      # 2. Seed canonical definitions (pcs + dozen) — idempotent
      %w[pcs dozen].each do |unit_name|
        attrs = UNIT_MAP.values.find { |v| v[:name] == unit_name }
        # Skip if already exists by name OR by ratio (for ratio=1, only one non-placeholder allowed)
        next if UnitDefinition.exists?(unit_group: default_group, name: unit_name)
        next if attrs[:ratio] == 1 && UnitDefinition.where(unit_group: default_group, ratio: 1).where(is_migration_placeholder: false).exists?

        UnitDefinition.create!(
          unit_group: default_group,
          name:       unit_name,
          ratio:      attrs[:ratio],
          is_migration_placeholder: false
        )
      end

      # Ensure the group is marked as default now that it has a base unit
      unless default_group.is_default?
        UnitGroup.where.not(id: default_group.id).update_all(is_default: false) # rubocop:disable Rails/SkipsModelValidations
        default_group.update_column(:is_default, true) # rubocop:disable Rails/SkipsModelValidations
      end

      # 3. Build a lookup of legacy code → unit_definition_id
      code_to_id = {}
      UNIT_MAP.each do |code, attrs|
        # Try to find by name first, then by ratio for canonical units
        ud = UnitDefinition.find_by(unit_group: default_group, name: attrs[:name])
        ud ||= UnitDefinition.find_by(unit_group: default_group, ratio: attrs[:ratio]) if !attrs[:placeholder]

        unless ud
          # Create migration placeholder for Pa/Se/Ct
          ud = UnitDefinition.create!(
            unit_group:               default_group,
            name:                     attrs[:name],
            ratio:                    attrs[:ratio],
            is_migration_placeholder: attrs[:placeholder]
          )
        end
        code_to_id[code] = ud.id
      end

      # 4. Migrate each order_line.unit → order_lines.unit_definition_id
      unresolved = execute(
        "SELECT DISTINCT unit FROM order_lines WHERE unit IS NOT NULL AND unit_definition_id IS NULL"
      ).map { |row| row["unit"] }

      unresolved.each do |code|
        raise "Unknown unit code '#{code}' — cannot migrate order_lines." unless code_to_id.key?(code)
      end

      code_to_id.each do |code, ud_id|
        execute(
          "UPDATE order_lines SET unit_definition_id = #{ud_id} " \
          "WHERE unit = '#{code}' AND unit_definition_id IS NULL"
        )
      end
    end
  end

  def down
    execute("UPDATE order_lines SET unit_definition_id = NULL")
    # Remove placeholder definitions; canonical ones stay
    UnitDefinition.where(is_migration_placeholder: true).destroy_all
  end
end

