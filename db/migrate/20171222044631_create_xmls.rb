class CreateXmls < ActiveRecord::Migration[5.1]
  def change
    create_table :xmls do |t|
      t.belongs_to :product, index: true
      t.string :name
      t.text :xml
      t.string :product
      t.timestamps
    end
  end
end
