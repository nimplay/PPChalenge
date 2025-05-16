# spec/requests/api/v1/categories/most_purchased_spec.rb
require 'swagger_helper'

RSpec.describe 'Categories Most Purchased API', type: :request do
  include AuthenticationHelper

  path '/api/v1/categories/most_purchased' do
    get('List most purchased products by category') do
      tags 'Categories'
      produces 'application/json'
      security [BearerAuth: []]

      parameter name: :category_id, in: :query, type: :integer, required: false, description: 'Filter by category ID'
      parameter name: :start_date, in: :query, type: :string, required: false, description: 'Start date (YYYY-MM-DD)'
      parameter name: :end_date, in: :query, type: :string, required: false, description: 'End date (YYYY-MM-DD)'
      parameter name: :limit, in: :query, type: :integer, required: false, description: 'Limit number of results'

      response(200, 'successful') do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { "Bearer #{generate_jwt_for(user)}" }
        let(:category) { create(:category, creator: user) }
        let!(:product) { create(:product, creator: user) }
        let!(:product_category) { create(:product_category, product: product, category: category) }
        let!(:purchases) { create_list(:purchase, 5, product: product, customer: create(:customer)) }

        before do |example|
          submit_request(example.metadata)
        end

        run_test! do |response|
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['data']).to be_an(Array)
          expect(json['data'].first['category_id']).to eq(category.id)
          expect(json['data'].first['purchase_count']).to eq(5)
        end
      end

      response(200, 'with category filter') do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { "Bearer #{generate_jwt_for(user)}" }
        let(:category1) { create(:category, creator: user) }
        let(:category2) { create(:category, creator: user) }
        let!(:product1) { create(:product, creator: user) }
        let!(:product2) { create(:product, creator: user) }
        let!(:pc1) { create(:product_category, product: product1, category: category1) }
        let!(:pc2) { create(:product_category, product: product2, category: category2) }
        let!(:purchases1) { create_list(:purchase, 3, product: product1, customer: create(:customer)) }
        let!(:purchases2) { create_list(:purchase, 5, product: product2, customer: create(:customer)) }
        let(:category_id) { category2.id }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['data'].size).to eq(1)
          expect(json['data'].first['category_id']).to eq(category2.id)
        end
      end

      response(200, 'with date range filter') do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { "Bearer #{generate_jwt_for(user)}" }
        let(:category) { create(:category, creator: user) }
        let!(:product) { create(:product, creator: user) }
        let!(:product_category) { create(:product_category, product: product, category: category) }
        let!(:old_purchases) do
          create_list(:purchase, 2, product: product, customer: create(:customer), created_at: 2.weeks.ago)
        end
        let!(:recent_purchases) do
          create_list(:purchase, 3, product: product, customer: create(:customer), created_at: 1.day.ago)
        end
        let(:start_date) { 1.week.ago.to_date.to_s }
        let(:end_date) { Date.today.to_s }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['data'].first['purchase_count']).to eq(3)
        end
      end

      response(401, 'unauthorized') do
        let(:Authorization) { nil }
        run_test!
      end
    end
  end
end
