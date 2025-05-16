class CreateAuditLogs < ActiveRecord::Migration[8.0]
   def change
    create_table :audit_logs do |t|
      t.references :admin, null: false, foreign_key: { to_table: :users }
      t.string :action, null: false
      t.references :auditable, polymorphic: true, null: false
      t.jsonb :changed_attributes, null: false

      t.timestamps
    end
  end
end
