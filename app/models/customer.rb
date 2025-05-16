class Customer < ApplicationRecord
  has_many :purchases, dependent: :destroy

  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone, presence: true
  validates :address, presence: true

  # Método para mostrar información básica
  def to_s
    "#{name} <#{email}>"
  end
end
