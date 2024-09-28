class UserSerializer
  include JSONAPI::Serializer
  attributes :id, :email, :name, :provider, :photo, :created_at, :updated_at
end
