# app/serializers/version_serializer.rb

class VersionSerializer < ApplicationSerializer
  attributes :number,
             :title,
             :description,
             :status,
             :released_at

  attribute :update_required do |_version, params|
    params[:update_required]
  end

  attribute :must_update do |_version, params|
    params[:must_update]
  end

  attribute :skip_premium do |_version, params|
    params[:skip_premium]
  end

  attribute :store_url do |_version, params|
    params[:store_url]
  end
end
