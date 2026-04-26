# frozen_string_literal: true

class AddUniquenameIndexToLogisticCompanies < ActiveRecord::Migration[8.0]
  def up
    # Resolve any existing duplicate names before adding the unique index
    execute <<~SQL
      WITH ranked AS (
        SELECT id,
               name,
               ROW_NUMBER() OVER (PARTITION BY lower(name) ORDER BY id) AS rn
        FROM logistic_companies
      )
      UPDATE logistic_companies lc
      SET name = lc.name || ' (' || (ranked.rn)::text || ')'
      FROM ranked
      WHERE ranked.id = lc.id
        AND ranked.rn > 1
    SQL

    add_index :logistic_companies, "lower(name)",
              unique: true,
              name: "index_logistic_companies_on_lower_name"
  end

  def down
    remove_index :logistic_companies, name: "index_logistic_companies_on_lower_name"
  end
end
