class User < ApplicationRecord
  has_many :categories
  has_many :xmls
  before_save {self.email = email.downcase}
  VALID_EMAIL_REGEXP = /\A[\S]{5,}+@(bssys)\.(com)\z/i
  validates :email, presence: true, format: {with: VALID_EMAIL_REGEXP}, uniqueness: {case_sensitive: false}
  has_secure_password
end