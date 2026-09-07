# app/models/app_version.rb

class AppVersion < ApplicationRecord
  self.primary_key = "id"

  has_many :app_installs, dependent: :nullify

  enum :status, AppVersionConstants::Status::ALL.index_with(&:itself), prefix: true

  scope :with_install_counts, -> {
    counts = AppInstall.where("app_installs.app_version_id = app_versions.id").select("COUNT(*)").to_sql
    select("app_versions.*", "(#{counts}) AS install_count")
  }

  validates :number, presence: true,
            format: { with: AppVersionConstants::Number::FORMAT },
            uniqueness: { conditions: -> { kept } }
  validates :title, presence: true
  validates :status, presence: true, inclusion: { in: AppVersionConstants::Status::ALL }
  validates :ios_build_number, numericality: { only_integer: true, greater_than: 0 },
            uniqueness: { conditions: -> { kept } }, allow_nil: true
  validates :android_build_number, numericality: { only_integer: true, greater_than: 0 },
            uniqueness: { conditions: -> { kept } }, allow_nil: true

  scope :live, -> {
    where(status: AppVersionConstants::Status::PUBLISHED)
      .where("released_at IS NULL OR released_at <= ?", Time.current)
  }

  before_save :stamp_released_at_on_publish

  def install_count
    return self[:install_count].to_i if has_attribute?(:install_count)

    app_installs.count
  end

  private

  def stamp_released_at_on_publish
    return unless status == AppVersionConstants::Status::PUBLISHED

    self.released_at ||= Time.current
  end
end
