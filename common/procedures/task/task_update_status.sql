DELIMITER $
DROP PROCEDURE IF EXISTS `task_update_status`$
CREATE PROCEDURE `task_update_status`(
  IN _id VARCHAR(16),
  IN _status VARCHAR(20)
)
BEGIN
  DECLARE _rank INT DEFAULT 0;
  DECLARE _done TINYINT DEFAULT 0;

  -- The task's own folder is deliberately NOT read here any more. It used to
  -- pick both the column set and the rank window; a workspace has one column
  -- set and one rank sequence per column, so neither depends on it.

  -- Is the destination a "done" column? Completion is driven by the column's
  -- is_done flag, not the literal 'complete' key — so a renamed or
  -- user-created done column still stamps completed_at correctly.
  --
  -- WORKSPACE SCOPE: one column set per workspace, at the root scope ''. This
  -- lookup used to be scoped to the task's own folder, back when built-in ids
  -- — which are literal status keys — existed once per folder and an unscoped
  -- read would have picked up another board's flag. There is one board now.
  SELECT COALESCE(MAX(is_done), 0) INTO _done
    FROM task_column
   WHERE id = _status
     AND nid = '';

  -- Place the task at the bottom of the destination column.
  -- WORKSPACE SCOPE: rank orders a COLUMN, and a column now holds every task
  -- in the workspace. Ranking within the task's own folder would restart the
  -- numbering per folder — a new task would land interleaved near the top of a
  -- column that already has twenty rows, instead of at its bottom.
  SELECT IFNULL(MAX(rank), 0) + 1
    INTO _rank
    FROM task
   WHERE status = _status
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
        -- WORKSPACE SCOPE: the column set is the workspace's, so a task's own nid
        -- (the folder it was created in, kept as provenance) no longer selects
        -- which column it matches.
        AND c.nid = ''
      WHERE s.parent_task_id = t.id
        AND c.is_done = 1) AS subtask_done
  FROM task t
  LEFT JOIN task_label tl ON tl.task_id = t.id
  WHERE t.id = _id
  GROUP BY t.id;
END$
DELIMITER ;
