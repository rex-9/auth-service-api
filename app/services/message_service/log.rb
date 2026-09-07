module MessageService
  class Log < Base
    OCCURRENCE_RECORDED = "client.logs.occurrence_recorded"
    CREATED = "client.logs.created"
    CREATE_FAILED = "client.logs.create_failed"
    FETCHED = "client.logs.fetched"
    FETCHED_ONE = "client.logs.fetched_one"
    RESOLVED = "client.logs.resolved"
    UNRESOLVED = "client.logs.unresolved"
    DELETED = "client.logs.deleted"
  end
end
