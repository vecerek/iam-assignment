class User < ApplicationRecord
  has_secure_password
  after_initialize :set_defaults, unless: :persisted?

  def set_defaults
    self.role ||= 'user'
    self.name ||= 'Anonymous'
  end
end
