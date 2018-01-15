class AddColumnVisibleAllToQueueManager < ActiveRecord::Migration[5.1]
  def change
    add_column :queue_managers, :visible_all, :boolean, :default => 0
  end
end
