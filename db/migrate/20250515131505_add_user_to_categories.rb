class AddUserToCategories < ActiveRecord::Migration[8.0]
   def change
    add_reference :categories, :creator, foreign_key: { to_table: :users }
    add_reference :categories, :updater, foreign_key: { to_table: :users }
    change_column_null :categories, :updater_id, true
  end
end
