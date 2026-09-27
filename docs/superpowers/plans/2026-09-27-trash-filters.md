# Trash Panel Filters Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add three filters to the Trash panel: **Latest deleted**, **Earliest deleted** and **Expiring soon** (5 days or less left to restore).

**Architecture:** The list is paged server-side (45 rows per page), so sorting and filtering must happen in SQL. A client-side sort would only reorder the page already loaded. A new procedure, `mfs_show_bin_next(_page, _sort)`, does the work. `mfs_show_bin(_page)` stays, reduced to a wrapper around `mfs_show_bin_next(_page, 'latest')`, because the stage endpoints (main/liam/huan) share one database server and older server builds still call the one-argument form. `media.show_bin` gets an optional `sort` param. The panel shows three chips; clicking one stores the value on the panel, stamps `data-filter` on its root and re-feeds the skeleton, which fetches again with the new `sort`.

**Tech Stack:** MariaDB 11.8 stored procedures (`schemas`), Node service + JSON ACL (`server-team`), Drumee ui-core widgets + SCSS (`ui-team`). Tests use `node --test` for JS and a bash harness on a disposable DB for SQL.

**Spec (verbatim from the request):**
> Add filters:
> - Latest deleted -> shows items from recently deleted to long deleted
> - Earliest deleted -> shows items from long ago deleted to recently deleted
> - Expiring soon -> Shows items that are about to expire (only 5 days left to restore)

## Background the engineer needs

The full flow is: panel `builtins/panel/trash/index.js` → `getCurrentApi()` → `media.show_bin` → `service/private/media.js:show_bin()` → `mfs_show_bin` on the user's drumate DB. That proc unions the user's own `trash_media` with the user's items in every hub where they have permission ≥ 15.

**The repo copy of `mfs_show_bin` is stale.** Stage runs three versions (checked 2026-09-27):

| md5 of body | instances | what it is |
|---|---|---|
| `52bcd3bc…` | 1509 | hand-applied, **not in git**. Adds `trashed_time`, `parent_path`, `hub_name`, `items_count` and `content_size`, orders by `trashed_time DESC, filename, nid`, and matches hub rows on `owner_id OR origin_id` |
| `cf3f0db4…` | 150 | older |
| `6e713de4…` | 18 | = repo `common/procedures/mfs-trash/mfs_show_bin.sql` |

The UI row skeleton already reads the extra columns from the 1509 version. **`mfs_show_bin_next` is built from that stage body**, which also brings the repo in line with what production actually runs. The stage body is copied verbatim into Task 1 below.

**Local box caveats:**
- No local `trash_media` has the `trashed_time` column (0 of 448).
- `yp.trash_expiry_config` does not exist locally.

So the current `mfs_show_bin` cannot run here. The SQL test therefore uses its own throwaway databases. Task 5 has the local provisioning needed for a click-test.

**Stage caveats:**
- 25 of 1677 stage instances lack `trashed_time`. The current proc already fails on them, and this plan neither fixes nor worsens that.
- Do not write to stage or prod DBs without an explicit ask. Task 5 hands the commands over rather than running them.

## Global Constraints

- One routine per `.sql` file; `DROP PROCEDURE IF EXISTS` before `CREATE`; params and locals prefixed `_` (schemas/CLAUDE.md).
- Filter values on the wire are exactly `latest`, `earliest`, `expiring`. Anything else, or a missing value, means `latest`.
- `latest` = `trashed_time` DESC. `earliest` = `trashed_time` ASC. `expiring` = rows with `days_remaining <= 5`, fewest days first, then oldest trash first.
- Legacy rows with `trashed_time = 0` (deletion time unknown) sort **last** in both `latest` and `earliest`. Their `days_remaining` is always the full expiry, so they only appear under `expiring` when the configured expiry is ≤ 5 days.
- Ties break on `filename` ASC, then `nid` ASC, so pages never overlap or skip rows.
- The 5-day threshold lives in one place in SQL (`_expiring_days`). The English hint repeats "5 days" in copy.
- Never change the arity of an existing proc: `mfs_show_bin(_page)` keeps its signature.
- Default filter when the panel opens: `latest`. The choice is kept while the panel instance lives (keep-alive slot) and is not persisted.
- Locale keys go into all six files: en, es, fr, km, ru, zh.

## Review Focus

1. **Empty "Expiring soon" result.** `data-empty=1` hides the status bar and footer. The filter chips must stay visible then, or the user cannot switch back. Pinned in Task 4 (CSS rule + manual check) and Task 3 (chips live outside the status bar).
2. **Legacy `trashed_time = 0` rows.** They must not jump to the top of "Earliest deleted". Pinned by row `L0` in the Task 1 harness.
3. **Unknown or missing `sort`** from an old UI or a hand-crafted call must behave exactly like today. Pinned in Task 1 (`bogus` value) and Task 2 (`showBinCall` tests).
4. **An old server calling `mfs_show_bin(page)` after the DB patch** must get the same rows and the same result shape. Pinned by the wrapper assertion in Task 1, plus the wrapper call through the real server in Task 5.
5. **Switching filters while a websocket echo reload is queued** must not run a second, stale fetch or leave the count wrong. Pinned in Task 4: `_setFilter` cancels the debounce, and the manual step deletes a file then switches filters within 600 ms.

---

### Task 1: SQL: `mfs_show_bin_next` + wrapper

**Files:**
- Create: `schemas/common/procedures/mfs-trash/mfs_show_bin_next.sql`
- Modify (full rewrite): `schemas/common/procedures/mfs-trash/mfs_show_bin.sql`
- Test: `schemas/tests/trash-show-bin-sort.sh`

**Interfaces:**
- Produces: `CALL mfs_show_bin_next(_page TINYINT, _sort VARCHAR(16))`. It returns the same columns as the stage `mfs_show_bin`, in this order: `nid, pid, parent_id, home_id, capability, owner_id, hub_id, status, filename, filesize, vhost, ext, ftype, filetype, mimetype, mtime, ctime, modifier_id, modifier_name, parent_exists, hub_exists, days_remaining, trashed_time, parent_path, hub_name, items_count, content_size`, then `page` (paged branch only) and `total_size`.
- Produces: `CALL mfs_show_bin(_page)`, which is equivalent to `mfs_show_bin_next(_page, 'latest')`.

- [ ] **Step 1: Write the failing test harness**

Create `schemas/tests/trash-show-bin-sort.sh`:

