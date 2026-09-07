# app/serializers/user_version_serializer.rb

class Client::UserVersionSerializer < ApplicationSerializer
  attributes :platform,
             :number,
             :build_number,
             :last_seen_at,
             :version_id
end
