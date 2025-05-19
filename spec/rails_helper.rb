require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'

require File.expand_path('../config/environment', __dir__)
abort('The Rails environment is running in production mode!') if Rails.env.production?

require 'rspec/rails'
require 'rswag/specs'
require 'factory_bot_rails'

# Cargar archivos de soporte
Dir[Rails.root.join('spec', 'support', '**', '*.rb')].sort.each { |f| require f }

RSpec.configure do |config|
  # Configuraciones básicas
  config.fixture_paths = [ "#{Rails.root}/spec/fixtures" ]
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  # Includes
  config.include FactoryBot::Syntax::Methods
  config.include AuthenticationHelper, type: :request

  if defined?(Devise)
    config.include Devise::Test::IntegrationHelpers, type: :request
    config.include Devise::Test::ControllerHelpers, type: :view
    config.include Devise::Test::ControllerHelpers, type: :controller
  end

  # Configuración de DatabaseCleaner
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
    DatabaseCleaner.strategy = :transaction
  end

  config.before do
    DatabaseCleaner.start
  end

  config.after do
    DatabaseCleaner.clean
  end

  # Configuración de RSwag (actualizada para evitar warnings)
  config.rswag_dry_run = false
  config.openapi_root = Rails.root.join('swagger').to_s
end

# Configuración OpenAPI/Swagger
RSpec.configure do |config|
  config.before do |example|
    if example.metadata[:openapi_spec]
      config.swagger_docs = {
        'v1/swagger.json' => {
          openapi: '3.0.1',
          info: {
            title: 'API V1',
            version: 'v1'
          },
          paths: {},
          servers: [
            {
              url: 'http://{defaultHost}',
              variables: {
                defaultHost: {
                  default: 'localhost:3000'
                }
              }
            }
          ]
        }
      }
    end
  end
end
