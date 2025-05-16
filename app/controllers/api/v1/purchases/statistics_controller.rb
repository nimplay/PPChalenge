module Api
  module V1
    module Purchases
      class StatisticsController < ApplicationController
        include Authenticable
        before_action :validate_admin_role
        before_action :set_date_range, only: [:index]

        def index
          stats = {
            total_revenue: calculate_total_revenue,
            purchase_count: calculate_purchase_count,
            average_order_value: calculate_average_order_value,
            top_products: top_products(5),
            revenue_by_category: revenue_by_category,
            timeline_data: timeline_data(params[:granularity] || 'day')
          }

          render json: { data: stats }
        end

        private

        def validate_admin_role
          return if current_user.admin? || current_user.manager?
          render_unauthorized('Access restricted to admins and managers')
        end

        def set_date_range
          return unless date_filter?
          @start_date = Date.parse(params[:start_date])
          @end_date = Date.parse(params[:end_date])
        end

        def calculate_total_revenue
          base_query.sum('purchases.quantity * products.price')
        end

        def calculate_purchase_count
          base_query.count
        end

        def calculate_average_order_value
          total = calculate_total_revenue
          count = calculate_purchase_count
          count.positive? ? (total / count).round(2) : 0
        end

        def top_products(limit)
          Purchase.joins(:product)
                  .where(date_filter)
                  .group('products.id, products.name')
                  .select('products.id, products.name, SUM(purchases.quantity * products.price) as revenue')
                  .order('revenue DESC')
                  .limit(limit)
                  .map do |p|
                    {
                      id: p.id,
                      name: p.name,
                      revenue: p.revenue.to_f.round(2)
                    }
                  end
        end

        def revenue_by_category
          Category.joins(products: :purchases)
                  .where(date_filter)
                  .group('categories.id, categories.name')
                  .select('categories.id, categories.name, SUM(purchases.quantity * products.price) as revenue')
                  .order('revenue DESC')
                  .map do |c|
                    {
                      id: c.id,
                      name: c.name,
                      revenue: c.revenue.to_f.round(2)
                    }
                  end
        end

        def timeline_data(granularity)
          case granularity
          when 'hour'
            group_by_hour
          when 'day'
            group_by_day
          when 'week'
            group_by_week
          when 'month'
            group_by_month
          else
            group_by_day
          end
        end

        def group_by_hour
          base_query.group_by_hour('purchases.created_at', format: '%Y-%m-%d %H:00')
                   .sum('purchases.quantity * products.price')
        end

        def group_by_day
          base_query.group_by_day('purchases.created_at')
                   .sum('purchases.quantity * products.price')
        end

        def group_by_week
          base_query.group_by_week('purchases.created_at')
                   .sum('purchases.quantity * products.price')
        end

        def group_by_month
          base_query.group_by_month('purchases.created_at')
                   .sum('purchases.quantity * products.price')
        end

        def base_query
          query = Purchase.joins(:product)
          query = query.where(created_at: @start_date.beginning_of_day..@end_date.end_of_day) if date_filter?
          apply_additional_filters(query)
        end

        def apply_additional_filters(query)
          query = query.joins(:product).where(products: { user_id: params[:admin_id] }) if params[:admin_id].present?
          query = query.where(customer_id: params[:customer_id]) if params[:customer_id].present?
          query = query.joins(product: :categories).where(categories: { id: params[:category_id] }) if params[:category_id].present?
          query
        end

        def date_filter
          return {} unless date_filter?
          { created_at: @start_date.beginning_of_day..@end_date.end_of_day }
        end

        def date_filter?
          params[:start_date].present? && params[:end_date].present?
        end

        def permitted_params
          params.permit(
            :start_date, :end_date,
            :category_id, :customer_id,
            :admin_id, :granularity
          )
        end

        def render_unauthorized(message)
          render json: { error: message }, status: :unauthorized
        end
      end
    end
  end
end
