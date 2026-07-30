DELIMITER $

DROP PROCEDURE IF EXISTS `get_org_quota`$
CREATE PROCEDURE `get_org_quota`(
  IN _domain_id INT(11) UNSIGNED
)
BEGIN
  -- Org storage limit vs cached usage.
  --
  -- The allowance is the ORGANISATION's own quota row (payer_id = the org
  -- entity id) — the same row disk_limit()/get_quota() enforce with. A domain
  -- routinely holds MORE rows than that one: org_provision re-keys the
  -- payer's personal free row (5 GB) onto the new org domain, so the previous
  -- SUM over the domain reported 105 GB for a 100 GB Team plan (and 1.005 TB
  -- for Business) while enforcement caps at the org row. Summing rows the
  -- enforcement never adds together overstates what the customer bought.
  --
  -- Domains with no organisation row (legacy/personal) keep the old
  -- behaviour: sum whatever payer rows exist.
  DECLARE _org_id VARCHAR(16) DEFAULT NULL;
  DECLARE _org_disk BIGINT DEFAULT NULL;
  DECLARE _quota BIGINT DEFAULT 0;

  SELECT id INTO _org_id FROM organisation
    WHERE domain_id = _domain_id LIMIT 1;
  IF _org_id IS NOT NULL THEN
    SELECT disk INTO _org_disk FROM quota
      WHERE domain_id = _domain_id AND payer_id = _org_id LIMIT 1;
  END IF;
  IF _org_disk IS NULL THEN
    -- Reward rows are excluded from the sum. A claim-reward entitlement carries
    -- $.disk at the BIGINT sentinel (2^63-1) as an unlimited marker, and
    -- _org_disk is a SIGNED BIGINT — one such row in the sum overflows it and
    -- the console header reports garbage for the whole organisation.
    --
    -- It cannot happen today: rewards are personal and land in domain 1, while
    -- this proc runs for an admin whose domain_id is > 1. The guard is here so
    -- that stops being something the header's correctness depends on
    -- remembering.
    SELECT COALESCE(SUM(disk), 0) INTO _org_disk FROM quota
      WHERE domain_id = _domain_id
        AND IFNULL(source, 'free') <> 'reward';
  END IF;
  SET _quota = COALESCE(_org_disk, 0);

  SELECT
    _domain_id AS domain_id,
    _quota AS quota_bytes,
    COALESCE(MAX(qu.cached_usage), 0) AS used_bytes,
    IF(_quota > 0,
      ROUND((COALESCE(MAX(qu.cached_usage), 0) / _quota) * 100, 1),
      0) AS usage_pct,
    IF(_quota > 0,
      GREATEST(_quota - COALESCE(MAX(qu.cached_usage), 0), 0),
      0) AS available_bytes,
    IF(_quota > 0
      AND (COALESCE(MAX(qu.cached_usage), 0) / _quota) >= 0.9,
      1, 0) AS low_storage_alert
  FROM quota_usage qu
  WHERE qu.domain_id = _domain_id;
END$

DELIMITER ;
