-- ALTER TABLE migration — existing hub / drumate databases
-- Kanban manual-order support: task.rank, the per-(folder, column) position
-- read and written by the 2026-07-08 task procs (task_create / task_list /
-- task_update / task_update_status / task_set_assignees).
--
-- Those procs shipped through the manifest to EVERY hub, but the column only
-- existed on freshly-created hubs (factory template) — common/tables/task.sql
-- is CREATE TABLE IF NOT EXISTS, a no-op on hubs whose task table predates it.
-- On such hubs CALL task_create failed with "Unknown column 'rank'" (the DB
-- layer swallows the error), so new tasks were silently never saved while new
-- workspaces worked. Safe to run multiple times (MariaDB 10.3+).
--
-- Apply to every common-class DB individually, e.g.:
--   bin/patch-from-file common/patches/alter_task_add_rank.sql common

ALTER TABLE `task`
  ADD COLUMN IF NOT EXISTS `rank` INT(11) NOT NULL DEFAULT 0 AFTER `nid`;

-- Backfill: give pre-existing tasks a stable per-(folder, column) rank that
-- matches the legacy display order (creation time), so existing boards keep
-- their ordering instead of every task sharing rank 0. Only touches rank = 0
-- rows, so re-runs and already-ranked tasks are unaffected.
UPDATE task t
  JOIN (
    SELECT id,
           ROW_NUMBER() OVER (PARTITION BY nid, status ORDER BY ctime, id) AS rn
      FROM task
  ) r ON r.id = t.id
   SET t.`rank` = r.rn
 WHERE t.`rank` = 0;
