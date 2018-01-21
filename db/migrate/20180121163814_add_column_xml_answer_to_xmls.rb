class AddColumnXmlAnswerToXmls < ActiveRecord::Migration[5.1]
  def change
    add_column :xmls, :xml_answer, :text
  end
end
