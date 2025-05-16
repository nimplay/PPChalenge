class Category < ApplicationRecord
  # Associations
  belongs_to :creator, class_name: 'User', optional: true
  belongs_to :updater, class_name: 'User', optional: true
  has_many :product_categories, dependent: :destroy
  has_many :products, through: :product_categories

  # Validations
  validates :name, presence: true, uniqueness: true, length: { maximum: 50 }
  validates :description, length: { maximum: 500 }

  # Callbacks for auditing (versión simplificada)
  after_create :log_creation
  after_update :log_update

  private

  def log_creation
    AuditLog.create!(
      admin: creator || User.admins.first || User.first,
      action: 'create',
      auditable: self,
      audit_changes: attributes_for_audit
    )

  end

  def log_update
    return unless saved_changes.any?

    AuditLog.create!(
      admin: creator || User.admins.first,
      action: 'create',
      auditable: self,
      audit_changes: attributes_for_audit
    )
  end
   def attributes_for_audit
    attributes.except('id', 'created_at', 'updated_at', 'creator_id', 'updater_id')
  end

  def saved_changes_for_audit
    saved_changes.except('updated_at', 'updater_id')
  end
end
