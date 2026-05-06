DELIMITER $

DROP PROCEDURE IF EXISTS `get_hub_audit_logs`$
CREATE PROCEDURE `get_hub_audit_logs`(
  IN _hub_id VARCHAR(16),
  IN _username VARCHAR(255),
  IN _from_time INT(11) UNSIGNED,
  IN _to_time INT(11) UNSIGNED,
  IN _page TINYINT(4)
)
BEGIN
  DECLARE _range BIGINT;
  DECLARE _offset BIGINT;

  CALL pageToLimits(_page, _offset, _range);

  SELECT
    c.id,
    c.timestamp AS ctime,
    c.uid,
    c.hub_id,
    c.event,
    c.src,
    c.dest,
    CONCAT(d.firstname, ' ', d.lastname) AS actor_name,
    d.firstname,
    d.lastname,
    d.email
  FROM yp.mfs_changelog c
  LEFT JOIN yp.drumate d ON d.id = c.uid
  WHERE c.hub_id = _hub_id
    AND (_from_time = 0 OR c.timestamp >= _from_time)
    AND (_to_time = 0 OR c.timestamp <= _to_time)
    AND (
      _username = '' OR _username IS NULL
      OR CONCAT(d.firstname, ' ', d.lastname) LIKE CONCAT('%', _username, '%')
    )
  ORDER BY c.timestamp DESC
  LIMIT _offset, _range;
END$

DELIMITER ;