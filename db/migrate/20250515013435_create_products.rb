class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    unless table_exists?(:users)
      create_table :users do |t|
        t.string :email, null: false, default: ""
        t.string :password_digest, null: false
        t.string :role, null: false, default: "user"
        t.string :jti, null: false
        t.timestamps null: false

        t.index [:email], unique: true
        t.index [:jti], unique: true
      end
    else
      # Si la tabla ya existe, transformarla
      rename_column :users, :encrypted_password, :password_digest
      remove_column :users, :reset_password_token
      remove_column :users, :reset_password_sent_at
      remove_column :users, :remember_created_at
      change_column_null :users, :jti, false
    end
  end
end