```bash
#!/usr/bin/env bash
# Exercises mfs_show_bin_next's three sorts and the mfs_show_bin wrapper
# against two throwaway databases (a user DB and one shared hub DB). The
# procs are loaded with yp.entity / yp.trash_expiry_config rewritten to
# tables inside the test DB, so nothing is written to yp. yp.filecap,
# yp.drumate and yp.vhost() are still read from the real yp.
#
#   tests/trash-show-bin-sort.sh trash_show_bin_test_1
set -euo pipefail

db=${1:?usage: trash-show-bin-sort.sh <disposable-db>}
case "$db" in
  trash_show_bin_test_*) ;;
  *) echo "refusing non-test database: $db" >&2; exit 2 ;;
esac
hub_db="${db}_hub"
root=$(cd "$(dirname "$0")/.." && pwd)
uid='tsbuser000000001'
hub='tsbhub0000000001'
other='tsbother00000001'

q() { mariadb --batch --skip-column-names "$1" -e "$2"; }

for d in "$db" "$hub_db"; do
  mariadb -e "DROP DATABASE IF EXISTS \`$d\`;
    CREATE DATABASE \`$d\` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci"
  mariadb "$d" < "$root/common/tables/media.sql"
  mariadb "$d" < "$root/common/tables/trash_media.sql"
done
mariadb "$db" < "$root/common/tables/permission.sql"
mariadb "$db" < "$root/common/procedures/utils/pageToLimits.sql"

q "$db" "CREATE TABLE entity (
    id VARCHAR(16) CHARACTER SET ascii, db_name VARCHAR(255),
    home_dir VARCHAR(512) DEFAULT '', home_id VARCHAR(16), status VARCHAR(16));
  INSERT INTO entity VALUES
    ('$uid', '$db', '/tmp/u', 'tsbuhome00000001', 'active'),
    ('$hub', '$hub_db', '/tmp/h', 'tsbhhome00000001', 'active');
  CREATE TABLE trash_expiry_config (expiry_days INT UNSIGNED NOT NULL);
  INSERT INTO trash_expiry_config VALUES (30);
  INSERT INTO media (id, parent_path, mimetype, category, status, user_filename)
    VALUES ('$hub', '', 'hub', 'hub', 'active', 'Shared');
  INSERT INTO permission (resource_id, entity_id, permission)
    VALUES ('$hub', '$uid', 31);"

load() {
  sed -e "s/yp\.entity/\`$db\`.entity/g" \
      -e "s/yp\.trash_expiry_config/\`$db\`.trash_expiry_config/g" \
      "$root/common/procedures/mfs-trash/$1" | mariadb "$db"
}
load mfs_show_bin_next.sql
load mfs_show_bin.sql

# row <db> <sys_id> <id> <name> <days-ago|legacy> <owner>
row() {
  local t="UNIX_TIMESTAMP(CURDATE() - INTERVAL $5 DAY + INTERVAL 12 HOUR)"
  [[ "$5" == legacy ]] && t=0
  q "$1" "INSERT INTO trash_media (sys_id, id, origin_id, owner_id,
      user_filename, parent_id, parent_path, mimetype, category, extension,
      status, trashed_time)
    VALUES ($2, '$3', '$6', '$6', '$4', 'gone000000000001', '/', 'text/plain',
      'document', 'txt', 'deleted', $t)"
}
# Personal drive: days left = 30 - days ago.
row "$db" 1 tsbA100000000001 A1   1  "$uid"   # 29 left
row "$db" 2 tsbA1b0000000001 A1b  1  "$uid"   # 29 left, same instant as A1
row "$db" 3 tsbD240000000001 D24  24 "$uid"   # 6 left: NOT expiring
row "$db" 4 tsbC250000000001 C25  25 "$uid"   # 5 left: expiring (boundary)
row "$db" 5 tsbB260000000001 B26  26 "$uid"   # 4 left
row "$db" 6 tsbL000000000001 L0   legacy "$uid" # unknown time
row "$db" 7 tsbT000000000001 __trash__ 26 "$uid" # never listed
# Shared hub: only the user's own items are listed.
row "$hub_db" 1 tsbH280000000001 H28 28 "$uid"   # 2 left
row "$hub_db" 2 tsbX270000000001 X27 27 "$other" # someone else's

# filename is column 9 of the result set.
names() { q "$db" "$1" | cut -f9 | paste -sd, -; }
fail=0
expect() {
  local got; got=$(names "$2")
  if [[ "$got" != "$3" ]]; then
    echo "FAIL $1: expected $3, got $got" >&2; fail=1
  fi
}

latest='A1,A1b,D24,C25,B26,H28,L0'
expect latest   "CALL mfs_show_bin_next(1, 'latest')"   "$latest"
expect earliest "CALL mfs_show_bin_next(1, 'earliest')" 'H28,B26,C25,D24,A1,A1b,L0'
expect expiring "CALL mfs_show_bin_next(1, 'expiring')" 'H28,B26,C25'
expect unknown  "CALL mfs_show_bin_next(1, 'bogus')"    "$latest"
expect null     "CALL mfs_show_bin_next(1, NULL)"       "$latest"
expect wrapper  "CALL mfs_show_bin(1)"                  "$latest"

days=$(q "$db" "CALL mfs_show_bin_next(1, 'expiring')" | cut -f22 | paste -sd, -)
[[ "$days" == '2,4,5' ]] || { echo "FAIL days_remaining: expected 2,4,5, got $days" >&2; fail=1; }

for d in "$db" "$hub_db"; do mariadb -e "DROP DATABASE \`$d\`"; done
[[ $fail == 0 ]] && echo 'trash show_bin sort tests: PASS' || exit 1
```

Run: `chmod +x tests/trash-show-bin-sort.sh`

- [ ] **Step 2: Run the harness and confirm it fails**

Run: `cd /home/drumee/schemas && tests/trash-show-bin-sort.sh trash_show_bin_test_1`

Expected: it exits non-zero. `mfs_show_bin_next.sql` does not exist yet, so the `sed` in `load` fails with "No such file". If a run aborts midway, drop the two `trash_show_bin_test_1*` databases by hand; the next run also recreates them.

- [ ] **Step 3: Create `mfs_show_bin_next.sql`**

The body is the stage `52bcd3bc…` body verbatim, except for these marked changes:
- the `_sort` param, its normalisation and `_expiring_days`;
- the `_uid` lookup now takes `LIMIT 1`;
- the two final `SELECT`s.

Write `schemas/common/procedures/mfs-trash/mfs_show_bin_next.sql`:

