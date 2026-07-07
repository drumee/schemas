DELIMITER $

DROP PROCEDURE IF EXISTS `get_org_storage_stats`$
CREATE PROCEDURE `get_org_storage_stats`(
  IN _domain_id INT(11) UNSIGNED
)
BEGIN
  -- Per-hub used storage from the maintained yp.disk_usage table (keyed by
  -- hub_id). The previous source (entity.space) is a dead column — 0 for every
  -- hub — so the org storage breakdown read 0 B for every workspace.
  -- hub_name: entity.ident is often NULL on freshly-created hubs, so fall back
  -- through yp.hub.name then hubname (same chain as member_list_workspaces).
  SELECT
    e.id AS hub_id,
    IFNULL(IFNULL(e.ident, h.name), h.hubname) AS hub_name,
    COALESCE(du.size, 0) AS used_bytes,
    ROUND(COALESCE(du.size, 0) / 1048576, 2) AS used_mb
  FROM yp.entity e
  LEFT JOIN yp.disk_usage du ON du.hub_id = e.id
  LEFT JOIN yp.hub h ON h.id = e.id
  WHERE e.dom_id = _domain_id
    AND e.type = 'hub'
    AND e.status = 'active'
  ORDER BY used_bytes DESC;
END$

DELIMITER ;
