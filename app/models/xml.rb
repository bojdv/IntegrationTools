class Xml < ApplicationRecord
  belongs_to :product
  def name_of_method
    "#{xml_name} #{product_name}"
  end
end
