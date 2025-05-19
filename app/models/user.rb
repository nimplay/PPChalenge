class User < ApplicationRecord
 has_secure_password

  # Roles
  enum :role, {
    user: "user",
    admin: "admin",
    manager: "manager"
  }, default: "user", prefix: true

  # Relaciones
  has_many :created_products, class_name: "Product", foreign_key: "created_by_id"
  has_many :updated_products, class_name: "Product", foreign_key: "updated_by_id"
  has_many :audit_logs, foreign_key: "admin_id"

  # Validaciones
  validates :email, presence: true, uniqueness: true
  validates :role, presence: true
  validates :password, presence: true, length: { minimum: 6 }, if: :password_required?

  # Scopes
  scope :admins, -> { where(role: "admin") }
  scope :managers, -> { where(role: "manager") }
  scope :regular_users, -> { where(role: "user") }

  before_create :generate_jti

  # Métodos de conveniencia
  def admin?
    role_admin?
  end

  def manager?
    role_manager?
  end

  def generate_jwt
    payload = {
      sub: id,
      jti: jti,
      exp: 24.hours.from_now.to_i,
      email: email,
      role: role
    }
    JWT.encode(payload, Rails.application.credentials.secret_key_base)
  end

  private

  def generate_jti
    self.jti ||= SecureRandom.uuid
  end

  def password_required?
    password_digest.blank? || password.present?
  end
end
