require 'rails_helper'

RSpec.configure do |config|
  config.swagger_root = Rails.root.join('swagger').to_s

  config.swagger_docs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'Store API',
        version: 'v1',
        description: 'API con autenticación JWT'
      },
      servers: [
        { url: 'http://{defaultHost}', variables: { defaultHost: { default: 'localhost:3000' } } }
      ],
      components: {
        securitySchemes: {
          BearerAuth: {
            type: :http,
            scheme: :bearer,
            bearerFormat: :JWT
          }
        },
        schemas: {
          Login: {
            type: :object,
            properties: {
              email: { type: :string, example: 'admin@store.com' },
              password: { type: :string, example: 'password123' }
            },
            required: [ 'email', 'password' ]
          },
          Error: {
            type: :object,
            properties: {
              error: { type: :string }
            }
          }
        }
      }
    }
  }
end
