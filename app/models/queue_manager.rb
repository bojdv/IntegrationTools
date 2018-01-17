class QueueManager < ApplicationRecord
  validates :manager_name, presence: true, :uniqueness  => {case_sensitive: false, :message => "Название %{value} уже есть в базе"}
end
