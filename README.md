# Drumee Schemas

The database schema for [Drumee](https://drumee.com): every table, stored
procedure, function and trigger, plus the tooling to apply them.

- **Docs:** [docs.drumee.com](https://docs.drumee.com/introduction/)

---

## The one rule

**One routine per file.** Every `.sql` file contains exactly one stored
procedure, function, table definition or trigger. No exceptions. The patch
tooling relies on it, and so does the ability to review a change.

## How the schema is organised

Drumee is multi-tenant: a workspace and a user each get their own database,
built from a template. The directories map to those database classes:

| Directory | Database class | Contains |
|---|---|---|
| `yellow_page/` | `yp` | The central directory — identity, hubs, media, sharing, billing |
| `hub/` | `hub` | Per-workspace schema |
| `drumate/` | `drumate` | Per-user schema |
| `common/` | `common` | Routines applied to every database class |
| `mailserver/` | | Mail server schema |
| `utils/`, `udf/` | | Helper routines and user-defined functions |
| `templates/` | | Schema templates used to provision new databases |

## Applying changes

Patch a single routine:

```console
bin/patch-from-file <routine-file-path> <db_name|db_class>
```

`db_class` is one of `yp`, `common`, `hub` or `drumate`.

Patch everything listed in a manifest:

```console
bin/patch-from-manifest <patches-dir>
```

Generate a manifest from the files that changed between two commits:

```console
bin/make-manifest <git_hash1> <git_hash2>
```

Build a new schema template from an existing installation:

```console
bin/make-templates <git_hash1> <git_hash2>
```

## Other tooling

| Script | What it does |
|---|---|
| `bin/compare-routines` | Diff routines between two databases |
| `bin/compare-tables-structure` | Diff table structures |
| `bin/scan-tables-structure` | Dump the structure of a database's tables |
| `bin/lookup-errors` | Search the error log |
| `bin/build-seeds` | Build the seed databases |
| `bin/make-changelog` | Generate a changelog entry |
| `bin/update-manifest` | Update an existing manifest |

## Care

These scripts write to live databases. A few things worth knowing before you
run one:

- Some files under `templates/` and the table definitions begin with
  `DROP TABLE`. **Read a table file before applying it** — applying one to a
  populated database will destroy its contents.
- A breaking change to a stored procedure should ship as a new version
  (`name_v2`) rather than a redefinition, so running instances keep working
  until the callers are updated.
- The filename must match the routine name inside it.

## Contributing

See the org [CONTRIBUTING guide](https://github.com/drumee/.github/blob/main/CONTRIBUTING.md).
Questions: [Discussions](https://github.com/orgs/drumee/discussions).

## License

AGPL-3.0 — see [LICENSE](LICENSE).

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
