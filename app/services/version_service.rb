# app/services/version_service.rb

class VersionService
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
    def check(version:, platform:)
      latest = latest_live
      Result.new(
        latest: latest,
        update_required: update_required?(client_number: version, latest: latest),
        must_update: must_update?(client_number: version),
        skip_premium: skip_premium?(client_number: version, latest: latest),
        store_url: store_url_for(platform)
      )
    end

    def latest_live
      Version.live.max_by { |version| Gem::Version.new(version.number) }
    end

    def update_required?(client_number:, latest:)
      client_version = parse_semver(client_number)
      return false if client_version.blank? || latest.blank?

      client_version < Gem::Version.new(latest.number)
    end

    def must_update?(client_number:)
      client_version = parse_semver(client_number)
      latest = latest_live
      return false if client_version.blank? || latest.blank? || !latest.is_force_update

      Gem::Version.new(latest.number) > client_version
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
      return unless value.to_s.match?(VersionConstants::Number::FORMAT)

      Gem::Version.new(value)
    end
  end
end
