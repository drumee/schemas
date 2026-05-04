# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Core Principle

**One routine per file.** Every `.sql` file must contain exactly one stored procedure, function, table definition, or trigger. No exceptions.

## Patching Commands

Apply a single SQL file to a database:
```bash
bin/patch-from-file <routine-file-path> <db_name|db_class>
```

Apply all files listed in a manifest:
```bash
bin/patch-from-manifest patches/
```

Generate a manifest from changed files between two git commits:
```bash
bin/make-manifest <git_hash1> <git_hash2>
```

Build a new schema template from an existing installation:
```bash
bin/make-templates <git_hash1> <git_hash2>
```

## Database Classes

The system manages 8 distinct database classes:

| Class | Directory | Purpose |
|-------|-----------|---------|
| `yellow_page` | `yellow_page/` | Main system database — central directory, auth, admin, contacts, OAuth |
| `hub` | `hub/` | Collaboration/workspace database — channels, files, sharing |
| `drumate` | `drumate/` | Per-user database — chat, contacts, desk, media, stats |
| `common` | `common/` | Schemas shared across hub and drumate instances — MFS (media file system), channels |
| `mailserver` | `mailserver/` | Email server backend |
| `utils` | `utils/` | Shared utility functions and UDFs (JSON helpers, path utilities) |
| `licence` | `licence/` | Licensing and entitlement management |
| `costums` | `costums/` | Customer-specific schema overrides (multi-tenant) |

The patching engine connects via MariaDB Unix socket at `/var/run/mysqld/mysqld.sock` using the current system user.

## Architecture

The `bin/patch.js` Node.js engine resolves the database target:
- For `yellow_page`/`yp`: applies to the single YP database
- For `hub`/`drumate`/`common`: discovers all matching database instances on the server and applies to each
- For a literal `db_name`: applies directly to that named database

**Manifest format** (`patches/manifest.txt`): one relative file path per line. Files listed are applied in order. The patches directory may also contain raw `.sql` migration files (e.g., `ALTER TABLE` statements) alongside the manifest.

## SQL File Conventions

**Stored procedures/functions:**
```sql
DELIMITER $

-- =========================================================
-- procedure_name
-- =========================================================
DROP PROCEDURE IF EXISTS `procedure_name`$
CREATE PROCEDURE `procedure_name`(
  IN _param1 TYPE,
  IN _param2 TYPE
)
BEGIN
  -- body
END $

DELIMITER ;
```

- Always `DROP ... IF EXISTS` before `CREATE` (idempotent)
- Input parameters prefixed with `_` (e.g., `_drumate_id`, `_key`)
- Internal variables also prefixed with `_` (e.g., `_res`, `_range`)

**Tables:** standard `CREATE TABLE` without `DROP` (tables are altered via patch files in `patches/`).

## Directory Layout

```
yellow_page/
  procedures/<feature>/   # admin, auth, contact, directory, domain, guest, mfs, ...
  tables/                 # ~34 table definitions
  functions/
  triggers/
hub/
  procedures/<feature>/   # channel, conference, media, share, ...
  tables/
drumate/
  procedures/<feature>/   # chat, contact, desk, media, stats, ...
  tables/
common/
  procedures/mfs/         # Core media file system (mfs_*) — used by both hub and drumate
  procedures/mfs-trash/
  tables/                 # channel, share_track, ...
patches/                  # Active manifest + migration SQL files
templates/factory/        # Seed SQL for initializing new instances (yp.sql, hub.sql, drumate.sql)
```
