# app/services/user_version_service.rb

class UserVersionService
  class << self
    def create(user:, platform:, number:, version_code:)
      record = UserVersion.find_or_initialize_by(user_id: user.id, platform: platform)
      record.number = number
      record.build_number = parse_version_code(version_code)
      record.version = Version.lookup_by_number(number)
      record.last_seen_at = Time.current
      record.save!
      record
    end

    private

    def parse_version_code(value)
      return if value.blank?

      parsed = Integer(value, exception: false)
      parsed if parsed&.positive?
    end
  end
end
