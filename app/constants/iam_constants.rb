# app/constants/iam_constants.rb

module IamConstants
  module Role
    SUPER_ADMIN = "super_admin".freeze
    ADMIN       = "admin".freeze
    USER        = "user".freeze
    ALL         = [ SUPER_ADMIN, ADMIN, USER ].freeze

    RESTRICTED_FOR_ADMIN = [
      "users",
      "roles",
      "permissions",
      "user_roles",
      "versions",
      "user_versions"
    ].freeze
  end

  module Action
    READ   = "read".freeze
    CREATE = "create".freeze
    UPDATE = "update".freeze
    DELETE = "delete".freeze
    ALL    = [ READ, CREATE, UPDATE, DELETE ].freeze
  end

  module Resource
    USERS         = "users".freeze
    ROLES         = "roles".freeze
    USER_ROLES    = "user_roles".freeze
    PERMISSIONS   = "permissions".freeze
    PRODUCTS      = "products".freeze
    PAYMENTS      = "payments".freeze
    SUBSCRIPTIONS = "subscriptions".freeze
    TRANSACTIONS  = "transactions".freeze
    ACCESSES      = "accesses".freeze
    ASSETS        = "assets".freeze
    NOTIFICATIONS = "notifications".freeze
    AI            = "ai".freeze
    SPEECH        = "speech".freeze
    LOGS          = "logs".freeze
    FEEDBACKS     = "feedbacks".freeze
    ANALYTICS     = "analytics".freeze
    VERSIONS      = "versions".freeze
    USER_VERSIONS = "user_versions".freeze
    ALL           = [
      USERS, ROLES, USER_ROLES, PERMISSIONS, PRODUCTS, PAYMENTS,
      SUBSCRIPTIONS, TRANSACTIONS, ACCESSES, ASSETS, NOTIFICATIONS,
      AI, SPEECH, LOGS, FEEDBACKS, ANALYTICS, VERSIONS, USER_VERSIONS
    ].freeze
  end

  module DefaultPermissions
    USER = [
      { resource: Resource::LOGS, actions: [ Action::CREATE ] },
      { resource: Resource::PRODUCTS, actions: [ Action::READ ] },
      { resource: Resource::PAYMENTS, actions: [ Action::CREATE ] },
      { resource: Resource::SUBSCRIPTIONS, actions: [ Action::READ, Action::CREATE ] },
      { resource: Resource::TRANSACTIONS, actions: [ Action::READ ] },
      { resource: Resource::ACCESSES, actions: [ Action::READ ] },
      { resource: Resource::ASSETS, actions: Action::ALL },
      { resource: Resource::USERS, actions: Action::ALL },
      { resource: Resource::AI, actions: Action::ALL },
      { resource: Resource::SPEECH, actions: Action::ALL },
      { resource: Resource::FEEDBACKS, actions: [ Action::CREATE, Action::READ ] },
      { resource: Resource::NOTIFICATIONS, actions: [ Action::READ, Action::UPDATE, Action::DELETE ] },
      { resource: Resource::VERSIONS, actions: [ Action::READ ] },
      { resource: Resource::USER_VERSIONS, actions: [ Action::CREATE ] }
    ].freeze
  end
end
