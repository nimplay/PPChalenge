# spec/requests/api/v1/purchases/search_spec.rb
require 'swagger_helper'

RSpec.describe 'Purchases API', type: :request do
  include AuthenticationHelper

  path '/api/v1/purchases/search' do
    get('search purchases') do
      tags 'Purchases'
      produces 'application/json'
      security [BearerAuth: []]

      parameter name: :start_date, in: :query, type: :string, required: false
      parameter name: :end_date, in: :query, type: :string, required: false
      parameter name: :category_id, in: :query, type: :integer, required: false
      parameter name: :customer_id, in: :query, type: :integer, required: false
      parameter name: :admin_id, in: :query, type: :integer, required: false
      parameter name: :page, in: :query, type: :integer, required: false
      parameter name: :per_page, in: :query, type: :integer, required: false

      response(200, 'successful') do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { "Bearer #{generate_jwt_for(user)}" } # RSwag espera este nombre exacto
        let(:category) { create(:category) }
        let(:customer) { create(:customer) }
        let(:start_date) { '2023-01-01' }
        let(:end_date) { '2023-12-31' }
        let(:category_id) { category.id }
        let(:customer_id) { customer.id }
        let(:admin_id) { user.id }
        let(:page) { 1 }
        let(:per_page) { 10 }

        before do |example|
          # Crear datos de prueba
          product = create(:product, creator: user)
          create(:product_category, product: product, category: category)
          create_list(:purchase, 3, product: product, customer: customer, created_at: '2023-06-15')

          # RSwag manejará la petición con los parámetros y headers definidos
          submit_request(example.metadata)
        end

        run_test! do |response|
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['data']).to be_an(Array)
          expect(json['meta']).to include(
            'total_count' => 3,
            'total_pages' => 1,
            'current_page' => 1
          )
        end
      end

      response(401, 'unauthorized') do
        let(:Authorization) { nil }
        run_test!
      end
    end
  end
end
