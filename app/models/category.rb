class Category < ApplicationRecord
  belongs_to :product
  belongs_to :user
  has_many :xmls
  validates :category_name, presence: true, :uniqueness  => {case_sensitive: false, :scope => :product_id, :message => 'Название %{value} уже существует в этом разделе'}
end
