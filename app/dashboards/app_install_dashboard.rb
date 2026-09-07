require "administrate/base_dashboard"

class AppInstallDashboard < Administrate::BaseDashboard
  def display_resource(app_install)
    "#{app_install.platform} #{app_install.number}"
  end

  ATTRIBUTE_TYPES = {
    id: Field::String,
    user: Field::BelongsTo,
    platform: Field::Select.with_options(searchable: false, collection: ->(field) { field.resource.class.send(field.attribute.to_s.pluralize).keys }),
    number: Field::String,
    build_number: Field::Number,
    last_seen_at: Field::DateTime,
    app_version: Field::BelongsTo,
    created_by_id: Field::String,
    creator: Field::BelongsTo,
    discarded_at: Field::DateTime,
    discarded_by_id: Field::String,
    discarder: Field::BelongsTo,
    undiscarded_at: Field::DateTime,
    undiscarded_by_id: Field::String,
    undiscarder: Field::BelongsTo,
    updated_by_id: Field::String,
    updater: Field::BelongsTo,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    user
    platform
    number
    build_number
    last_seen_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    user
    platform
    number
    build_number
    last_seen_at
    app_version
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = [].freeze

  COLLECTION_FILTERS = {}.freeze
end
