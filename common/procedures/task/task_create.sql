DELIMITER $
DROP PROCEDURE IF EXISTS `task_create`$
CREATE PROCEDURE `task_create`(
  IN _id VARCHAR(16),
  IN _title VARCHAR(500),
  IN _description TEXT,
  IN _status VARCHAR(20),
  IN _priority VARCHAR(20),
  IN _due_date DATE,
  IN _start_date DATE,
  IN _created_by VARCHAR(16),
  -- Reporter. NULL = "the creator", which is the overwhelming case; the create
  -- modal only sends a uid when the user picked somebody else. created_by is
  -- always the real creator regardless, so provenance survives either way.
  IN _reporter_uid VARCHAR(16),
  IN _nid VARCHAR(16),
  -- Subtask link. NULL = normal top-level task. The caller (task.create) has
  -- already verified the parent exists and is not itself a subtask, and passes
  -- the PARENT's nid as _nid so both rows share a board.
  IN _parent_task_id VARCHAR(16)
)
BEGIN
  DECLARE _rank INT DEFAULT 0;
  DECLARE _now INT DEFAULT UNIX_TIMESTAMP();

  -- rank = max rank in the same (folder, status) column + 1 (bottom of column).
  -- Scoped by nid (null-safe) so each folder's columns rank independently.
  SELECT IFNULL(MAX(rank), 0) + 1
    INTO _rank
    FROM task
   WHERE status = _status
     AND nid <=> _nid;

  INSERT INTO task (
    id, title, description, status, priority, due_date, start_date,
    created_by, reporter_uid, nid, parent_task_id, rank, ctime, mtime, completed_at
  )
  VALUES (
    _id, _title, _description, _status, IFNULL(_priority, 'medium'), _due_date, _start_date,
    _created_by, IFNULL(_reporter_uid, _created_by), _nid, _parent_task_id, _rank, _now, _now,
    IF(_status = 'complete', _now, 0)
  );

  -- Assignees are set via task_set_assignees after create (multi-assignee).
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
    -- Subtask rollup counters. Computed here rather than client-side so the
    -- badge reads the true done/total even when a member/priority filter hides
    -- some children. "done" follows the column's is_done flag, never the
    -- literal 'complete' key, so a renamed done column still counts.
    --
    -- CONVERT(... USING ascii) on the join is required, not cosmetic:
    -- task_column.id is ascii_general_ci while task.status inherits the table's
    -- utf8mb4_general_ci, and joining them raw risks
    -- ER_CANT_AGGREGATE_2COLLATIONS (1267) — the same trap documented in
    -- task_update_status and task_column_get_v2. task_column holds a handful of
    -- rows per DB, so giving up its PK lookup here costs nothing.
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
