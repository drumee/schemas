DELIMITER $

DROP PROCEDURE IF EXISTS `hub_get_audit_logs_count`$
CREATE PROCEDURE `hub_get_audit_logs_count`(
  IN _username VARCHAR(255),
  IN _action VARCHAR(32),
  IN _category VARCHAR(32),
  IN _from_time INT(11),
  IN _to_time INT(11)
)
BEGIN
  -- Returns one row with `total` matching the same WHERE clause used by
  -- hub_get_audit_logs_window. Used by yp.private/admin.get_audit_logs
  -- to sum totals across every hub in the caller's domain so the FE can
  -- render an accurate paginator. _action/_category ('' = no filter)
  -- back the Audit tab action filter.
  SELECT COUNT(*) AS total
  FROM action_log a
  INNER JOIN yp.drumate d ON d.id = a.uid
  WHERE (
    _username = '' OR _username IS NULL OR
    CONCAT(d.firstname, ' ', d.lastname) LIKE CONCAT('%', _username, '%') OR
    d.firstname LIKE CONCAT('%', _username, '%') OR
    d.lastname  LIKE CONCAT('%', _username, '%') OR
    d.fullname  LIKE CONCAT('%', _username, '%') OR
    d.email     LIKE CONCAT('%', _username, '%')
  )
  AND (_action   = '' OR _action   IS NULL OR a.action   = _action)
  AND (_category = '' OR _category IS NULL OR a.category = _category)
  AND (_from_time = 0 OR a.ctime >= _from_time)
  AND (_to_time   = 0 OR a.ctime <= _to_time);
END$

DELIMITER ;
