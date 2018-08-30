class Product < ApplicationRecord
  has_many :categories
  has_many :test_plans
  accepts_nested_attributes_for :categories
  validates :product_name, presence: true, uniqueness: {case_sensitive: false}
  default_scope {order(product_name: :asc)}
  #scope :categories_by_name, -> {categories.order(category_name: :asc)}
end
