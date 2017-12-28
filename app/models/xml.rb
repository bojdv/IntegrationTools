class Xml < ApplicationRecord
  belongs_to :category
  validates :xml_name, presence: true
  validates :xml_text, presence: true
end
