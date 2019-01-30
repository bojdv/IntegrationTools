class CreateExternalDefectLists < ActiveRecord::Migration[5.1]
  def change
    create_table :external_defect_lists do |t|
      t.string :key
      t.index :key, unique: true
      t.string :summary
      t.datetime :created
      t.string :status
      t.string :labels
      t.text :reason

      t.timestamps
    end
  end
end
