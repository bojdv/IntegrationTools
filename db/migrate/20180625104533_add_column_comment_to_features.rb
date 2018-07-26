class AddColumnCommentToFeatures < ActiveRecord::Migration[5.1]
  def change
    add_column :features, :comment, :text
    add_column :features, :project_plan, :string
    add_column :features, :test_report_link, :string
    add_column :features, :start_date, :date
    add_column :features, :end_date, :date
    remove_column :features, :tz
    remove_column :features, :milestone
    add_column :features, :tz, :text
  end
end
