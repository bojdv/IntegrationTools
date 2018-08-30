class Xml < ApplicationRecord
  belongs_to :category
  belongs_to :user
  validates :xml_name, presence: true, :uniqueness  => {case_sensitive: false, :scope => :category_id, :message => '%{value} уже есть в этой категории'}
  validates :xml_text, presence: true
  default_scope {order(xml_name: :asc)}
end
