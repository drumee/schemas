DELIMITER $

DROP PROCEDURE IF EXISTS `get_hub_user_storage`$
CREATE PROCEDURE `get_hub_user_storage`(
  IN _hub_id VARCHAR(16),
  IN _sort_by VARCHAR(32),
  IN _page TINYINT(4)
)
BEGIN
  DECLARE _range BIGINT;
  DECLARE _offset BIGINT;

  CALL pageToLimits(_page, _offset, _range);

  SET _sort_by = IFNULL(_sort_by, 'usage_high');

  SELECT
    p.entity_id AS uid,
    d.firstname,
    d.lastname,
    d.fullname,
    d.email,
    p.permission AS hub_permission,
    COALESCE(SUM(m.filesize), 0) AS used_bytes,
    ROUND(COALESCE(SUM(m.filesize), 0) / 1048576, 2) AS used_mb
  FROM permission p
  INNER JOIN yp.drumate d ON d.id = p.entity_id
  LEFT JOIN media m
    ON m.owner_id = p.entity_id
    AND m.status NOT IN ('hidden', 'deleted')
    AND m.category NOT IN ('folder', 'hub', 'root')
  WHERE p.resource_id = '*'
    AND p.permission  > 0
  GROUP BY p.entity_id, d.firstname, d.lastname, d.fullname, d.email, p.permission
  ORDER BY
    CASE WHEN _sort_by = 'usage_high' THEN COALESCE(SUM(m.filesize), 0) END DESC,
    CASE WHEN _sort_by = 'usage_low' THEN COALESCE(SUM(m.filesize), 0) END ASC,
    d.lastname ASC
  LIMIT _offset, _range;
END$

DELIMITER ;