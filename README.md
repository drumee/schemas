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