```sql
DELIMITER $

-- =========================================================
-- mfs_show_bin_next
-- Trash listing with a sort/filter. _sort:
--   'latest'   trashed_time DESC (default; also for NULL / unknown)
--   'earliest' trashed_time ASC
--   'expiring' only days_remaining <= _expiring_days, fewest first
-- Rows with trashed_time = 0 (deleted before the column existed, time
-- unknown) sort last in both directions. mfs_show_bin(_page) wraps this
-- with 'latest' for callers that predate the param.
-- =========================================================
DROP PROCEDURE IF EXISTS `mfs_show_bin_next`$
CREATE PROCEDURE `mfs_show_bin_next`(
  IN _page TINYINT(4),
  IN _sort VARCHAR(16) CHARACTER SET ascii
)
BEGIN
  DECLARE _hub_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _db_name VARCHAR(60) CHARACTER SET ascii;
  DECLARE _home_dir VARCHAR(300) CHARACTER SET ascii;
  DECLARE _home_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _uid VARCHAR(16) CHARACTER SET ascii;
  DECLARE _hub_name VARCHAR(128) CHARACTER SET utf8mb4;
  DECLARE _range BIGINT;
  DECLARE _offset BIGINT;
  DECLARE _expiry_days INT DEFAULT 30;
  DECLARE _expiring_days INT DEFAULT 5;

  IF _sort IS NULL OR _sort NOT IN ('latest', 'earliest', 'expiring') THEN
    SET _sort = 'latest';
  END IF;

  CALL pageToLimits(_page, _offset, _range);

  SELECT IFNULL(expiry_days, 30) INTO _expiry_days
    FROM yp.trash_expiry_config LIMIT 1;

  SET @_expiry_days = _expiry_days;

  SELECT id INTO _uid FROM yp.entity WHERE db_name = DATABASE() LIMIT 1;

  DROP TABLE IF EXISTS `_hubs`;
  CREATE TEMPORARY TABLE `_hubs` (
    hub_id VARCHAR(16) CHARACTER SET ascii DEFAULT NULL,
    db_name VARCHAR(60) CHARACTER SET ascii DEFAULT NULL,
    home_dir VARCHAR(300) CHARACTER SET ascii DEFAULT NULL,
    is_checked INT DEFAULT 0
  );

  DROP TABLE IF EXISTS _bin_media;
  CREATE TEMPORARY TABLE _bin_media AS
    SELECT
      m.id AS nid,
      m.parent_id AS pid,
      m.parent_id AS parent_id,
      _home_id AS home_id,
      ff.capability,
      me.id AS owner_id,
      me.id AS hub_id,
      m.status AS status,
      m.user_filename AS filename,
      m.filesize AS filesize,
      yp.vhost(me.id) AS vhost,
      m.extension AS ext,
      m.category AS ftype,
      m.category AS filetype,
      m.mimetype,
      m.upload_time AS mtime,
      m.publish_time AS ctime,
      m.origin_id AS modifier_id,
      IFNULL(CONCAT_WS(' ', d.firstname, d.lastname), 'System Admin') AS modifier_name,
      CASE WHEN EXISTS (
        SELECT 1 FROM media pm
        WHERE pm.id = m.parent_id AND pm.status = 'active'
      ) THEN 1 ELSE 0 END AS parent_exists,
      CASE WHEN me.status = 'active' THEN 1 ELSE 0 END AS hub_exists,
      GREATEST(0, _expiry_days - DATEDIFF(NOW(), FROM_UNIXTIME(IFNULL(NULLIF(m.trashed_time, 0), UNIX_TIMESTAMP()))))
                                                                        AS days_remaining,
      m.trashed_time AS trashed_time,
      m.parent_path AS parent_path,
      CAST(NULL AS CHAR(128) CHARACTER SET utf8mb4) AS hub_name,
      (SELECT COUNT(*) FROM trash_media c
        WHERE c.parent_id = m.id AND c.status <> 'deleted') AS items_count,
      CASE WHEN m.category = 'folder' THEN
        (SELECT IFNULL(SUM(c.filesize), 0) FROM trash_media c
          WHERE c.trashed_time = m.trashed_time AND c.status <> 'deleted'
            AND c.category <> 'folder'
            AND LEFT(c.file_path, CHAR_LENGTH(m.file_path) + 1) = CONCAT(m.file_path, '/'))
      ELSE m.filesize END AS content_size
    FROM trash_media m
      INNER JOIN yp.entity me ON me.db_name = DATABASE()
      LEFT JOIN yp.filecap ff ON m.extension = ff.extension
      LEFT JOIN yp.drumate d  ON m.origin_id = d.id
    WHERE m.status = 'deleted';

  INSERT INTO _hubs
  SELECT id, db_name, home_dir, 0
  FROM yp.entity
  WHERE id IN (
    SELECT id FROM media m
    INNER JOIN permission p
      ON p.resource_id = m.id AND p.permission >= 15 AND m.status = 'active'
  );

  SELECT hub_id, db_name, home_dir
    FROM _hubs WHERE is_checked = 0 LIMIT 1
    INTO _hub_id, _db_name, _home_dir;

  WHILE _hub_id IS NOT NULL DO

    SET _hub_name = NULL;
    SELECT user_filename FROM media WHERE id = _hub_id LIMIT 1 INTO _hub_name;

    SET @sql = CONCAT(
      "INSERT INTO _bin_media (",
        "nid, pid, parent_id, home_id, capability, owner_id, hub_id, ",
        "status, filename, filesize, vhost, ext, ftype, filetype, mimetype, ",
        "ctime, mtime, modifier_id, modifier_name, parent_exists, hub_exists, days_remaining, trashed_time, parent_path, hub_name, items_count, content_size) ",
      "SELECT ",
        "m.id AS nid, ",
        "m.parent_id AS pid, ",
        "m.parent_id AS parent_id, ",
        "me.home_id AS home_id, ",
        "ff.capability, ",
        "me.id AS owner_id, ",
        "me.id AS hub_id, ",
        "m.status AS status, ",
        "m.user_filename AS filename, ",
        "m.filesize AS filesize, ",
        "yp.vhost(me.id) AS vhost, ",
        "m.extension AS ext, ",
        "m.category AS ftype, ",
        "m.category AS filetype, ",
        "m.mimetype, ",
        "m.upload_time AS ctime, ",
        "m.publish_time AS mtime, ",
        "m.origin_id AS modifier_id, ",
        "IFNULL(CONCAT_WS(' ', d.firstname, d.lastname), 'System Admin') AS modifier_name, ",
        "CASE WHEN EXISTS (SELECT 1 FROM ", _db_name, ".media pm ",
          "WHERE pm.id = m.parent_id AND pm.status = 'active') THEN 1 ELSE 0 END AS parent_exists, ",
        "CASE WHEN me.status = 'active' THEN 1 ELSE 0 END AS hub_exists, ",
        "GREATEST(0, @_expiry_days - DATEDIFF(NOW(), FROM_UNIXTIME(IFNULL(NULLIF(m.trashed_time, 0), UNIX_TIMESTAMP())))) AS days_remaining, ",
        "m.trashed_time AS trashed_time, ",
        "m.parent_path AS parent_path, ",
        QUOTE(_hub_name), " AS hub_name, ",
        "(SELECT COUNT(*) FROM ", _db_name, ".trash_media c ",
          "WHERE c.parent_id = m.id AND c.status <> 'deleted') AS items_count, ",
        "CASE WHEN m.category = 'folder' THEN ",
          "(SELECT IFNULL(SUM(c.filesize), 0) FROM ", _db_name, ".trash_media c ",
            "WHERE c.trashed_time = m.trashed_time AND c.status <> 'deleted' ",
              "AND c.category <> 'folder' ",
              "AND LEFT(c.file_path, CHAR_LENGTH(m.file_path) + 1) = CONCAT(m.file_path, '/')) ",
        "ELSE m.filesize END AS content_size ",
      "FROM ", _db_name, ".trash_media m ",
        "INNER JOIN yp.entity me ON me.db_name = ", QUOTE(_db_name), " ",
        "LEFT JOIN yp.filecap ff ON m.extension = ff.extension ",
        "LEFT JOIN yp.drumate d  ON m.origin_id = d.id ",
      "WHERE m.status = 'deleted' ",
        "AND (m.owner_id = ", QUOTE(_uid), " OR m.origin_id = ", QUOTE(_uid), ")"
    );

    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    UPDATE _hubs SET is_checked = 1 WHERE hub_id = _hub_id;
    SELECT NULL, NULL, NULL INTO _hub_id, _db_name, _home_dir;
    SELECT hub_id, db_name, home_dir
      FROM _hubs WHERE is_checked = 0 LIMIT 1
      INTO _hub_id, _db_name, _home_dir;

  END WHILE;

  -- Total storage occupied by the whole bin (all pages, unfiltered)
  SELECT IFNULL(SUM(filesize), 0) INTO @_total_size
    FROM _bin_media WHERE filename != '__trash__';

  -- The same WHERE / ORDER BY in both branches. (trashed_time = 0) ASC puts
  -- legacy rows last whichever way trashed_time runs; filename, nid make the
  -- order total so pages neither overlap nor skip.
  IF _offset < 0 THEN
    SELECT *, @_total_size AS total_size
      FROM _bin_media
      WHERE filename != '__trash__'
        AND (_sort <> 'expiring' OR days_remaining <= _expiring_days)
      ORDER BY
        CASE WHEN _sort = 'expiring' THEN days_remaining END ASC,
        (trashed_time = 0) ASC,
        CASE WHEN _sort = 'latest' THEN trashed_time END DESC,
        CASE WHEN _sort <> 'latest' THEN trashed_time END ASC,
        filename, nid;
  ELSE
    SELECT *, _page AS page, @_total_size AS total_size
      FROM _bin_media
      WHERE filename != '__trash__'
        AND (_sort <> 'expiring' OR days_remaining <= _expiring_days)
      ORDER BY
        CASE WHEN _sort = 'expiring' THEN days_remaining END ASC,
        (trashed_time = 0) ASC,
        CASE WHEN _sort = 'latest' THEN trashed_time END DESC,
        CASE WHEN _sort <> 'latest' THEN trashed_time END ASC,
        filename, nid
      LIMIT _offset, _range;
  END IF;

  DROP TABLE IF EXISTS _bin_media;

END $

DELIMITER ;
```

