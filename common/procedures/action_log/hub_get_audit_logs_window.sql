DELIMITER $

DROP PROCEDURE IF EXISTS `hub_get_audit_logs_window`$
CREATE PROCEDURE `hub_get_audit_logs_window`(
  IN _username VARCHAR(255),
  IN _action VARCHAR(32),
  IN _category VARCHAR(32),
  IN _from_time INT(11),
  IN _to_time INT(11),
  IN _limit INT(11)
)
BEGIN
  -- Returns up to _limit most recent audit rows matching the same filter
  -- as hub_get_audit_logs_filtered, with no per-hub pagination. The yp
  -- aggregator (admin.get_audit_logs) fetches page*PAGE_SIZE rows from
  -- every hub, merges by ctime DESC, then slices the requested page —
  -- this guarantees correct cross-hub pagination, which the page-per-hub
  -- variant could not produce.
  -- _action/_category ('' = no filter) back the Audit tab action filter.
  -- target_name/target_email resolve entity_id when it points at a member
  -- (member/permission rows) so the FE can show a proper Target Resource
  -- instead of parsing the free-text log.
  IF _limit IS NULL OR _limit <= 0 THEN
    SET _limit = 200;
  END IF;

  SELECT
    a.uid,
    a.action,
    a.category,
    a.notify_to,
    a.entity_id,
    a.log,
    a.ctime,
    CONCAT(d.firstname, ' ', d.lastname) AS actor_name,
    d.firstname,
    d.lastname,
    d.email,
    CONCAT(t.firstname, ' ', t.lastname) AS target_name,
    t.email AS target_email
  FROM action_log a
  INNER JOIN yp.drumate d ON d.id = a.uid
  LEFT JOIN yp.drumate t ON t.id = a.entity_id
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
  AND (_to_time   = 0 OR a.ctime <= _to_time)
  ORDER BY a.ctime DESC
  LIMIT _limit;
END$

DELIMITER ;
