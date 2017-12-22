class AddProductIdToXmls < ActiveRecord::Migration[5.1]
  def change
    add_column :xmls, :product_id, :number
  end
end
