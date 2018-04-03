class CreateCcFormatValidatorLogs < ActiveRecord::Migration[5.1]
  def change
    create_table :cc_format_validator_logs do |t|
      t.string :uuid
      t.string :events
      t.string :status
      t.string :short_message
      t.text :full_message
      t.text :xml
      t.timestamps
    end
  end
end