- [ ] **Step 4: Rewrite `mfs_show_bin.sql` as the wrapper**

Replace the whole of `schemas/common/procedures/mfs-trash/mfs_show_bin.sql` with:

```sql
DELIMITER $

-- =========================================================
-- mfs_show_bin
-- Kept for callers that predate the sort param (stage endpoints share one
-- DB server, so an older server build may still call this). Same rows and
-- order as mfs_show_bin_next(_page, 'latest').
-- =========================================================
DROP PROCEDURE IF EXISTS `mfs_show_bin`$
CREATE PROCEDURE `mfs_show_bin`(
  IN _page TINYINT(4)
)
BEGIN
  CALL mfs_show_bin_next(_page, 'latest');
END $

DELIMITER ;
```

- [ ] **Step 5: Run the harness and confirm it passes**

Run: `cd /home/drumee/schemas && tests/trash-show-bin-sort.sh trash_show_bin_test_1`

Expected: `trash show_bin sort tests: PASS`.

If `yp.vhost` rejects the fake id, the failure names it. Replace `yp.vhost(me.id)` in the `sed` of `load` with `NULL`; do this only in the harness, never in the proc.

- [ ] **Step 6: Commit**

```bash
cd /home/drumee/schemas
git add common/procedures/mfs-trash/mfs_show_bin_next.sql common/procedures/mfs-trash/mfs_show_bin.sql tests/trash-show-bin-sort.sh
git commit -m "feat(mfs-trash): mfs_show_bin_next with latest/earliest/expiring sort

Built from the mfs_show_bin body running on 1509 stage instances (never
committed), so the repo now matches production. mfs_show_bin keeps its
one-arg signature as a wrapper for older server builds."
```

---

### Task 2: Server: `sort` param on `media.show_bin`

**Files:**
- Create: `server-team/service/lib/trash-sort.js`
- Modify: `server-team/service/private/media.js:2679-2686` (`show_bin`)
- Modify: `server-team/acl/media.json`, `show_bin.params`
- Test: `server-team/test/trash-sort.test.js`

**Interfaces:**
- Consumes: `mfs_show_bin(_page)` and `mfs_show_bin_next(_page, _sort)` from Task 1.
- Produces:
  - `SORTS = ['latest', 'earliest', 'expiring']`
  - `DEFAULT_SORT = 'latest'`
  - `trashSort(value) → string`
  - `showBinCall(page, sort) → [procName, ...args]`

- [ ] **Step 1: Write the failing test**

Create `server-team/test/trash-sort.test.js`:

```js
const assert = require('node:assert/strict');
const test = require('node:test');

const { SORTS, DEFAULT_SORT, trashSort, showBinCall } = require('../service/lib/trash-sort');

test('accepts the three sorts verbatim', () => {
  for (const s of ['latest', 'earliest', 'expiring']) assert.equal(trashSort(s), s);
});

test('anything else falls back to latest', () => {
  for (const s of [undefined, null, '', 'undefined', 'LATEST', 'oldest', 1, {}]) {
    assert.equal(trashSort(s), DEFAULT_SORT);
  }
});

test('latest keeps calling the one-arg proc, so an unpatched instance still answers', () => {
  assert.deepEqual(showBinCall(2, 'latest'), ['mfs_show_bin', 2]);
  assert.deepEqual(showBinCall(1, undefined), ['mfs_show_bin', 1]);
});

test('earliest / expiring call mfs_show_bin_next with the sort', () => {
  assert.deepEqual(showBinCall(1, 'earliest'), ['mfs_show_bin_next', 1, 'earliest']);
  assert.deepEqual(showBinCall(3, 'expiring'), ['mfs_show_bin_next', 3, 'expiring']);
});

test('acl/media.json show_bin.sort enum mirrors SORTS', () => {
  const { sort } = require('../acl/media.json').services.show_bin.params;
  assert.deepEqual(sort.enum, SORTS);
  assert.equal(sort.default, DEFAULT_SORT);
});
```

