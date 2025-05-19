module Api
  module V1
    module Categories
      class MostPurchasedController < ApplicationController
        include Authenticable
        before_action :set_cache_key, only: [ :index ]

        # GET /api/v1/categories/most_purchased
        def index
          @result = cached_categories_with_most_purchased
          render json: { data: @result }
        end

        private

        def set_cache_key
          permitted_params = params.permit(
            :limit, :force_refresh, :start_date, :end_date, :category_id,
            most_purchased: [ :limit, :force_refresh, :start_date, :end_date, :category_id ]
          )

          cache_params = permitted_params.to_h.deep_symbolize_keys
          @cache_key = "most_purchased_#{cache_params.to_query}"
        end

        def cached_categories_with_most_purchased
          Rails.cache.fetch(@cache_key, expires_in: 1.hour) do
            categories_with_most_purchased
          end
        end

        def categories_with_most_purchased
          query = base_query
          apply_filters(query)
          process_query_results(query)
        end

        def base_query
          Category.joins(products: :purchases)
                  .joins("LEFT JOIN users ON products.user_id = users.id")
                  .select(
                    "categories.id as category_id",
                    "categories.name as category_name",
                    "products.id as product_id",
                    "products.name as product_name",
                    "products.price as product_price",
                    "COUNT(purchases.id) as purchase_count",
                    "users.email as creator_email"
                  )
        end

        def apply_filters(query)
          query.where!(category_filter) if category_filter
          query.where!(date_range_filter) if date_range_filter
        end

        def category_filter
          return unless params.dig(:most_purchased, :category_id) || params[:category_id]
          { "categories.id" => params.dig(:most_purchased, :category_id) || params[:category_id] }
        end

        def date_range_filter
          return unless valid_date_range?

          start_date = parse_date(params.dig(:most_purchased, :start_date) || params[:start_date])
          end_date = parse_date(params.dig(:most_purchased, :end_date) || params[:end_date])

          { purchases: { created_at: start_date.beginning_of_day..end_date.end_of_day } }
        end

        def valid_date_range?
          (params.dig(:most_purchased, :start_date) && params.dig(:most_purchased, :end_date)) ||
          (params[:start_date] && params[:end_date])
        end

        def process_query_results(query)
          results = query.group("categories.id, products.id, users.email")
                        .order("categories.id, purchase_count DESC")

          build_response_hash(results)
        end

        def build_response_hash(results)
          results.each_with_object({}) do |record, hash|
            category = hash[record.category_id] ||= initialize_category(record)

            if category[:purchase_count] < record.purchase_count.to_i
              update_category_with_product(category, record)
            end
          end.values
        end

        def initialize_category(record)
          {
            category_id: record.category_id,
            category_name: record.category_name,
            product: nil,
            purchase_count: 0
          }
        end

        def update_category_with_product(category, record)
          category[:product] = {
            id: record.product_id,
            name: record.product_name,
            price: record.product_price,
            created_by: record.creator_email
          }
          category[:purchase_count] = record.purchase_count.to_i
        end

        def parse_date(date_string)
          date_string.is_a?(String) ? Date.parse(date_string) : date_string
        end
      end
    end
  end
end
