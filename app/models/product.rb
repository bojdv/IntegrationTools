class Product < ApplicationRecord
  has_many :categories
  has_many :test_plans
  accepts_nested_attributes_for :categories
  validates :product_name, presence: true, uniqueness: {case_sensitive: false}
end