- [ ] **Step 2: Run it and confirm it fails**

Run: `cd /home/drumee/server-team && node --test test/trash-sort.test.js`

Expected: FAIL, `Cannot find module '../service/lib/trash-sort'`.

- [ ] **Step 3: Implement the lib**

Create `server-team/service/lib/trash-sort.js`:

```js
/**
 * media.show_bin `sort` values. Mirrors acl/media.json's enum and
 * mfs_show_bin_next's accepted _sort values.
 *
 * `latest` (the default, and the only order before the param existed) keeps
 * calling the one-arg mfs_show_bin: that name exists on every instance,
 * including any the mfs_show_bin_next patch has not reached yet.
 */
const SORTS = Object.freeze(['latest', 'earliest', 'expiring']);
const DEFAULT_SORT = 'latest';

function trashSort(value) {
  return SORTS.includes(value) ? value : DEFAULT_SORT;
}

function showBinCall(page, sort) {
  const s = trashSort(sort);
  return s === DEFAULT_SORT ? ['mfs_show_bin', page] : ['mfs_show_bin_next', page, s];
}

module.exports = { SORTS, DEFAULT_SORT, trashSort, showBinCall };
```

- [ ] **Step 4: Add the ACL param**

In `acl/media.json`, inside `show_bin.params`, add a `sort` entry after `page`:

```json
        "page": {
          "type": "number",
          "required": false,
          "default": 1,
          "min": 1,
          "doc": "Page number for pagination"
        },
        "sort": {
          "type": "string",
          "required": false,
          "default": "latest",
          "enum": ["latest", "earliest", "expiring"],
          "doc": "latest: most recently deleted first. earliest: oldest deletion first. expiring: only items with 5 days or less left before auto-purge, fewest days first."
        }
```

Validate: `node -e "require('./acl/media.json')"` prints nothing.

- [ ] **Step 5: Use it in the handler**

In `service/private/media.js`, add the require next to the other `../lib/` requires near the top:

```js
const { showBinCall } = require('../lib/trash-sort');
```

and replace the body of `show_bin()` (currently at line 2679):

```js
  show_bin() {
    // `let`, not `const`: the default below reassigns it. As a const this threw
    // "Assignment to constant variable" on every call that omitted `page` or
    // sent 0 — i.e. the default was unreachable, not merely unused.
    let page = this.input.get(Attr.page);
    if (page == null || page == undefined || page == 0) page = 1;
    const [proc, ...args] = showBinCall(page, this.input.get('sort'));
    this.db.call_proc(proc, ...args, this.output.list);
  }
```

- [ ] **Step 6: Run tests and confirm they pass**

Run: `cd /home/drumee/server-team && node --test test/trash-sort.test.js && node -e "require('./service/private/media.js')" 2>&1 | head -3`

Expected: all 5 tests pass. The require line may print environment errors from globals, but no `SyntaxError`.

- [ ] **Step 7: Commit**

```bash
cd /home/drumee/server-team
git add service/lib/trash-sort.js service/private/media.js acl/media.json test/trash-sort.test.js
git commit -m "feat(media): optional sort on show_bin (latest/earliest/expiring)"
```

---

### Task 3: UI: filter module, chips, placeholder and locale

**Files:**
- Create: `ui-team/src/drumee/builtins/panel/trash/filters.js`
- Create: `ui-team/src/drumee/builtins/panel/trash/skeleton/filters.js`
- Modify: `ui-team/src/drumee/builtins/panel/trash/skeleton/topbar.js`
- Modify: `ui-team/src/drumee/builtins/panel/trash/skeleton/placeholder.js`
- Modify: `ui-team/locale/{en,es,fr,km,ru,zh}.json`
- Test: `ui-team/tests/panel-trash-filters.test.js`

**Interfaces:**
- Consumes: the wire values from Task 2 (`latest|earliest|expiring`).
- Produces (`builtins/panel/trash/filters.js`):
  - `TRASH_FILTERS`
  - `DEFAULT_FILTER = "latest"`
  - `FILTER_LABELS` (value → LOCALE key)
  - `normalizeFilter(v) → string`
  - `showBinApi(filter, hub_id) → { service, page: 1, hub_id, sort }`
- Produces: chips carrying `service: "trash-filter"` and `name: <value>`, with classes `panel-trash__filter panel-trash__filter--<value>`, inside a `panel-trash__filters` row.
- Reads: the placeholder reads `ui._filter`, which Task 4 sets.
- Adds LOCALE keys: `TRASH_FILTER_LATEST`, `TRASH_FILTER_EARLIEST`, `TRASH_FILTER_EXPIRING`, `TRASH_EXPIRING_EMPTY_TITLE`, `TRASH_EXPIRING_EMPTY_HINT`.

- [ ] **Step 1: Write the failing test**

Create `ui-team/tests/panel-trash-filters.test.js`:

