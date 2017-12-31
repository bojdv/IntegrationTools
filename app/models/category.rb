class Category < ApplicationRecord
  belongs_to :product
  belongs_to :user
  has_many :xmls
  validates :category_name, presence: true
end
