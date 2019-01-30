class ExternalDefectList < ApplicationRecord
  validates :key, uniqueness: true
end
