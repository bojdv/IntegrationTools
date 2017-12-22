class CreateProducts < ActiveRecord::Migration[5.1]
  def change
    create_table :products do |t|
      t.has_many :xmls
      t.string :name
      t.timestamps
    end
  end
end
