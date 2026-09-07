# app/models/user_version.rb

class UserVersion < ApplicationRecord
  self.primary_key = "id"

  belongs_to :user
  belongs_to :version, optional: true

  enum :platform, AuthConstants::Platform::ALL.index_with(&:itself), prefix: true

  validates :platform, presence: true, inclusion: { in: AuthConstants::Platform::ALL }
  validates :number, presence: true, format: { with: VersionConstants::Number::FORMAT }
  validates :user_id, uniqueness: { scope: :platform, conditions: -> { kept } }
  validates :build_number, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :last_seen_at, presence: true
end
