DELIMITER $

DROP PROCEDURE IF EXISTS `get_org_quota`$
CREATE PROCEDURE `get_org_quota`(
  IN _domain_id INT(11) UNSIGNED
)
BEGIN
  -- Org storage limit vs cached usage. A domain can hold SEVERAL quota rows
  -- (one per payer/seat purchase), so the org allowance is the SUM of every
  -- payer's disk — the old LIMIT 1 picked an arbitrary row and understated
  -- the quota. Usage comes from yp.quota_usage (one cached row per domain).
  SELECT
    _domain_id AS domain_id,
    COALESCE(SUM(q.disk), 0) AS quota_bytes,
    COALESCE(MAX(qu.cached_usage), 0) AS used_bytes,
    IF(COALESCE(SUM(q.disk), 0) > 0,
      ROUND((COALESCE(MAX(qu.cached_usage), 0) / SUM(q.disk)) * 100, 1),
      0) AS usage_pct,
    IF(COALESCE(SUM(q.disk), 0) > 0,
      GREATEST(COALESCE(SUM(q.disk), 0) - COALESCE(MAX(qu.cached_usage), 0), 0),
      0) AS available_bytes,
    IF(COALESCE(SUM(q.disk), 0) > 0
      AND (COALESCE(MAX(qu.cached_usage), 0) / SUM(q.disk)) >= 0.9,
      1, 0) AS low_storage_alert
  FROM quota q
  LEFT JOIN quota_usage qu ON qu.domain_id = q.domain_id
  WHERE q.domain_id = _domain_id;
END$

DELIMITER ;
