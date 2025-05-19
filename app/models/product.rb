class Product < ApplicationRecord
  # Asociaciones
  belongs_to :creator, class_name: "User", foreign_key: "user_id"
  belongs_to :updater, class_name: "User", foreign_key: "updated_by_id", optional: true

  has_many :product_categories, dependent: :destroy
  has_many :categories, through: :product_categories
  has_many :purchases, dependent: :nullify

  # Configuración de Active Storage
  has_many_attached :images do |attachable|
    attachable.variant :thumb, resize_to_limit: [ 300, 300 ]
    attachable.variant :medium, resize_to_limit: [ 600, 600 ]
    attachable.variant :large, resize_to_limit: [ 1200, 1200 ]
  end

  # Constantes de validación
  IMAGE_CONTENT_TYPES = %w[image/jpeg image/png image/webp].freeze
  MAX_IMAGE_SIZE = 5.megabytes
  MAX_IMAGES_PER_PRODUCT = 5

  # Validaciones
  validates :name, presence: true, length: { maximum: 100 }
  validates :description, presence: true, length: { maximum: 1000 }
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :stock, presence: true, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 0
  }
  validates :user_id, presence: true
  validate :validate_images

  # Enumerados
  enum :product_type, {
    physical: "physical",
    digital: "digital",
    service: "service"
  }, default: "physical"

  # Scopes
  scope :with_images, -> { joins(:images_attachments).distinct }
  scope :by_image_type, ->(content_type) {
    joins(images_attachments: :blob).where(active_storage_blobs: { content_type: content_type })
  }

  # Callbacks
  before_update :track_update
  after_create :log_creation
  after_update :log_update
  after_commit :process_images_background, if: :saved_change_to_images?

  # Métodos de instancia
  def thumbnail_url
    return unless images.attached?
    images.first.variant(:thumb).processed.url
  rescue Aws::S3::Errors::NoSuchKey => e
    Rails.logger.error "Error al procesar thumbnail: #{e.message}"
    nil
  end

  def image_urls
    return [] unless images.attached?

    images.map do |img|
      img.variant(:medium).processed.url
    rescue Aws::S3::Errors::NoSuchKey => e
      Rails.logger.error "Error al procesar imagen: #{e.message}"
      nil
    end.compact
  end

  private

  def validate_images
    return unless images.attached?

    if images.count > MAX_IMAGES_PER_PRODUCT
      errors.add(:images, "No se pueden adjuntar más de #{MAX_IMAGES_PER_PRODUCT} imágenes")
    end

    images.each do |image|
      unless IMAGE_CONTENT_TYPES.include?(image.content_type)
        errors.add(:images, "Tipo de archivo no permitido: #{image.content_type}")
      end

      if image.byte_size > MAX_IMAGE_SIZE
        errors.add(:images, "#{image.filename} excede el tamaño máximo de #{MAX_IMAGE_SIZE / 1.megabyte}MB")
      end
    end
  end

  def process_images_background
    ImageProcessingJob.perform_later(id)
  end

  def saved_change_to_images?
    saved_change_to_attribute?(:images) && images.attached?
  end

  def track_update
    self.updated_by_id = Current.user&.id if changed?
  end

  def log_creation
    AuditLog.create!(
      admin: creator,
      action: "create",
      auditable: self,
      audit_changes: attributes.except("id", "created_at", "updated_at")
    )
  end

  def log_update
    return unless saved_changes.any?
    AuditLog.create!(
      admin: updater || creator,
      action: "update",
      auditable: self,
      audit_changes: saved_changes.except("updated_at", "updated_by_id")
    )
  end

  def create_audit_log(action:, changes:)
    AuditLog.create!(
      admin: updater || creator,
      action: "update",
      auditable: self,
      audit_changes: saved_changes.except("updated_at", "updater_id")
    )
  end
end
