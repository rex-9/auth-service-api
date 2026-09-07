# app/models/version.rb

class Version < ApplicationRecord
  self.primary_key = "id"

  has_many :user_versions, dependent: :nullify
  has_many :feedbacks, dependent: :nullify
  has_many :log_clients, class_name: "Log::Client", dependent: :nullify

  enum :status, VersionConstants::Status::ALL.index_with(&:itself), prefix: true

  scope :with_install_counts, -> {
    counts = UserVersion.where("user_versions.version_id = versions.id").select("COUNT(*)").to_sql
    select("versions.*", "(#{counts}) AS install_count")
  }

  validates :number, presence: true,
            format: { with: VersionConstants::Number::FORMAT },
            uniqueness: { conditions: -> { kept } }
  validates :title, presence: true
  validates :status, presence: true, inclusion: { in: VersionConstants::Status::ALL }
  validates :ios_build_number, numericality: { only_integer: true, greater_than: 0 },
            uniqueness: { conditions: -> { kept } }, allow_nil: true
  validates :android_build_number, numericality: { only_integer: true, greater_than: 0 },
            uniqueness: { conditions: -> { kept } }, allow_nil: true

  scope :live, -> {
    where(status: VersionConstants::Status::PUBLISHED)
      .where("released_at IS NULL OR released_at <= ?", Time.current)
  }

  def self.lookup_by_number(number)
    return if number.blank?

    find_by(number: number)
  end

  before_save :yank_other_published_versions, if: :publishing?
  before_save :stamp_released_at_on_publish

  def install_count
    return self[:install_count].to_i if has_attribute?(:install_count)

    user_versions.count
  end

  private

  def publishing?
    status == VersionConstants::Status::PUBLISHED
  end

  def yank_other_published_versions
    others = self.class.where(status: VersionConstants::Status::PUBLISHED)
    others = others.where.not(id: id) if id.present?
    others.update_all(
      status: VersionConstants::Status::YANKED,
      updated_at: Time.current
    )
  end

  def stamp_released_at_on_publish
    return unless publishing?

    self.released_at ||= Time.current
  end
end
