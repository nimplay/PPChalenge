# spec/requests/api/v1/categories/top_revenue_spec.rb
require 'swagger_helper'

RSpec.describe 'Categories API', type: :request do
  include AuthenticationHelper

  path '/api/v1/categories/top_revenue' do
    get('top revenue categories') do
      tags 'Categories'
      produces 'application/json'
      security [BearerAuth: []]

      parameter name: :start_date, in: :query, type: :string, required: false, description: 'Start date filter (YYYY-MM-DD)'
      parameter name: :end_date, in: :query, type: :string, required: false, description: 'End date filter (YYYY-MM-DD)'

      response(200, 'successful') do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { "Bearer #{generate_jwt_for(user)}" }
        let(:category) { create(:category, creator: user) }
        let(:product1) { create(:product, price: 100.0, creator: user) }
        let(:product2) { create(:product, price: 200.0, creator: user) }
        let(:customer) { create(:customer) }

        before do |example|
          create(:product_category, product: product1, category: category)
          create(:product_category, product: product2, category: category)

          create_list(:purchase, 3, product: product1, quantity: 2, customer: customer)
          create_list(:purchase, 2, product: product2, quantity: 3, customer: customer)

          submit_request(example.metadata)
        end

        run_test! do
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)

          expect(json['data']).to be_an(Array)
          expect(json['data'].first).to include(
            'category_id' => category.id,
            'category_name' => category.name,
            'products' => be_an(Array)
          )

          products = json['data'].first['products']
          expect(products.map { |p| p['revenue'].to_f }).to match_array([600.0, 1200.0])
        end
      end

      response(200, 'with date filter') do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { "Bearer #{generate_jwt_for(user)}" }
        let(:category) { create(:category, creator: user) }
        let(:product) { create(:product, price: 100.0, creator: user) }
        let(:customer) { create(:customer) }
        let(:start_date) { 1.week.ago.to_date.to_s }
        let(:end_date) { Date.today.to_s }

        before do
          create(:product_category, product: product, category: category)

          create_list(:purchase, 2,
                     product: product,
                     quantity: 1,
                     customer: customer,
                     created_at: 3.days.ago)

          create_list(:purchase, 5,
                     product: product,
                     quantity: 1,
                     customer: customer,
                     created_at: 2.weeks.ago)
        end

        run_test! do
          json = JSON.parse(response.body)
          products = json['data'].first['products']
          total = products.sum { |p| p['revenue'].to_f }
          expect(total).to eq(200.0)
        end
      end

      response(401, 'unauthorized') do
        let(:Authorization) { nil }
        run_test!
      end
    end
  end
end
