DELIMITER $

DROP PROCEDURE IF EXISTS `get_org_user_storage`$
CREATE PROCEDURE `get_org_user_storage`(
  IN _domain_id INT(11) UNSIGNED,
  IN _sort_by VARCHAR(32),
  IN _page TINYINT(4)
)
BEGIN
  DECLARE _range BIGINT;
  DECLARE _offset BIGINT;

  CALL pageToLimits(_page, _offset, _range);

  SET _sort_by = IFNULL(_sort_by, 'usage_high');

  -- Used storage = the user's maintained footprint (files in the hubs they own
  -- + their personal space), via the canonical yp.disk_usage() function — the
  -- same source data_usage()/disk_free()/the quota cache use. The previous
  -- source (entity.space) is a dead column, 0 for every drumate and hub, which
  -- made every user read 0 B used.
  SELECT
    d.id AS uid,
    d.firstname,
    d.lastname,
    d.fullname,
    d.email,
    p.privilege AS domain_privilege,
    COALESCE(disk_usage(d.id), 0) AS used_bytes,
    ROUND(COALESCE(disk_usage(d.id), 0) / 1048576, 2) AS used_mb
  FROM yp.drumate d
  INNER JOIN yp.privilege p ON p.uid = d.id
  WHERE d.domain_id = _domain_id
  ORDER BY
    CASE WHEN _sort_by = 'usage_high' THEN used_bytes END DESC,
    CASE WHEN _sort_by = 'usage_low' THEN used_bytes END ASC,
    d.lastname ASC
  LIMIT _offset, _range;
END$

DELIMITER ;
