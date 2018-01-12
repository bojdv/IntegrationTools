class AddIndex < ActiveRecord::Migration[5.1]
  def change
    add_index :xmls, :category_id
  end
end
