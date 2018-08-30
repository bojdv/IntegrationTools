class AddColumnStatusToFeatures < ActiveRecord::Migration[5.1]
  def change
    add_column :features, :status, :string
  end
end
