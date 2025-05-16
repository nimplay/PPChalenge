require 'swagger_helper'

RSpec.describe 'Api::V1::Authentication', type: :request do
  let(:valid_user) { create(:user, email: 'admin@store.com', password: 'password123', role: 'admin') }

  path '/api/v1/auth' do
    post 'Inicia sesión' do
      tags 'Authentication'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :credentials, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string },
          password: { type: :string }
        },
        required: ['email', 'password']
      }

      response '200', 'Inicio de sesión exitoso' do
        let(:credentials) { { email: valid_user.email, password: 'password123' } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['token']).to be_present
          expect(data['user']['email']).to eq(valid_user.email)
        end
      end

      response '401', 'Credenciales inválidas' do
        let(:credentials) { { email: 'invalid@email.com', password: 'wrongpass' } }
        run_test!
      end
    end
  end

  path '/api/v1/auth/logout' do
    delete 'Cierra sesión' do
      tags 'Authentication'
      security [BearerAuth: []]
      produces 'application/json'

      response '204', 'Sesión cerrada' do
        let(:Authorization) { "Bearer #{valid_user.generate_jwt}" }
        run_test!
      end

      response '401', 'No autorizado' do
        let(:Authorization) { 'Bearer invalid' }
        run_test!
      end
    end
  end
end
