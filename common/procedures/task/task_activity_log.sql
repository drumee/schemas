DELIMITER $
DROP PROCEDURE IF EXISTS `task_activity_log`$
CREATE PROCEDURE `task_activity_log`(
  IN _task_id VARCHAR(16),
  IN _actor_uid VARCHAR(16),
  IN _action VARCHAR(20),
  IN _meta TEXT
)
BEGIN
  -- Append a task event to the folder-scoped activity feed. The task's nid is
  -- copied in so the feed can be queried per-folder and survives task deletion.
  -- Best-effort: callers must not let a logging failure break the mutation.
  DECLARE _nid VARCHAR(16) DEFAULT NULL;

  SELECT nid INTO _nid FROM task WHERE id = _task_id;

  INSERT INTO task_activity (task_id, nid, actor_uid, action, meta, ctime)
  VALUES (_task_id, _nid, _actor_uid, _action, _meta, UNIX_TIMESTAMP());
END$
DELIMITER ;
