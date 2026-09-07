# app/services/app_version_service.rb

class AppVersionService
  EMPTY_CATALOG = {
    id: nil,
    number: nil,
    title: nil,
    description: nil,
    status: nil,
    released_at: nil
  }.freeze

  Result = Data.define(:latest, :update_required, :must_update, :skip_premium, :store_url)

  class << self
    def check(app_version:, platform:)
      latest = latest_live
      Result.new(
        latest: latest,
        update_required: update_required?(client_number: app_version, latest: latest),
        must_update: must_update?(client_number: app_version),
        skip_premium: skip_premium?(client_number: app_version, latest: latest),
        store_url: store_url_for(platform)
      )
    end

    def create_install(user:, platform:, number:, version_code:)
      install = AppInstall.find_or_initialize_by(user_id: user.id, platform: platform)
      install.number = number
      install.build_number = parse_version_code(version_code)
      install.app_version = AppVersion.find_by(number: number)
      install.last_seen_at = Time.current
      install.save!
      install
    end

    def latest_live
      AppVersion.live.max_by { |version| Gem::Version.new(version.number) }
    end

    def update_required?(client_number:, latest:)
      client_version = parse_semver(client_number)
      return false if client_version.blank? || latest.blank?

      client_version < Gem::Version.new(latest.number)
    end

    def must_update?(client_number:)
      client_version = parse_semver(client_number)
      return false if client_version.blank?

      AppVersion.live.where(is_force_update: true).any? do |force|
        Gem::Version.new(force.number) > client_version
      end
    end

    def skip_premium?(client_number:, latest:)
      client_version = parse_semver(client_number)
      return false if client_version.blank? || latest.blank?

      client_version > Gem::Version.new(latest.number)
    end

    private

    def store_url_for(platform)
      case platform
      when AuthConstants::Platform::IOS then AppConfig::IOS_STORE_URL.presence
      when AuthConstants::Platform::ANDROID then AppConfig::ANDROID_STORE_URL.presence
      end
    end

    def parse_semver(value)
      return if value.blank?
      return unless value.to_s.match?(AppVersionConstants::Number::FORMAT)

      Gem::Version.new(value)
    end

    def parse_version_code(value)
      return if value.blank?

      parsed = Integer(value, exception: false)
      parsed if parsed&.positive?
    end
  end
end
