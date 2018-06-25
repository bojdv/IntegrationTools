class TestPlan < ApplicationRecord
  belongs_to :product
  has_many :features, dependent: :destroy
end
