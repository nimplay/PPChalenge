class RenameChangesToAuditChangesInAuditLogs < ActiveRecord::Migration[8.0]
  def change
    rename_column :audit_logs, :changes, :audit_changes
  end
end
