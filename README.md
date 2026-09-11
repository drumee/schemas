# Drumee Schemas — multi-tenant MariaDB schema and migration tooling

The database layer of [**Drumee**](https://drumee.com), an open-source,
self-hosted collaboration platform: files, folder-native chat, video meetings
and fine-grained permissions, running on infrastructure the owner controls.
This repository holds every table, stored procedure, function and trigger it
runs on, plus the tooling that applies them across a live fleet.

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL_v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)
[![MariaDB](https://img.shields.io/badge/MariaDB-003545?logo=mariadb&logoColor=white)](https://mariadb.org/)
[![Self-hosted](https://img.shields.io/badge/self--hosted-yes-success)](https://docs.drumee.com/self-hosting/overview)

**[Documentation](https://docs.drumee.com/introduction/)** ·
**[Self-hosting guides](https://docs.drumee.com/self-hosting/overview)** ·
**[Architecture](https://docs.drumee.com/self-hosting/architecture)** ·
**[Discussions](https://github.com/orgs/drumee/discussions)**

---

## Why this schema looks unusual

Most collaboration platforms put every tenant in one database and separate them
with a `tenant_id` column. Drumee does not. **Every workspace and every user
gets its own MariaDB database**, provisioned from a template at signup and torn
down with the account.

That choice is what makes data sovereignty real rather than a policy promise:
one tenant's data is a separate database that can be backed up, moved, exported
or destroyed on its own, and a query cannot accidentally cross a tenant boundary
because the boundary is the database, not a `WHERE` clause.

The cost is that a schema change is a **fleet operation** — a stored procedure
has to be applied to every database of its class, not once to a shared table.
That is what the tooling in `bin/` exists for, and why the "one routine per
file" rule below is not a style preference.

## Who this repository is for

- **Self-hosting Drumee?** You do not need this repo. Follow the
  [self-hosting guides](https://docs.drumee.com/self-hosting/overview) — the
  schema is installed for you.
- **Contributing a back-end change?** Anything touching persistence lands here,
  and it lands as SQL, not as an ORM migration.
- **Evaluating the architecture?** Start with *Why this schema looks unusual*
  above and the [architecture docs](https://docs.drumee.com/self-hosting/architecture).

## Prerequisites

- **MariaDB**, and a **running Drumee instance** you can safely break. The
  tooling reads that instance's own registry to discover which databases exist,
  so it cannot run against a bare server.
- **Node.js** — `bin/patch.js` and the manifest tooling are Node.
- The quickest disposable instance is the
  [self-hosting quick start](https://docs.drumee.com/self-hosting/overview).

## Quick start — read before you write

Every command here talks to live databases. Start by comparing two you already
have, which only reads:

```console
# Do two databases actually agree?
bin/compare-routines <db_a> <db_b>
bin/compare-tables-structure <db_a> <db_b>
```

Then apply a **single routine** to a **single database**:

```console
bin/patch-from-file yellow_page/procedures/<area>/<name>.sql yp
```

> ⚠️ Read [**Care**](#care) below before running anything that writes. In short:
> some files begin with `DROP TABLE`, `common/` applies to the whole fleet, and a
> procedure whose signature changed must ship as `name_v2`.

## Architecture at a glance

```
              yp  ── the central directory
                    identity · hubs · media · sharing · billing
                     │
      ┌──────────────┼──────────────┐
      │              │              │
  one database   one database   mailserver
   per user      per workspace   mail routing
      │              │
      └─── common/ ──┘
     routines applied to every class
```

`templates/` holds the schema each new user and workspace database is built
from; `bin/build-seeds` and `bin/make-templates` maintain them. A pool of
pre-built databases is kept warm so signup does not wait on a `CREATE DATABASE`.

## Related repositories

| Repository | What it is |
|---|---|
| [server-team](https://github.com/drumee/server-team) | The back-end that calls these routines |
| [server-core](https://github.com/drumee/server-core) | Request lifecycle, sessions, ACL, meta filesystem |
| [setup-schemas](https://github.com/drumee/setup-schemas) | Bootstraps a fresh instance's database and seed data |
| [debian](https://github.com/drumee/debian) | Builds and deploys Drumee — container and Debian packages |
| [ui-team](https://github.com/drumee/ui-team) | The workspace front-end |

[Browse all repositories](https://github.com/orgs/drumee/repositories)

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

Patch everything listed in a manifest. With no argument it reads
`patches/manifest.txt`:

```console
bin/patch-from-manifest
bin/patch-from-manifest --manifest=/path/to/manifest.txt
```

Generate a manifest from the files that changed between two commits:

```console
bin/make-manifest <git_hash1> <git_hash2>
```

Rebuild the schema templates from a live installation. It picks an active
database of each class and dumps it into `factory/` (or the directory you name):

```console
bin/make-templates [factory-dir]
```

This rewrites files in this repository — see [Care](#care).

## Other tooling

| Script | What it does |
|---|---|
| `bin/compare-routines` | Diff routines between two databases |
| `bin/compare-tables-structure` | Diff table structures |
| `bin/scan-tables-structure` | Rewrites the table `.sql` files in this repo from a live database — **not** a read-only dump |
| `bin/lookup-errors` | Search log files for known MariaDB errors — `bin/lookup-errors <logfile>...` |
| `bin/build-seeds` | Build the seed databases |
| `bin/make-changelog` | Generate a changelog entry |
| `bin/update-manifest` | Regenerate `patches/manifest.txt` from `changelog.txt` for a date range |

## Care

These scripts write to live databases. A few things worth knowing before you
run one:

- Some files under `templates/` and the table definitions begin with
  `DROP TABLE`. **Read a table file before applying it** — applying one to a
  populated database will destroy its contents.
- **`common/` is a fleet apply.** A routine placed there goes to every database
  of every class, not to one — so it is not a `patch-from-file` job.
- **`bin/scan-tables-structure` and `bin/make-templates` rewrite files in this
  repository** from a live database. They are maintenance tools, not inspection
  tools; run them only when you mean to regenerate the checked-in SQL.
- A breaking change to a stored procedure should ship as a new version
  (`name_v2`) rather than a redefinition, so running instances keep working
  until the callers are updated.
- The filename must match the routine name inside it.

## Contributing

See the org [CONTRIBUTING guide](https://github.com/drumee/.github/blob/main/CONTRIBUTING.md).
Questions: [Discussions](https://github.com/orgs/drumee/discussions).

## License

AGPL-3.0 — see [LICENSE](LICENSE).
