class AddColumnReportUrlToTestPlans < ActiveRecord::Migration[5.1]
  def change
    add_column :test_plans, :report_url, :string
  end
end
