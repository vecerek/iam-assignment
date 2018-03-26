class User < ApplicationRecord
  has_secure_password
  after_initialize :set_defaults, unless: :persisted?

  validates_uniqueness_of :email

  def set_defaults
    self.role ||= 'user'
    self.name ||= 'Anonymous'
  end
end
