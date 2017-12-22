class CreateQueueManagers < ActiveRecord::Migration[5.1]
  def change
    create_table :queue_managers do |t|
      t.string :name
      t.string :queue
      t.string :host
      t.string :port
      t.string :user

      t.string :password

      t.timestamps
    end
  end
end
