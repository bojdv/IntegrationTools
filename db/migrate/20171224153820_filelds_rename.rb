class FileldsRename < ActiveRecord::Migration[5.1]
  def change
    rename_column  :products, :name, :product_name
    rename_column  :queue_managers, :name, :manager_name
    rename_column  :xmls, :name, :xml_name
    rename_column  :xmls, :xml, :xml_text
    rename_column  :xmls, :product, :product_name
  end
end
