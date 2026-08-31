# schemas
Drumee Schemas Packages
## Principles
- A file must not contain more than one routine


### To patch a routine
```console
bin/patch-from-file routine-file-path db_name|db_class 
```
A db_class may be one of yp|common|hub|drumate

### To patch a set of routines from a manifest file
```console
bin/patch-from-manifest patches-dir
```

### To create a manifest for patching from files that have been changed between two git commits
```console
bin/make-manifest git_hash1 git_hash2
```

### Build a new Drumee Schemas template from existing installation
```console
bin/make-templates git_hash1 git_hash2
```

## Mobile push registration v2

The ordered deployment route is the
[`patches/manifest.txt`](patches/manifest.txt) entry set. Table ownership lives
under [`yellow_page/tables`](yellow_page/tables/), registration transitions and
send-eligibility queries live under
[`yellow_page/procedures/deviceregistration`](yellow_page/procedures/deviceregistration/),
and the executable contract is
[`tests/notification-v2-schema.sh`](tests/notification-v2-schema.sh). Hub
recipient resolution uses the dedicated, database-bounded
`hub_members_for_mobile_push` procedure; its page contract is covered by
[`tests/mobile-push-member-page.sh`](tests/mobile-push-member-page.sh).

Full Notification history keeps acknowledgement and removal separate:
`contact_activity.dismissed_at` is the compatible read marker and `hidden_at`
is explicit removal from Activity history; MFS uses `mfs_ack` and
`mfs_dismissed` respectively. Chat/teamchat/ticket acknowledgement uses the
privacy-safe `notification_activity_history` table, which stores opaque rollup
identity and timing only. The disposable index/removal/history contracts are owned
by [`tests/notification-feed-index.sh`](tests/notification-feed-index.sh) and
[`tests/notification-feed-dismissal.sh`](tests/notification-feed-dismissal.sh),
plus [`tests/notification-rollup-history.sh`](tests/notification-rollup-history.sh).
Per-user Notification Save stores only opaque activity hashes in
`notification_activity_bookmark`; bounded concurrent writes and removal are
owned by
[`tests/notification-activity-bookmark.sh`](tests/notification-activity-bookmark.sh).

The durable boundary is compare-and-set ownership and state versioning:
registration changes, logout, account switches, and provider invalidation must
match the server-issued registration/binding/state tuple. UID-bound tombstones
make those transitions replay-safe, so delayed work cannot mutate a newer
binding. Only active, unexpired v2 registrations selected by the send procedures
are eligible; legacy anonymous registration rows are excluded. Push credential
material stays inside the schema/server boundary and must not be copied into
documentation, logs, fixtures, or migration evidence.
