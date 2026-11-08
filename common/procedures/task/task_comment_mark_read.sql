DELIMITER $

-- =========================================================
-- task_comment_mark_read
-- Every comment on _task_id now counts as read for _uid. Called when the user
-- opens the task's detail panel. Returns {task_id, read_ts}.
-- =========================================================
DROP PROCEDURE IF EXISTS `task_comment_mark_read`$
CREATE PROCEDURE `task_comment_mark_read`(
  IN _task_id VARCHAR(16),
  IN _uid VARCHAR(16)
)
BEGIN
  DECLARE _now INT DEFAULT UNIX_TIMESTAMP();

  INSERT INTO task_comment_read (task_id, uid, read_ts)
  VALUES (_task_id, _uid, _now)
  ON DUPLICATE KEY UPDATE read_ts = VALUES(read_ts);

  SELECT task_id, read_ts
    FROM task_comment_read
   WHERE task_id = _task_id
     AND uid = _uid;
END $

DELIMITER ;
