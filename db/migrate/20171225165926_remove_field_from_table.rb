class RemoveFieldFromTable < ActiveRecord::Migration[5.1]
  def change
    remove_column :xmls, :product_name
  end
end
