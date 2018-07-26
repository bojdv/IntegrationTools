class CreateTestPlans < ActiveRecord::Migration[5.1]
  def change
    create_table :test_plans do |t|
      t.string :name
      t.references :product, foreign_key: true

      t.timestamps
    end
  end
end
