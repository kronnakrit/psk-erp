# frozen_string_literal: true

require "rails_helper"

RSpec.configure do |config|
  config.openapi_root = Rails.root.join("swagger").to_s

  config.openapi_specs = {
    "v1/swagger.yaml" => {
      openapi: "3.0.1",
      info: {
        title: "PSK ERP API V1",
        version: "v1",
        description: "PSK ERP wholesale order management API"
      },
      paths: {},
      components: {
        securitySchemes: {
          bearerAuth: {
            type: :http,
            scheme: :bearer,
            bearerFormat: "JWT"
          }
        },
        schemas: {
          error_response: {
            type: :object,
            properties: {
              error: { type: :string }
            }
          },
          pagination: {
            type: :object,
            properties: {
              current_page: { type: :integer },
              total_pages: { type: :integer },
              total_count: { type: :integer }
            }
          }
        }
      },
      security: [{ bearerAuth: [] }],
      servers: [
        {
          url: "{scheme}://{defaultHost}",
          variables: {
            scheme: { default: "http" },
            defaultHost: { default: "localhost:3000" }
          }
        }
      ]
    }
  }

  config.openapi_format = :yaml
end
