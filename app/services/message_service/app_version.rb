module MessageService
  class AppVersion < Base
    CURRENT_FETCHED    = "app_version.current_fetched"
    FETCHED            = "app_version.fetched"
    CREATED            = "app_version.created"
    CREATE_FAILED      = "app_version.create_failed"
    UPDATED            = "app_version.updated"
    UPDATE_FAILED      = "app_version.update_failed"
    DISCARDED          = "app_version.discarded"
    DISCARDED_FETCHED  = "app_version.discarded_fetched"
    RESTORED           = "app_version.restored"
    NOT_FOUND          = "app_version.not_found"
  end
end

