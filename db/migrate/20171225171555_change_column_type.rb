class ChangeColumnType < ActiveRecord::Migration[5.1]
  def change
    change_column :xmls, :product_id, :integer, :limit => 10
  end
end
