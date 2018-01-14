class AddFieldsToQueueManager < ActiveRecord::Migration[5.1]
  def change
    add_column :queue_managers, :manager_type, :string
    add_column :queue_managers, :amq_protocol, :string
    add_column :queue_managers, :channel_manager, :string
    add_column :queue_managers, :channel, :string
    add_column :queue_managers, :queue_in, :string
    add_column :queue_managers, :user_id, :integer, :limit => 10
    rename_column :queue_managers, :queue, :queue_out
  end
end