```js
// panel-trash-filters.test.js — the Trash panel's Latest / Earliest /
// Expiring soon filters: the value module, the chip row, where the row sits
// in the topbar, the per-filter empty state and the locale keys.
//
//   node --test tests/panel-trash-filters.test.js
const test = require("node:test");
const assert = require("node:assert/strict");
const path = require("node:path");

const DIR = path.join(__dirname, "..", "src/drumee/builtins/panel/trash");
const node = (type) => (opt = {}) => ({ type, ...opt });
global.Skeletons = {
  Box: { X: node("Box.X"), Y: node("Box.Y") },
  Note: node("Note"),
  Image: { Svg: node("Image.Svg") },
  Button: { Label: node("Button.Label"), Svg: node("Button.Svg") },
};
const en = require("../locale/en.json");
global.LOCALE = new Proxy(en, {
  get: (t, k) => (k === "format" ? undefined : k in t ? t[k] : k),
});
String.prototype.format = String.prototype.format || function () { return String(this); };
global.SERVICE = { media: { show_bin: "media.show_bin" } };
global.Desk = {};

const F = require(path.join(DIR, "filters"));
const P = "panel-trash";
const ui = (o = {}) => ({ fig: { family: P, group: "panel" }, _filter: "latest", ...o });
const walk = (n, out = []) => {
  if (Array.isArray(n)) { n.forEach((k) => walk(k, out)); return out; }
  if (!n || typeof n !== "object") return out;
  out.push(n);
  (n.kids || []).forEach((k) => walk(k, out));
  return out;
};
const has = (n, c) => String(n.className || "").split(/\s+/).includes(`${P}__${c}`);

test("the three filters, latest first and default", () => {
  assert.deepEqual([...F.TRASH_FILTERS], ["latest", "earliest", "expiring"]);
  assert.equal(F.DEFAULT_FILTER, "latest");
});

test("normalizeFilter keeps known values and defaults the rest", () => {
  for (const v of F.TRASH_FILTERS) assert.equal(F.normalizeFilter(v), v);
  for (const v of [undefined, null, "", "Latest", "oldest"]) {
    assert.equal(F.normalizeFilter(v), "latest");
  }
});

test("showBinApi sends the sort with the bin request", () => {
  assert.deepEqual(F.showBinApi("expiring", "u1"), {
    service: "media.show_bin", page: 1, hub_id: "u1", sort: "expiring",
  });
  assert.equal(F.showBinApi("junk", "u1").sort, "latest");
});

test("chip row: one chip per filter, wired to trash-filter", () => {
  const u = ui();
  const row = require(path.join(DIR, "skeleton/filters"))(u);
  assert.ok(has(row, "filters"));
  const chips = walk(row).filter((n) => has(n, "filter"));
  assert.deepEqual(chips.map((c) => c.name), ["latest", "earliest", "expiring"]);
  for (const c of chips) {
    assert.equal(c.service, "trash-filter");
    assert.equal(c.uiHandler, u);
    assert.ok(has(c, `filter--${c.name}`));
  }
  assert.deepEqual(chips.map((c) => c.content),
    [en.TRASH_FILTER_LATEST, en.TRASH_FILTER_EARLIEST, en.TRASH_FILTER_EXPIRING]);
});

test("chips sit in the topbar but OUTSIDE the status bar (hidden when empty)", () => {
  const top = require(path.join(DIR, "skeleton/topbar"))(ui());
  const filters = walk(top).find((n) => has(n, "filters"));
  assert.ok(filters, "topbar carries the filter row");
  const status = walk(top).find((n) => has(n, "status-bar"));
  assert.ok(!walk(status).some((n) => has(n, "filters")));
});

test("empty state names the filter when Expiring soon finds nothing", () => {
  const ph = require(path.join(DIR, "skeleton/placeholder"));
  const text = (u) => walk(ph(u)).filter((n) => n.type === "Note").map((n) => n.content);
  assert.ok(text(ui({ _filter: "expiring" })).includes(en.TRASH_EXPIRING_EMPTY_TITLE));
  assert.ok(text(ui({ _filter: "expiring" })).includes(en.TRASH_EXPIRING_EMPTY_HINT));
  for (const f of ["latest", "earliest"]) {
    assert.ok(text(ui({ _filter: f })).includes(en.NOTHING_IN_TRASH));
  }
});

const KEYS = ["TRASH_FILTER_LATEST", "TRASH_FILTER_EARLIEST", "TRASH_FILTER_EXPIRING",
  "TRASH_EXPIRING_EMPTY_TITLE", "TRASH_EXPIRING_EMPTY_HINT"];
for (const lang of ["en", "es", "fr", "km", "ru", "zh"]) {
  test(`${lang}.json carries the trash filter keys`, () => {
    const t = require(path.join(__dirname, "..", "locale", `${lang}.json`));
    for (const k of KEYS) {
      assert.equal(typeof t[k], "string", `${lang}: missing ${k}`);
      assert.ok(t[k].trim(), `${lang}: empty ${k}`);
    }
  });
}
```

- [ ] **Step 2: Run it and confirm it fails**

Run: `cd /home/drumee/ui-team && node --test tests/panel-trash-filters.test.js`

Expected: FAIL, `Cannot find module '.../panel/trash/filters'`.

- [ ] **Step 3: Create the filter module**

`ui-team/src/drumee/builtins/panel/trash/filters.js`:

```js
// Trash panel filters. The value goes to media.show_bin as `sort`; the
// server (service/lib/trash-sort) and mfs_show_bin_next accept the same three
// and read anything else as "latest", so an old server simply ignores it.
const TRASH_FILTERS = Object.freeze(["latest", "earliest", "expiring"]);
const DEFAULT_FILTER = "latest";
const FILTER_LABELS = Object.freeze({
  latest: "TRASH_FILTER_LATEST",
  earliest: "TRASH_FILTER_EARLIEST",
  expiring: "TRASH_FILTER_EXPIRING",
});

function normalizeFilter(value) {
  return TRASH_FILTERS.includes(value) ? value : DEFAULT_FILTER;
}

function showBinApi(filter, hub_id) {
  return {
    service: SERVICE.media.show_bin,
    page: 1,
    hub_id,
    sort: normalizeFilter(filter),
  };
}

module.exports = { TRASH_FILTERS, DEFAULT_FILTER, FILTER_LABELS, normalizeFilter, showBinApi };
```

- [ ] **Step 4: Create the chip row**

`ui-team/src/drumee/builtins/panel/trash/skeleton/filters.js`:

```js
const { TRASH_FILTERS, FILTER_LABELS } = require("../filters");

// Latest / Earliest / Expiring soon. The active chip is not stamped here: the
// panel root carries data-filter and the skin lights the matching
// __filter--<value>, so a switch needs no per-chip state.
module.exports = function (ui) {
  const pfx = ui.fig.family;
  return Skeletons.Box.X({
    className: `${pfx}__filters`,
    debug: __filename,
    kids: TRASH_FILTERS.map((f) => Skeletons.Note({
      className: `${pfx}__filter ${pfx}__filter--${f}`,
      content: LOCALE[FILTER_LABELS[f]],
      service: "trash-filter",
      name: f,
      uiHandler: ui,
    })),
  });
};
```

- [ ] **Step 5: Put the row in the topbar**

In `skeleton/topbar.js`, change the final return so the row sits between the header and the status bar:

```js
  return Skeletons.Box.Y({
    className: `${pfx}__topbar`,
    debug: __filename,
    // The filter row stays OUT of the status bar: data-empty=1 hides that bar,
    // and an empty "Expiring soon" result must still offer the way back.
    kids: [header, require("./filters")(ui), statusBar],
  });
```

- [ ] **Step 6: Make the empty state filter-aware**

In `skeleton/placeholder.js`, add a line at the top of the function, after `const pfx = ui.fig.family;`:

```js
  // "Nothing in trash" is wrong when only the Expiring soon filter is empty.
  const expiring = ui._filter === "expiring";
```

and change the title and hint notes to:

```js
      Skeletons.Note({
        className: `${pfx}__placeholder-title`,
        content: expiring ? LOCALE.TRASH_EXPIRING_EMPTY_TITLE : LOCALE.NOTHING_IN_TRASH,
      }),
      Skeletons.Note({
        className: `${pfx}__placeholder-hint`,
        content: expiring ? LOCALE.TRASH_EXPIRING_EMPTY_HINT : LOCALE.TRASH_EMPTY_HINT,
      }),
```

