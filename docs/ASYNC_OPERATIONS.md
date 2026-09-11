# Asynchronous operation contract

Queued work exposed to clients uses one lifecycle:

```text
queued -> processing -> completed | failed
```

Every lifecycle payload carries:

- `operation_id`: stable for the full lifetime of one operation.
- `operation_type`: one of the values in `NotificationConstants::OperationType`.
- `operation_status`: one of the values in `NotificationConstants::OperationStatus`.
- `link`: the client route for the affected resource.

Producers must create a new `operation_id` for each invocation and reuse that ID
for every transition of that invocation. Re-running work for the same resource
must not reuse an earlier operation's ID. Consumers upsert by `operation_id`; a
transition updates the existing UI item instead of creating a second notification.
Persisted in-app operations use the unique `user_id + operation_id` constraint to
enforce that rule server-side.

Admin jobs carry the requesting user's ID explicitly. They must not infer the
recipient only from the resource creator because an administrator may operate on
a resource created by another user.

The contract applies to AI responses, asset compression, video thumbnail
generation, notification delivery, and payment-webhook processing. Provider or
domain-specific states may remain internal, but client-facing payloads must map
them to the four statuses above.

When adding another queued operation:

1. Add its type to `NotificationConstants::OperationType`.
2. Return the queued operation fields in the `202 Accepted` response.
3. Emit `processing` when the worker starts.
4. Emit exactly one terminal `completed` or `failed` transition.
5. Add the resource link and keep it valid in Web and Mobile.
6. Document the response/event in OpenAPI and cover every transition in specs.
