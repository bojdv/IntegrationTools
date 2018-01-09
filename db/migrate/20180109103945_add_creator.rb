class AddCreator < ActiveRecord::Migration[5.1]
  def change
    add_column :xmls, :creator_id, :integer, :limit => 10
    add_column :categories, :creator_id, :integer, :limit => 10
  end
end
