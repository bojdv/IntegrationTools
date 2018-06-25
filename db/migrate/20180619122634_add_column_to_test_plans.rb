class AddColumnToTestPlans < ActiveRecord::Migration[5.1]
  def change
    add_column :test_plans, :finish_date, :date
    add_column :test_plans, :status, :string
    add_column :test_plans, :comment, :text
    add_column :test_plans, :user_id, :integer, :limit => 10
  end
end
