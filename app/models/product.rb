class Product < ApplicationRecord
  has_many :xmls
  accepts_nested_attributes_for :xmls
end
