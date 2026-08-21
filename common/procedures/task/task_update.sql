DELIMITER $
DROP PROCEDURE IF EXISTS `task_update`$
CREATE PROCEDURE `task_update`(
  IN _id VARCHAR(16),
  IN _title VARCHAR(500),
  IN _description TEXT,
  IN _priority VARCHAR(20),
  IN _due_date DATE,
  IN _start_date DATE,
  -- Reporter. NULL = keep, like title / description / priority above. There is
  -- deliberately no way to CLEAR it: a task always reads as reported by
  -- somebody, and the field falls back to created_by when it was never set.
  IN _reporter_uid VARCHAR(16)
)
BEGIN
  -- title / description / priority / reporter_uid: NULL means "keep existing"
  -- due_date / start_date: passed through directly (NULL clears the date).
  -- start_date NULL = Duration toggle OFF (single-date task).
  --
  -- created_by is absent on purpose: it is write-once provenance (see task.sql).
  -- Reassigning the reporter must never rewrite who opened the task, because the
  -- detail panel prints task.ctime right next to it.
  UPDATE task
     SET title        = IFNULL(_title, title),
         description  = IFNULL(_description, description),
         priority     = IFNULL(_priority, priority),
         due_date     = _due_date,
         start_date   = _start_date,
         reporter_uid = IFNULL(_reporter_uid, reporter_uid),
         mtime        = UNIX_TIMESTAMP()
   WHERE id = _id;

  SELECT
    t.id, t.title, t.description, t.status, t.priority, t.due_date, t.start_date,
    t.created_by,
    -- Reporter: the editable "reported by" uid. COALESCE so a row predating
    -- alter_task_add_reporter.sql (reporter_uid NULL) answers with its creator —
    -- the client never has to know the column was backfilled.
    COALESCE(t.reporter_uid, t.created_by) AS reporter_uid,
    t.nid, t.parent_task_id, t.rank, t.ctime, t.mtime,
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
