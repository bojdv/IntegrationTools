class AddClumnTestDataToFeatures < ActiveRecord::Migration[5.1]
  def change
    add_column :features, :test_data, :text
  end
end
