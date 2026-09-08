DELIMITER $
DROP PROCEDURE IF EXISTS `task_activity_list`$
CREATE PROCEDURE `task_activity_list`(
  IN _nid VARCHAR(16),
  IN _include_unscoped TINYINT,
  IN _limit INT
)
BEGIN
  -- Recent activity, newest first. Mirrors task_list's scoping exactly:
  --   _nid = '*'  every row in this workspace, whatever folder it belongs to.
  --               This is what the board's Project Health feed asks for — the
  --               board is workspace-level, so its activity is too.
  --   otherwise   rows whose nid matches that folder, plus legacy nid-less rows
  --               when _include_unscoped = 1.
  -- '*' is a sentinel rather than a fourth parameter because MariaDB procedures
  -- take no default arguments: adding one would break every existing CALL.
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
  WHERE
    _nid = '*'
     OR a.nid <=> _nid
     OR (_include_unscoped = 1 AND a.nid IS NULL)
  ORDER BY a.ctime DESC, a.sys_id DESC
  LIMIT _limit;
END$
DELIMITER ;
