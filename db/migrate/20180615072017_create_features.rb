class CreateFeatures < ActiveRecord::Migration[5.1]
  def change
    create_table :features do |t|
      t.string :name
      t.string :labels
      t.references :test_plan, foreign_key: true

      t.timestamps
    end
  end
end
