DELIMITER $

DROP PROCEDURE IF EXISTS `hub_get_audit_logs_filtered`$
CREATE PROCEDURE `hub_get_audit_logs_filtered`(
  IN _username VARCHAR(255),
  IN _from_time INT(11),
  IN _to_time INT(11),
  IN _page TINYINT(4)
)
BEGIN
  DECLARE _range BIGINT;
  DECLARE _offset BIGINT;

  CALL pageToLimits(_page, _offset, _range);

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
    d.email
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
  AND (_from_time = 0 OR a.ctime >= _from_time)
  AND (_to_time   = 0 OR a.ctime <= _to_time)
  ORDER BY a.ctime DESC
  LIMIT _offset, _range;
END$

DELIMITER ;