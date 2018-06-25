class Feature < ApplicationRecord
  belongs_to :test_plan
  serialize :qa, Array
  serialize :manager, Array
  serialize :developer, Array
  serialize :analytic, Array
end
