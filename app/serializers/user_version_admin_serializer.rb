class UserVersionAdminSerializer < ApplicationSerializer
  set_type :user_version

  attributes :user_id,
             :platform,
             :number,
             :build_number,
             :last_seen_at,
             :version_id

  attribute :user_email do |record|
    record.user&.email
  end
end