- [ ] **Step 7: Add the locale keys**

Insert them right after `TRASH_EMPTY_HINT` in every file. All six files survive a `JSON.parse` / `JSON.stringify(…, null, 2)` round trip unchanged (checked 2026-09-27), so this script is safe:

```bash
cd /home/drumee/ui-team && node - <<'EOF'
const fs = require("fs");
const add = {
  en: ["Latest deleted", "Earliest deleted", "Expiring soon", "Nothing expiring soon",
       "No item in the trash has 5 days or less left to restore."],
  fr: ["Supprimés récemment", "Supprimés il y a longtemps", "Expire bientôt", "Rien n'expire bientôt",
       "Aucun élément de la corbeille n'a 5 jours ou moins pour être restauré."],
  es: ["Eliminados recientemente", "Eliminados hace más tiempo", "Caducan pronto", "Nada caduca pronto",
       "Ningún elemento de la papelera tiene 5 días o menos para restaurarse."],
  ru: ["Недавно удалённые", "Давно удалённые", "Скоро истекают", "Ничего не истекает в ближайшее время",
       "В корзине нет объектов, срок восстановления которых истекает через 5 дней или раньше."],
  zh: ["最近删除", "最早删除", "即将过期", "没有即将过期的项目",
       "回收站中没有剩余恢复时间不超过 5 天的项目。"],
  km: ["បានលុបថ្មីៗ", "បានលុបយូរជាងគេ", "ជិតផុតកំណត់", "គ្មានអ្វីជិតផុតកំណត់ទេ",
       "គ្មានធាតុណាមួយក្នុងធុងសំរាមដែលនៅសល់ ៥ ថ្ងៃ ឬតិចជាងនេះសម្រាប់ស្ដារឡើងវិញទេ។"],
};
const KEYS = ["TRASH_FILTER_LATEST", "TRASH_FILTER_EARLIEST", "TRASH_FILTER_EXPIRING",
  "TRASH_EXPIRING_EMPTY_TITLE", "TRASH_EXPIRING_EMPTY_HINT"];
for (const [lang, vals] of Object.entries(add)) {
  const file = `locale/${lang}.json`;
  const src = JSON.parse(fs.readFileSync(file, "utf8"));
  const out = {};
  for (const [k, v] of Object.entries(src)) {
    if (KEYS.includes(k)) continue;           // re-runnable
    out[k] = v;
    if (k === "TRASH_EMPTY_HINT") KEYS.forEach((key, i) => (out[key] = vals[i]));
  }
  fs.writeFileSync(file, JSON.stringify(out, null, 2) + "\n");
}
EOF
git diff --stat locale/
```

Expected: each of the six files shows `5 insertions(+)` and no deletions.

- [ ] **Step 8: Run tests and confirm they pass**

Run: `cd /home/drumee/ui-team && node --test tests/panel-trash-filters.test.js`

Expected: all tests pass (6 behaviour tests + 6 locale tests).

- [ ] **Step 9: Commit**

```bash
cd /home/drumee/ui-team
git add src/drumee/builtins/panel/trash/filters.js src/drumee/builtins/panel/trash/skeleton/filters.js \
  src/drumee/builtins/panel/trash/skeleton/topbar.js src/drumee/builtins/panel/trash/skeleton/placeholder.js \
  locale/*.json tests/panel-trash-filters.test.js
git commit -m "feat(trash): Latest / Earliest / Expiring soon filter chips"
```

---

### Task 4: UI: wire the panel and style the chips

**Files:**
- Modify: `ui-team/src/drumee/builtins/panel/trash/index.js` (`initialize`, `getCurrentApi`, new `_setFilter`, `onUiEvent`)
- Modify: `ui-team/src/drumee/builtins/panel/trash/skin/index.scss`

**Interfaces:**
- Consumes: `DEFAULT_FILTER`, `normalizeFilter` and `showBinApi` from Task 3, plus the `trash-filter` chip service.
- Produces: `this._filter` on the panel, and `data-filter="<value>"` on the panel root.

- [ ] **Step 1: Wire `index.js`**

Add the require under the existing requires at the top:

```js
const { DEFAULT_FILTER, normalizeFilter, showBinApi } = require("./filters");
```

In `initialize`, stamp the default filter together with `anim`, and set the field:

```js
  initialize(opt = {}) {
    opt.dataset = { ...opt.dataset, anim: "out", filter: DEFAULT_FILTER };
    super.initialize(opt);
    // Latest / Earliest / Expiring soon (skeleton/filters). Kept for the life
    // of the panel instance, so a keep-alive re-show reopens on the same one.
    this._filter = DEFAULT_FILTER;
```

(The rest of `initialize` is unchanged.)

Replace `getCurrentApi`:

```js
  getCurrentApi() {
    return showBinApi(this._filter, Visitor.id);
  }
```

Add `_setFilter` directly after `getCurrentApi`:

```js
  /**
   * Switch the bin order / filter. Re-feeds the panel like `refresh` does
   * rather than restart()ing the list: the empty state is built with the
   * filter in hand (Expiring soon has its own wording), and restart() would
   * put the old placeholder back.
   */
  _setFilter(value) {
    const filter = normalizeFilter(value);
    if (filter === this._filter) return;
    this._filter = filter;
    if (this.el) this.el.dataset.filter = filter;
    // The feed below fetches with the new sort; an echo reload still queued
    // (or held for later) would fetch the same list a second time.
    if (this._wsRefresh.cancel) this._wsRefresh.cancel();
    this._pendingWsRefresh = false;
    this._staleWhileParked = false;
    this.feed(require('./skeleton')(this));
  }
```

In `onUiEvent`, add a case before `case 'refresh':`:

```js
      case 'trash-filter':
        return this._setFilter(cmd.mget(_a.name));
```

- [ ] **Step 2: Style the chips**

In `skin/index.scss`:

1. Hide the filter row only when the bin is truly empty. Extend the existing `&__ui[data-empty="1"]` block so it reads:

```scss
  &__ui[data-empty="1"] {

    .panel-trash__status-bar,
    .panel-trash__footer {
      display: none;
    }

    // Latest / Earliest are the whole bin, so empty there means empty. An
    // empty Expiring soon only means nothing expires yet: keep the chips so
    // the user can switch back.
    &:not([data-filter="expiring"]) .panel-trash__filters {
      display: none;
    }
  }
```

2. Add the row and chip styles directly after the `&__topbar { … }` block:

