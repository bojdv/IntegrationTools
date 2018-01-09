class Xml < ApplicationRecord
  belongs_to :category
  belongs_to :user
  validates :xml_name, presence: true
  validates :xml_text, presence: true
end
