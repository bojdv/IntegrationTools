class Product < ApplicationRecord
  has_many :categories
  accepts_nested_attributes_for :categories
end
