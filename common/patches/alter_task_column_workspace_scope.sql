-- ALTER TABLE migration — existing hub / drumate databases
-- Collapse task_column from FOLDER scope back to ONE SET PER WORKSPACE.
--
-- Why: the product model changed. Tasks, chat and meetings are workspace-level
-- now (Figma 43:23955 makes Files / Chat / Task / Meet workspace rail items),
-- so a board is the WORKSPACE'S board and must show every task in the workspace
-- under one set of columns. While columns stayed folder-scoped, a task created
-- in a subfolder carried a status matching no column at the root, so a
-- workspace-wide board could not render it at all.
--
-- This deliberately reverses alter_task_column_scope_pk, which made columns
-- folder-scoped. That patch was correct for the folder-scoped model; the model
-- is what changed. The (id, nid) PRIMARY KEY is LEFT IN PLACE — nothing needs
-- it dropped once every row sits at nid = '', and keeping it avoids a second
-- destructive DDL on live databases.
--
-- Scope key: '' is the workspace root, matching task_column_init.scope_key and
-- what every task_column proc now hard-codes.
--
-- MERGE RULE — "root wins" (product owner's decision):
--   * custom columns (generated 16-char ids, unique within the database) move
--     to '' intact and keep their tasks;
--   * the four BUILT-INS (todo / in_progress / to_review / complete) exist once
--     PER FOLDER, so they collide on (id, ''). The ROOT row survives and the
--     per-folder duplicates are dropped. Their tasks need no repointing:
--     task.status holds the built-in KEY ITSELF ('todo'), identical in every
--     scope, so those tasks land on the surviving root row automatically.
--     A rename / recolour / reorder applied to a built-in INSIDE a subfolder is
--     lost — the accepted cost of the merge.
--
-- task.nid is NOT touched: a task keeps the folder it was created in as
-- provenance (task_list still returns it, and task_list_range reports it to the
-- Personal Calendar). That column simply stops deciding which column set
-- applies.
--
-- Every step is guarded and safe to run repeatedly.

-- 1. When the root has NO columns at all — a workspace whose board was only
--    ever opened inside a subfolder — decide WHICH folder's copy of the four
--    built-ins wins, before step 2 starts merging.
--
--    Step 2 alone would still populate the root (nothing collides with an empty
--    scope), but the winner would be whichever row the engine happened to read
--    first: a rename or recolour would survive or vanish at random, differently
--    on every database. Seeding from MIN(nid) first makes the outcome
--    deterministic and reproducible.
--
--    Ordering note: every destructive step below runs only AFTER the rows it
--    removes have been copied, so an interrupted run (the CLI stops the file at
--    the first error) can lose nothing — it can only leave the merge half done,
--    and re-running finishes it.
INSERT IGNORE INTO task_column (id, nid, name, theme, position, is_done, ctime, mtime)
SELECT c.id, '', c.name, c.theme, c.position, c.is_done, c.ctime, c.mtime
  FROM task_column c
  JOIN (SELECT MIN(nid) AS src FROM task_column WHERE nid <> '') pick
    ON pick.src = c.nid
 WHERE NOT EXISTS (SELECT 1 FROM task_column r WHERE r.nid = '');

-- 2. Move every remaining non-root column to the root scope. INSERT IGNORE
--    keeps the existing root row on a collision — that IS the "root wins" rule:
--    the four built-ins already exist at '' so their duplicates are discarded
--    here, while custom ids are unique and therefore always land.
INSERT IGNORE INTO task_column (id, nid, name, theme, position, is_done, ctime, mtime)
SELECT id, '', name, theme, position, is_done, ctime, mtime
  FROM task_column
 WHERE nid <> '';

-- 3. Drop what has now been merged. Every surviving column lives at ''.
DELETE FROM task_column WHERE nid <> '';

-- 4. Re-space positions so the merged set has a stable, gap-free order.
--    Built-ins keep their canonical order; custom columns follow.
SET @pos := 0;
UPDATE task_column
   SET position = (@pos := @pos + 1)
 WHERE nid = ''
 ORDER BY
   CASE id
     WHEN 'todo' THEN 0
     WHEN 'in_progress' THEN 1
     WHEN 'to_review' THEN 2
     WHEN 'complete' THEN 3
     ELSE 4
   END,
   position,
   id;

-- 5. Per-scope seed markers. task_column_list records that a scope has been
--    seeded so it never re-seeds; folder markers are meaningless now, and
--    leaving them would block the root from being re-seeded if it were ever
--    emptied.
DELETE FROM task_column_init WHERE scope_key <> '';

-- 6. Record the root scope as seeded, if it now holds columns and was not
--    already marked. task_column_list only auto-seeds the four built-ins for a
--    scope with no task_column_init row, and it seeds by first doing
--    `UPDATE task_column SET position = position + 4`. A workspace whose board
--    only ever existed inside a subfolder ends this patch with columns at ''
--    and NO marker — so the next board open would shove every column we just
--    merged four places to the right and then INSERT IGNORE the built-ins that
--    are already there, scrambling the order for no reason. The marker says
--    what is already true: this scope is seeded.
--
--    The guard tests for a BUILT-IN at the root, not merely for any column.
--    "Seeded" means task_column_list has planted todo / in_progress /
--    to_review / complete here; a scope holding only user-created columns has
--    never been seeded, whatever else it contains. Marking such a scope claims
--    a seeding that never happened, and because the marker is permanent the
--    built-ins can then never arrive — stranding every task whose status is a
--    built-in key on a board with no column to put it in.
--
--    Any one built-in is enough: a user who deleted 'to_review' from a properly
--    seeded board must keep it deleted, so the marker has to survive a partial
--    set. Only a root with NONE of them was never seeded.
INSERT IGNORE INTO task_column_init (scope_key, ctime)
SELECT '', UNIX_TIMESTAMP()
  FROM DUAL
 WHERE EXISTS (
   SELECT 1 FROM task_column
    WHERE nid = ''
      AND id IN ('todo', 'in_progress', 'to_review', 'complete')
 );

--    Self-heal. An earlier revision of this patch guarded on "any column at
--    root", which marked never-seeded scopes that held only custom columns.
--    Remove such a marker so the next board open seeds the built-ins as it
--    always would have. Safe on a correctly-marked scope: the EXISTS below is
--    the exact negation of the INSERT above, so a scope that deserves its
--    marker keeps it.
DELETE FROM task_column_init
 WHERE scope_key = ''
   AND NOT EXISTS (
     SELECT 1 FROM task_column
      WHERE nid = ''
        AND id IN ('todo', 'in_progress', 'to_review', 'complete')
   );

-- 7. Column WATCHES follow their columns. task_column_watch is keyed
--    (uid, nid, column_key) with '0' as its root sentinel, and every watch proc
--    now hard-codes that key. A bell switched on inside a subfolder would
--    otherwise read as off on the workspace board — and, worse, still fire
--    notifications nobody can see a bell for. INSERT IGNORE collapses the
--    duplicates a user accumulated across folders onto the single row.
INSERT IGNORE INTO task_column_watch (uid, nid, column_key, ctime)
SELECT uid, '0', column_key, ctime
  FROM task_column_watch
 WHERE nid <> '0';

DELETE FROM task_column_watch WHERE nid <> '0';
