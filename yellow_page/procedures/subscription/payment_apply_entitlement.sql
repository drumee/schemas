DELIMITER $
DROP PROCEDURE IF EXISTS `payment_apply_entitlement`$
CREATE PROCEDURE `payment_apply_entitlement`(
  IN _entity_id VARCHAR(16) CHARACTER SET ascii,   -- user id (individual) OR organisation id (org)
  IN _plan_code VARCHAR(30) CHARACTER SET ascii,
  IN _period_end INT(11) UNSIGNED,
  IN _entity_type VARCHAR(8) CHARACTER SET ascii,  -- 'user' | 'org'  (P3)
  IN _seats INT(11) UNSIGNED,                       -- org per-seat quantity (P3)
  IN _extra_disk BIGINT UNSIGNED                    -- sum of storage add-on disks (P4)
)
BEGIN
  DECLARE _domain_id INT(11) UNSIGNED;
  DECLARE _payer_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _plan_quota JSON;
  DECLARE _base_disk BIGINT UNSIGNED;
  SET _entity_type = IFNULL(NULLIF(_entity_type, ''), 'user');
  SET _seats = IFNULL(_seats, 1);
  SET _extra_disk = IFNULL(_extra_disk, 0);

  IF _entity_type = 'org' THEN
    -- Org: _entity_id = organisation id; entitlement keyed by the org's domain
    -- so disk_limit tier-2 cascades it to all members.
    --
    -- FLAT, no longer per-seat (2026-07 pricing rebuild). Team grants 100 GB
    -- for up to 10 members and Business 1 TB for unlimited — the plan's
    -- quota.$.disk is the WHOLE allowance, so it must not be multiplied by the
    -- subscription quantity any more, and quota.$.seat is the plan's member
    -- CAP, so it must not be overwritten with the purchased quantity either.
    -- _seats is kept in the signature for callers but no longer sizes anything;
    -- see yellow_page/patches/2026-07-24-pricing-usd-team-business.sql, the two
    -- have to move together or org disk goes wrong.
    SELECT domain_id FROM yp.organisation WHERE id = _entity_id LIMIT 1 INTO _domain_id;
    SET _domain_id = IFNULL(_domain_id, 1);
    SET _payer_id = _entity_id;
    SELECT quota FROM yp.plan WHERE plan_code = _plan_code AND entity_type = 'org' AND active = 1 LIMIT 1 INTO _plan_quota;
    SET _plan_quota = IFNULL(_plan_quota, JSON_OBJECT('plan', _plan_code, 'disk', 100000000000, 'seat', 10));
    SET _base_disk = IFNULL(JSON_VALUE(_plan_quota, '$.disk'), 100000000000);
    SET _plan_quota = JSON_SET(_plan_quota, '$.plan', _plan_code,
                               '$.organization', 1, '$.disk', _base_disk + _extra_disk);
  ELSE
    -- Individual: payer-keyed row. total = plan disk + storage add-ons.
    SELECT domain_id FROM yp.drumate WHERE id = _entity_id LIMIT 1 INTO _domain_id;
    SET _domain_id = IFNULL(_domain_id, 1);
    SET _payer_id = _entity_id;
    SELECT quota FROM yp.plan WHERE plan_code = _plan_code AND entity_type = 'user' AND active = 1 LIMIT 1 INTO _plan_quota;
    SET _plan_quota = IFNULL(_plan_quota, JSON_OBJECT('plan', _plan_code, 'disk', 20000000000));
    SET _base_disk = IFNULL(JSON_VALUE(_plan_quota, '$.disk'), 20000000000);
    SET _plan_quota = JSON_SET(_plan_quota, '$.plan', _plan_code, '$.disk', _base_disk + _extra_disk);
    -- C1 Pro per-seat: when the reducer resolved a real seat total (plan
    -- included seats + pro_seat add-ons), record it; keep the plan's default
    -- $.seat otherwise (callers passing the legacy 1/0 leave it untouched).
    IF _seats > IFNULL(JSON_VALUE(_plan_quota, '$.seat'), 0) THEN
      SET _plan_quota = JSON_SET(_plan_quota, '$.seat', _seats);
    END IF;
  END IF;

  INSERT INTO yp.quota (domain_id, payer_id, plan, quota, source, period_end, ctime, mtime)
  VALUES (_domain_id, _payer_id, _plan_code, _plan_quota, 'stripe', _period_end, UNIX_TIMESTAMP(), UNIX_TIMESTAMP())
  ON DUPLICATE KEY UPDATE
    plan = _plan_code, quota = VALUES(quota), source = 'stripe', period_end = _period_end, mtime = UNIX_TIMESTAMP();

  -- Rebuild the org's usage-cache row from live disk_usage. quota_usage FKs to
  -- quota(domain_id) ON DELETE CASCADE, so payment_clear_entitlement (org
  -- cancel) drops it; on re-subscribe it must be reseeded with the real total
  -- or domain usage would be undercounted (→ quota under-enforced). Idempotent
  -- on renewals (re-syncs any drift). Only for org rows keyed by a real domain.
  IF _entity_type = 'org' AND _domain_id > 1 THEN
    -- hub → domain is entity.dom_id (matches disk_usage_sync_quota_cache trigger).
    INSERT INTO yp.quota_usage (domain_id, cached_usage, actual_usage, drift, last_recalc, ctime, mtime)
    SELECT _domain_id, COALESCE(SUM(du.size), 0), COALESCE(SUM(du.size), 0), 0,
           UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), UNIX_TIMESTAMP()
      FROM yp.disk_usage du
      INNER JOIN yp.entity e ON du.hub_id = e.id
     WHERE e.dom_id = _domain_id
    ON DUPLICATE KEY UPDATE
      cached_usage = VALUES(cached_usage), actual_usage = VALUES(actual_usage),
      drift = 0, last_recalc = UNIX_TIMESTAMP(), mtime = UNIX_TIMESTAMP();
  END IF;

  SELECT _entity_id AS entity_id, _domain_id AS domain_id, _entity_type AS entity_type,
         _plan_code AS plan, _seats AS seats, _extra_disk AS extra_disk,
         _period_end AS period_end, JSON_VALUE(_plan_quota, '$.disk') AS disk;
END $
DELIMITER ;
