DELIMITER $
DROP PROCEDURE IF EXISTS `task_set_assignees`$
CREATE PROCEDURE `task_set_assignees`(
  IN _task_id VARCHAR(16),
  IN _uids TEXT
)
BEGIN
  -- Replace the full assignee set for a task (multi-assignee).
  -- _uids is a comma-separated list of uids; '' or NULL clears all assignees.
  DECLARE _now  INT DEFAULT UNIX_TIMESTAMP();
  DECLARE _rest TEXT DEFAULT _uids;
  DECLARE _one  VARCHAR(16);

  DELETE FROM task_assignee WHERE task_id = _task_id;

  IF _uids IS NOT NULL AND _uids <> '' THEN
    WHILE LENGTH(_rest) > 0 DO
      SET _one = TRIM(SUBSTRING_INDEX(_rest, ',', 1));
      IF _one <> '' THEN
        INSERT IGNORE INTO task_assignee (task_id, uid, ctime)
        VALUES (_task_id, _one, _now);
      END IF;
      IF LOCATE(',', _rest) > 0 THEN
        SET _rest = SUBSTRING(_rest, LOCATE(',', _rest) + 1);
      ELSE
        SET _rest = '';
      END IF;
    END WHILE;
  END IF;

  UPDATE task SET mtime = _now WHERE id = _task_id;

  SELECT
    t.id, t.title, t.description, t.status, t.priority, t.due_date,
    t.created_by, t.nid, t.rank, t.ctime, t.mtime,
    GROUP_CONCAT(DISTINCT tl.label_id) AS label_ids,
    (SELECT GROUP_CONCAT(ta.uid) FROM task_assignee ta WHERE ta.task_id = t.id) AS assignee_uids
  FROM task t
  LEFT JOIN task_label tl ON tl.task_id = t.id
  WHERE t.id = _task_id
  GROUP BY t.id;
END$
DELIMITER ;
