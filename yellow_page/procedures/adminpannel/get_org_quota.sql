DELIMITER $

DROP PROCEDURE IF EXISTS `get_org_quota`$
CREATE PROCEDURE `get_org_quota`(
  IN _domain_id INT(11) UNSIGNED
)
BEGIN
  -- Domain storage limit (yp.quota.disk) vs cached org usage (yp.quota_usage).
  -- Mirrors the quota slice of hub/procedures/admin/get_hub_storage_stats.sql.
  SELECT
    _domain_id AS domain_id,
    COALESCE(q.disk, 0) AS quota_bytes,
    COALESCE(qu.cached_usage, 0) AS used_bytes,
    IF(COALESCE(q.disk, 0) > 0,
      ROUND((COALESCE(qu.cached_usage, 0) / q.disk) * 100, 1),
      0) AS usage_pct,
    IF(COALESCE(q.disk, 0) > 0,
      GREATEST(COALESCE(q.disk, 0) - COALESCE(qu.cached_usage, 0), 0),
      0) AS available_bytes,
    IF(COALESCE(q.disk, 0) > 0
      AND (COALESCE(qu.cached_usage, 0) / q.disk) >= 0.9,
      1, 0) AS low_storage_alert
  FROM yp.quota q
  LEFT JOIN yp.quota_usage qu ON qu.domain_id = q.domain_id
  WHERE q.domain_id = _domain_id
  LIMIT 1;
END$

DELIMITER ;
