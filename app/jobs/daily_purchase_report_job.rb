class DailyPurchaseReportJob
  include Sidekiq::Job
  sidekiq_options queue: :reports, retry: 3

  def perform
    purchases = Purchase.where(created_at: Date.yesterday.all_day)

    report_data = {
      date: Date.yesterday,
      total_purchases: purchases.count,
      total_revenue: purchases.sum(:total_price),
      top_products: purchases.joins(:product)
                            .group('products.name')
                            .order('count_all DESC')
                            .limit(5)
                            .count,
      new_customers: Customer.where(created_at: Date.yesterday.all_day).count
    }

    AdminMailer.daily_purchase_report(report_data).deliver_now
  rescue => e
    Rails.logger.error "Error generating daily report: #{e.message}"
    raise
  end

  private

  def generate_report(purchases)
    {
      date: Date.yesterday,
      total_purchases: purchases.count,
      total_revenue: purchases.sum(:total_price),
      top_products: purchases.joins(:product)
                            .group('products.name')
                            .order('count_all DESC')
                            .limit(5)
                            .count,
      customers_count: purchases.distinct.count(:customer_id)
    }
  end

  def save_to_storage(data)
    file_name = "purchases_report_#{Date.yesterday}.json"
    S3_BUCKET.put_object(
      key: "reports/#{file_name}",
      body: data.to_json
    )
  end
end
