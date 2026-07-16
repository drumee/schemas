DELIMITER $
DROP PROCEDURE IF EXISTS `task_update_status`$
CREATE PROCEDURE `task_update_status`(
  IN _id VARCHAR(16),
  IN _status VARCHAR(20)
)
BEGIN
  DECLARE _rank INT DEFAULT 0;
  DECLARE _nid VARCHAR(16) DEFAULT NULL;
  DECLARE _done TINYINT DEFAULT 0;

  -- Resolve the task's folder so the destination-column rank is computed
  -- within the same folder, not across the whole hub.
  SELECT nid INTO _nid FROM task WHERE id = _id;

  -- Is the destination a "done" column? Completion is now driven by the
  -- column's is_done flag, not the literal 'complete' key — so a renamed or
  -- user-created done column still stamps completed_at correctly.
  SELECT COALESCE(MAX(is_done), 0) INTO _done
    FROM task_column WHERE id = _status;

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
    t.created_by, t.nid, t.rank, t.ctime, t.mtime, t.completed_at,
    GROUP_CONCAT(DISTINCT tl.label_id) AS label_ids,
    (SELECT GROUP_CONCAT(ta.uid) FROM task_assignee ta WHERE ta.task_id = t.id) AS assignee_uids
  FROM task t
  LEFT JOIN task_label tl ON tl.task_id = t.id
  WHERE t.id = _id
  GROUP BY t.id;
END$
DELIMITER ;
