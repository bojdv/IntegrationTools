class Product < ApplicationRecord
  has_many :categories
  accepts_nested_attributes_for :categories
  validates :product_name, presence: true, uniqueness: {case_sensitive: false}
end
