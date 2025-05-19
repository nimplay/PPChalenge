class ImageProcessingJob < ApplicationJob
  queue_as :default

  def perform(product_id)
    product = Product.find(product_id)

    product.images.each do |image|
      [ :thumb, :medium, :large ].each do |variant|
        image.variant(variant).processed
      end
    end
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "Producto no encontrado: #{e.message}"
  end
end
