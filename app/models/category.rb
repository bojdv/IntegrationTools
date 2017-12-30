class Category < ApplicationRecord
  belongs_to :product
  has_many :xmls
  validates :category_name, presence: true
end
