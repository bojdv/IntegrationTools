class AddColumnToFeatures < ActiveRecord::Migration[5.1]
  def change
    add_column :features, :project_name, :string
    add_column :features, :backlog, :string
    add_column :features, :feature_url, :string
    add_column :features, :test_scope, :text
    add_column :features, :tz, :string
    add_column :features, :milestone, :string
    add_column :features, :testcases, :string
    add_column :features, :analytic, :string
    add_column :features, :developer, :string
    add_column :features, :qa, :string
    add_column :features, :manager, :string
  end
end
