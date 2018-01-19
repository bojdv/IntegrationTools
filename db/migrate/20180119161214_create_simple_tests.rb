class CreateSimpleTests < ActiveRecord::Migration[5.1]
  def change
    create_table :simple_tests do |t|
      t.integer :xml_id, limit:10
      t.integer :queue_manager_id, limit:10

      t.timestamps
    end
    add_index :simple_tests, :xml_id, unique: true
  end
end
