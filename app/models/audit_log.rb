class AuditLog < ApplicationRecord
  belongs_to :admin, class_name: 'User'
  belongs_to :auditable, polymorphic: true

  validates :action, presence: true, inclusion: { in: %w[create update delete] }
  validates :audit_changes, presence: true

  attribute :audit_changes, :jsonb, default: -> { {} }

  def self.log_changes(record, action, user)
    create!(
      admin: user,
      action: action,
      auditable: record,
      audit_changes: record.attributes_for_audit
    )
  end
end
