module Api
  module V1
    module Purchases
      class SearchController < ApplicationController
        include Authenticable
        before_action :validate_admin_role
        before_action :set_pagination_defaults, only: [:index]

        def index
          @purchases = filtered_purchases
                      .includes(:product, :customer, product: [:categories, :creator])
                      .page(@page)
                      .per(@per_page)

          render json: purchase_response
        end

        private

        def validate_admin_role
          return if current_user.admin? || current_user.manager?
          render_unauthorized('Access restricted to admins and managers')
        end

        def set_pagination_defaults
          @page = params[:page] || 1
          @per_page = params[:per_page] || 20
        end

        def filtered_purchases
          purchases = Purchase.all
          filters.each do |filter|
            purchases = send("apply_#{filter}_filter", purchases) if send("#{filter}_filter?")
          end
          purchases
        end

        def filters
          [:date, :category, :customer, :admin]
        end

        def date_filter?
          params[:start_date].present? && params[:end_date].present?
        end

        def apply_date_filter(purchases)
          start_date = Date.parse(params[:start_date])
          end_date = Date.parse(params[:end_date])
          purchases.where(created_at: start_date.beginning_of_day..end_date.end_of_day)
        end

        def category_filter?
          params[:category_id].present?
        end

        def apply_category_filter(purchases)
          purchases.joins(product: :categories).where(categories: { id: params[:category_id] })
        end

        def customer_filter?
          params[:customer_id].present?
        end

        def apply_customer_filter(purchases)
          purchases.where(customer_id: params[:customer_id])
        end

        def admin_filter?
          params[:admin_id].present?
        end

        def apply_admin_filter(purchases)
          purchases.joins(:product).where(products: { user_id: params[:admin_id] })
        end

        def purchase_response
          {
            data: @purchases.map { |p| format_purchase(p) },
            meta: {
              total_count: @purchases.total_count,
              total_pages: @purchases.total_pages,
              current_page: @purchases.current_page,
              per_page: @purchases.limit_value,
              filters: permitted_params
            }
          }
        end

        def format_purchase(purchase)
          {
            id: purchase.id,
            product: {
              id: purchase.product.id,
              name: purchase.product.name,
              price: purchase.product.price,
              categories: purchase.product.categories.pluck(:name)
            },
            customer: {
              id: purchase.customer.id,
              name: purchase.customer.name,
              email: purchase.customer.email
            },
            quantity: purchase.quantity,
            total_price: purchase.total_price,
            purchased_at: purchase.created_at,
            admin_creator: purchase.product.creator.email
          }
        end

        def permitted_params
          params.permit(
            :start_date, :end_date,
            :category_id, :customer_id,
            :admin_id, :page, :per_page
          )
        end

        def render_unauthorized(message)
          render json: { error: message }, status: :unauthorized
        end
      end
    end
  end
end
