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

  SELECT
    d.id AS uid,
    d.firstname,
    d.lastname,
    d.fullname,
    d.email,
    p.privilege AS domain_privilege,
    COALESCE(e.space, 0) AS used_bytes,
    ROUND(COALESCE(e.space, 0) / 1048576, 2) AS used_mb
  FROM yp.drumate d
  INNER JOIN yp.privilege p ON p.uid = d.id
  LEFT JOIN yp.entity e ON e.id = d.id AND e.type = 'drumate'
  WHERE d.domain_id = _domain_id
  ORDER BY
    CASE WHEN _sort_by = 'usage_high' THEN COALESCE(e.space, 0) END DESC,
    CASE WHEN _sort_by = 'usage_low' THEN COALESCE(e.space, 0) END ASC,
    d.lastname ASC
  LIMIT _offset, _range;
END$

DELIMITER ;