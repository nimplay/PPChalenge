class Purchase < ApplicationRecord
  belongs_to :product
  belongs_to :customer

  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :total_price, numericality: { greater_than_or_equal_to: 0 }
  validates :status, inclusion: { in: %w[completed pending cancelled] }

  before_validation :calculate_total_price, if: :quantity_changed?

  private

  def calculate_total_price
    self.total_price = product.price * quantity
  end
end
