DELIMITER $

DROP PROCEDURE IF EXISTS `get_org_storage_stats`$
CREATE PROCEDURE `get_org_storage_stats`(
  IN _domain_id INT(11) UNSIGNED
)
BEGIN
  SELECT
    e.id AS hub_id,
    e.ident AS hub_name,
    COALESCE(e.space, 0) AS used_bytes,
    ROUND(
      COALESCE(e.space, 0) / 1048576,
      2
    ) AS used_mb
  FROM yp.entity e
  WHERE e.dom_id = _domain_id
    AND e.type = 'hub'
    AND e.status = 'active'
  ORDER BY e.space DESC;
END$

DELIMITER ;