DELIMITER $
DROP PROCEDURE IF EXISTS `task_activity_list`$
CREATE PROCEDURE `task_activity_list`(
  IN _nid VARCHAR(16),
  IN _include_unscoped TINYINT,
  IN _limit INT
)
BEGIN
  -- Recent activity for a folder scope, newest first. Mirrors task_list's
  -- scoping: rows whose nid matches the folder, plus legacy nid-less rows at the
  -- workspace root view (_include_unscoped = 1).
  -- The current task title/priority are joined live (LEFT JOIN — null when the
  -- task was since deleted; the client then falls back to meta.title). Actor
  -- display name is resolved client-side from the hub member list.
  IF _limit IS NULL OR _limit <= 0 THEN
    SET _limit = 30;
  END IF;

  SELECT
    a.sys_id,
    a.task_id,
    a.actor_uid,
    a.action,
    a.meta,
    a.ctime,
    t.title    AS task_title,
    t.priority AS task_priority,
    t.status   AS task_status
  FROM task_activity a
  LEFT JOIN task t ON t.id = a.task_id
  WHERE a.nid <=> _nid
     OR (_include_unscoped = 1 AND a.nid IS NULL)
  ORDER BY a.ctime DESC, a.sys_id DESC
  LIMIT _limit;
END$
DELIMITER ;
