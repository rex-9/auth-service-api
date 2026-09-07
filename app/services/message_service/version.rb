module MessageService
  class Version < Base
    CURRENT_FETCHED    = "version.current_fetched"
    FETCHED            = "version.fetched"
    CREATED            = "version.created"
    CREATE_FAILED      = "version.create_failed"
    UPDATED            = "version.updated"
    UPDATE_FAILED      = "version.update_failed"
    DISCARDED          = "version.discarded"
    DISCARDED_FETCHED  = "version.discarded_fetched"
    RESTORED           = "version.restored"
    NOT_FOUND          = "version.not_found"
  end
end
