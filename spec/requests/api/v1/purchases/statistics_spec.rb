# spec/requests/api/v1/purchases/statistics_spec.rb
require 'swagger_helper'

RSpec.describe 'Purchases Statistics API', type: :request do
  include AuthenticationHelper

  path '/api/v1/purchases/statistics' do
    get('purchase statistics') do
      tags 'Purchases'
      produces 'application/json'
      security [ BearerAuth: [] ]
      parameter name: :start_date, in: :query, type: :string, required: false, description: 'Start date (YYYY-MM-DD)'
      parameter name: :end_date, in: :query, type: :string, required: false, description: 'End date (YYYY-MM-DD)'
      parameter name: :category_id, in: :query, type: :integer, required: false, description: 'Filter by category ID'

      response(200, 'successful') do
        let(:user) { create(:user, :admin) }
        let(:authorization) { "Bearer #{generate_jwt_for(user)}" }
        let(:category) { create(:category, creator: user) }
        let(:customer) { create(:customer) }

        before do |example|
          product = create(:product, price: 100.0, creator: user)
          create(:product_category, product: product, category: category)
          create_list(:purchase, 3, product: product, quantity: 1, customer: customer, created_at: '2023-06-15')

          submit_request(example.metadata)
product = create(:product, price: 100.0, creator: user)
          create(:product_category, product: product, category: category)

          # Purchases within date range
          create_list(:purchase, 2, product: product, quantity: 1, customer: customer, created_at: '2023-06-15')

          # Purchases outside date range
          create_list(:purchase, 5, product: product, quantity: 1, customer: customer, created_at: '2023-07-15')

          submit_request(example.metadata)
        end

        run_test! do |response|
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)

          expect(json['data']).to be_a(Hash)
          expect(json['data']).to include(
            'purchase_count' => be_a(Integer),
            'total_revenue' => be_a(String),
            'average_order_value' => be_a(String),
            'revenue_by_category' => be_an(Array),
            'top_products' => be_an(Array),
            'timeline_data' => be_a(Hash)
          )

          expect(json['data']['revenue_by_category'].first).to include(
            'id' => be_a(Integer),
            'name' => be_a(String),
            'revenue' => be_a(Float)
          )
        end
      end

      response(200, 'with date filter') do
        let(:user) { create(:user, :admin) }
        let(:authorization) { "Bearer #{generate_jwt_for(user)}" }
        let(:category) { create(:category, creator: user) }
        let(:customer) { create(:customer) }
        let(:start_date) { '2023-06-01' }
        let(:end_date) { '2023-06-30' }


        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['data']['purchase_count']).to eq(2)
          expect(json['data']['total_revenue'].to_f).to eq(200.0) # 2 purchases * 100 price
        end
      end

      response(401, 'unauthorized') do
        let(:authorization) { nil }
        run_test!
      end
    end
  end
end
