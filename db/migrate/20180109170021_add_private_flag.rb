class AddPrivateFlag < ActiveRecord::Migration[5.1]
  def change
    add_column :xmls, :private, :boolean
    add_column :categories, :private, :boolean
    add_column :xmls, :xml_description, :text
  end
end
