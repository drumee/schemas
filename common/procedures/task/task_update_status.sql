DELIMITER $
DROP PROCEDURE IF EXISTS `task_update_status`$
CREATE PROCEDURE `task_update_status`(
  IN _id VARCHAR(16),
  IN _status VARCHAR(20)
)
BEGIN
  DECLARE _rank INT DEFAULT 0;
  -- CHARACTER SET ascii to match task.nid / task_column.nid: without it the
  -- variable takes the database default (utf8mb4) and comparing it against the
  -- ascii column raises ER_CANT_AGGREGATE_2COLLATIONS (1267).
  DECLARE _nid VARCHAR(16) CHARACTER SET ascii DEFAULT NULL;
  DECLARE _done TINYINT DEFAULT 0;

  -- Resolve the task's folder so the destination-column rank is computed
  -- within the same folder, not across the whole hub.
  SELECT nid INTO _nid FROM task WHERE id = _id;

  -- Is the destination a "done" column? Completion is driven by the column's
  -- is_done flag, not the literal 'complete' key — so a renamed or
  -- user-created done column still stamps completed_at correctly.
  --
  -- Scoped to the task's own folder: built-in ids are literal status keys that
  -- exist once PER SCOPE, so an unscoped lookup reads another board's flag.
  -- task_column.nid uses '' for root (primary-key column, cannot be NULL)
  -- while task.nid keeps NULL, hence IFNULL on both sides — which also keeps
  -- this correct before AND after alter_task_column_scope_pk.
  SELECT COALESCE(MAX(is_done), 0) INTO _done
    FROM task_column
   WHERE id = _status
     AND IFNULL(nid, '') = IFNULL(_nid, '');

  -- Place task at the bottom of the destination (folder, status) column.
  SELECT IFNULL(MAX(rank), 0) + 1
    INTO _rank
    FROM task
   WHERE status = _status
     AND nid <=> _nid
     AND id <> _id;

  -- Stamp completed_at when entering a done column; clear it when leaving.
  -- A re-complete refreshes the timestamp so cycle-time reflects the latest pass.
  UPDATE task
     SET status = _status,
         rank   = _rank,
         mtime  = UNIX_TIMESTAMP(),
         completed_at = IF(_done = 1, UNIX_TIMESTAMP(), 0)
   WHERE id = _id;

  SELECT
    t.id, t.title, t.description, t.status, t.priority, t.due_date, t.start_date,
    t.created_by,
    -- Reporter: the editable "reported by" uid. COALESCE so a row predating
    -- alter_task_add_reporter.sql (reporter_uid NULL) answers with its creator —
    -- the client never has to know the column was backfilled.
    COALESCE(t.reporter_uid, t.created_by) AS reporter_uid,
    t.nid, t.parent_task_id, t.rank, t.ctime, t.mtime, t.completed_at,
    GROUP_CONCAT(DISTINCT tl.label_id) AS label_ids,
    (SELECT GROUP_CONCAT(ta.uid) FROM task_assignee ta WHERE ta.task_id = t.id) AS assignee_uids,
    -- Subtask rollup counters — see task_create for the rationale.
    (SELECT COUNT(*) FROM task s WHERE s.parent_task_id = t.id) AS subtask_total,
    (SELECT COUNT(*)
       FROM task s
       JOIN task_column c
         ON c.id = CONVERT(s.status USING ascii)
        AND IFNULL(c.nid, '') = IFNULL(s.nid, '')
      WHERE s.parent_task_id = t.id
        AND c.is_done = 1) AS subtask_done
  FROM task t
  LEFT JOIN task_label tl ON tl.task_id = t.id
  WHERE t.id = _id
  GROUP BY t.id;
END$
DELIMITER ;
