class AppInstallAdminSerializer < ApplicationSerializer
  set_type :app_install

  attributes :user_id,
             :platform,
             :number,
             :build_number,
             :last_seen_at,
             :app_version_id

  attribute :user_email do |install|
    install.user&.email
  end
end
