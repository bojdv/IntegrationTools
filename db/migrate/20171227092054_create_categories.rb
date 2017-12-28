class CreateCategories < ActiveRecord::Migration[5.1]
  def change
    create_table :categories do |t|
      t.belongs_to :product, index: true
      t.string :category_name
      t.integer :product_id, limit:10

      t.timestamps
    end
    rename_column  :xmls, :product_id, :category_id
  end
end