```scss
  /* ── Filters: Latest / Earliest / Expiring soon ─────────── */
  &__filters {
    flex-shrink: 0;
    flex-wrap: wrap;
    gap: 8px;
    padding: 12px 24px 0;
  }

  &__filter {
    @include drumee.typo($color: var(--normal-fg-50),
      $size: 10px,
      $weight: 600,
      $line: 1);
    font-family: var(--font-mono, var(--font-medium));
    text-transform: uppercase;
    letter-spacing: 0.4px;
    cursor: pointer;
    padding: 6px 12px;
    border-radius: 999px;
    border: 1px solid var(--border-muted);
    transition: color 0.15s, border-color 0.15s, background-color 0.15s;

    &:hover {
      color: var(--normal-fg-30);
      border-color: var(--border-default);
    }
  }

  // The panel root carries data-filter; light the matching chip.
  &__ui[data-filter="latest"] .panel-trash__filter--latest,
  &__ui[data-filter="earliest"] .panel-trash__filter--earliest,
  &__ui[data-filter="expiring"] .panel-trash__filter--expiring {
    color: var(--active-border);
    border-color: var(--active-border);
    background-color: var(--normal-fg-10);
  }
```

- [ ] **Step 3: Compile check**

Run: `cd /home/drumee/ui-team && node_modules/.bin/sass --no-source-map --load-path=src/drumee/skin src/drumee/builtins/panel/trash/skin/index.scss | grep -c "panel-trash__filter"`

Expected: a number ≥ 4 and no sass error.

- [ ] **Step 4: Re-run the unit tests**

Run: `cd /home/drumee/ui-team && node --test tests/panel-trash-filters.test.js tests/items-ready.test.js`

Expected: all pass.

- [ ] **Step 5: Commit**

```bash
cd /home/drumee/ui-team
git add src/drumee/builtins/panel/trash/index.js src/drumee/builtins/panel/trash/skin/index.scss
git commit -m "feat(trash): switch bin order from the filter chips"
```

---

### Task 5: Patch, click-test, hand over stage

**Files:** none changed. This task runs commands and checks behaviour.

- [ ] **Step 1: Provision the local test account (local box only)**

Local lacks what the current proc already needs. Find your login's DB (`yp.entity.db_name`; it is not derivable from the account id), then:

```bash
cd /home/drumee/schemas
mariadb yp -e "SHOW TABLES LIKE 'trash_expiry_config'"   # expect empty; if not, skip the next line
mariadb yp < yellow_page/tables/trash_expiry_config.sql
DB=$(mariadb -N -e "SELECT db_name FROM yp.entity WHERE ident='<your-local-ident>'")
mariadb "$DB" -e "ALTER TABLE trash_media
  ADD COLUMN IF NOT EXISTS trashed_time INT(11) UNSIGNED NOT NULL DEFAULT 0 AFTER upload_time,
  ADD KEY IF NOT EXISTS idx_trashed_time (trashed_time)"
```

- [ ] **Step 2: Patch the procs locally**

```bash
cd /home/drumee/schemas
bin/patch-from-file common/procedures/mfs-trash/mfs_show_bin_next.sql common
bin/patch-from-file common/procedures/mfs-trash/mfs_show_bin.sql common
mariadb -N -e "SELECT COUNT(*) FROM information_schema.routines WHERE routine_name='mfs_show_bin_next'"
mariadb -N -e "SELECT COUNT(*) FROM information_schema.routines WHERE routine_name='mfs_show_bin'"
```

Expected: the two counts are equal (every instance got both). Order matters: the wrapper calls `mfs_show_bin_next`, so patch that first.

- [ ] **Step 3: Seed trash rows with known ages in `$DB`**

Trash three files through the UI. Then back-date two of them so all three filters have something to show:

```bash
mariadb "$DB" -e "SELECT id, user_filename, trashed_time FROM trash_media WHERE status='deleted' ORDER BY sys_id DESC LIMIT 3"
# pick two ids from the output:
mariadb "$DB" -e "UPDATE trash_media SET trashed_time = UNIX_TIMESTAMP() - 27*86400 WHERE id='<id1>';
                  UPDATE trash_media SET trashed_time = UNIX_TIMESTAMP() - 10*86400 WHERE id='<id2>'"
```

- [ ] **Step 4: Deploy server + UI locally and click-test**

Deploy the running server copy at `/srv/drumee/runtime`, not the checkout. Deploy the UI bundle, then do a **full page reload**, since an open SPA tab keeps the old build. Open Trash:

1. Latest deleted is lit. Order is: fresh file, 10-day file, 27-day file.
2. Earliest deleted gives the reverse order. The count is unchanged.
3. Expiring soon shows only the 27-day file, with a "3 days left" badge.
4. Restore that file while on Expiring soon. The empty state reads "Nothing expiring soon" and the chips are **still visible**. Click Latest deleted and the full list is back.
5. Delete a file from Files, then within 600 ms click Earliest deleted. DevTools → Network shows a single `media.show_bin` with `sort=earliest` and no trailing second request.
6. Old caller check: on the patched instance, `curl` or DevTools `media.show_bin` **without** `sort` returns the same rows as Latest deleted. This is the wrapper path through the real server driver.
7. Mobile width (≤ 1024px, and phone): the chips wrap and do not overflow the 360px card.

- [ ] **Step 5: Hand the stage commands to the user (do not run)**

Stage writes need an explicit ask, and `patch-from-file` against hub targets has side effects there. Give the user this loop, which patches exactly the instances that already have `mfs_show_bin`:

```bash
# on stage, from the schemas checkout at the merged commit
for f in mfs_show_bin_next mfs_show_bin; do
  mysql -N -e "SELECT DISTINCT routine_schema FROM information_schema.routines WHERE routine_name='mfs_show_bin'" |
  while read -r db; do mysql "$db" < common/procedures/mfs-trash/$f.sql || echo "FAILED $f $db"; done
done
mysql -N -e "SELECT routine_name, md5(routine_definition), COUNT(*) FROM information_schema.routines
  WHERE routine_name IN ('mfs_show_bin','mfs_show_bin_next') GROUP BY 1,2"
```

Expected afterwards: one md5 per routine name, with equal counts. **Rollout order:** schemas first, then server, then UI. The UI already sends `sort`, which an old server ignores. A new server calls `mfs_show_bin_next` only for earliest/expiring. The 25 stage instances without `trashed_time` stay broken exactly as they are today; list them with the query from the Background section if the user wants a follow-up.

---

## Out of scope (noted while tracing, not changed here)

- `mfs_empty_trash` purges every row of `trash_media` in shared hubs, not just the user's own, while `show_bin` only lists the user's.
- `mfs_show_bin` swaps `ctime`/`mtime` between personal and hub rows; `_home_id` is never set.
- "Empty Trash" still empties the whole bin whichever filter is active.
