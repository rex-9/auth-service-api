# app/serializers/app_install_serializer.rb

class AppInstallSerializer < ApplicationSerializer
  attributes :platform,
             :number,
             :build_number,
             :last_seen_at,
             :app_version_id
end
