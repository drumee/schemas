DELIMITER $

DROP PROCEDURE IF EXISTS `organisation_get_retention`$
CREATE PROCEDURE `organisation_get_retention`(
  IN _domain_id INT
)
BEGIN
  -- Reads the org-wide versioning retention policy from organisation.metadata,
  -- bounded by what the org's PLAN actually sells.
  --
  -- The published pricing table promises 30 days on Team and 1 year on
  -- Business, and yp.quota already carries exactly that as $.history_length
  -- (30 / 365). Nothing read it: the default here was a hardcoded 30 and the
  -- admin console only offered 30/60/90, so a Business org could neither get
  -- nor choose the year it pays for, while a Team org once set to 90 kept 90
  -- after downgrading. The plan is the source of truth for the ceiling;
  -- metadata is the org's choice WITHIN it.
  --
  -- Resolution mirrors the quota cascade (see disk_limit): the organisation's
  -- own row first, then the seeded free fallback, so an org whose entitlement
  -- row is missing degrades to the platform default rather than to zero.
  --
  -- The other toggles are pure org preferences and are returned as stored.
  -- version_history_bytes is a cache refreshed by versionRetentionWorker for
  -- the "Versioning Impact" card (0 until the first worker run).
  DECLARE _plan_days INT DEFAULT 0;

  SELECT CAST(JSON_VALUE(q.quota, '$.history_length') AS UNSIGNED)
    FROM quota q
    INNER JOIN organisation o ON o.domain_id = q.domain_id AND o.id = q.payer_id
   WHERE q.domain_id = _domain_id
   LIMIT 1
    INTO _plan_days;

  IF _plan_days IS NULL OR _plan_days = 0 THEN
    SELECT CAST(JSON_VALUE(quota, '$.history_length') AS UNSIGNED)
      FROM quota
     WHERE payer_id = 'ffffffffffffffff' AND domain_id = 1
     LIMIT 1
      INTO _plan_days;
  END IF;

  -- Still nothing (the free row stores 0): keep the historical default rather
  -- than handing the worker a 0-day policy, which would purge every version an
  -- existing org holds.
  IF _plan_days IS NULL OR _plan_days = 0 THEN
    SET _plan_days = 30;
  END IF;

  SELECT
    -- The stored choice when there is one, else the plan's allowance — and
    -- never above what the plan sells.
    LEAST(
      CAST(COALESCE(JSON_VALUE(m, '$.version_retention_days'), _plan_days) AS UNSIGNED),
      _plan_days
    ) AS retention_days,
    -- What the plan permits, so the admin console can offer the choices this
    -- org is entitled to instead of a hardcoded list.
    _plan_days AS max_retention_days,
    CAST(COALESCE(JSON_VALUE(m, '$.version_apply_immediately'),      0) AS UNSIGNED) AS apply_immediately,
    CAST(COALESCE(JSON_VALUE(m, '$.version_allow_members_view'),     0) AS UNSIGNED) AS allow_members_view,
    CAST(COALESCE(JSON_VALUE(m, '$.version_allow_editors_restore'),  0) AS UNSIGNED) AS allow_editors_restore,
    CAST(COALESCE(JSON_VALUE(m, '$.version_history_bytes'),          0) AS UNSIGNED) AS version_history_bytes
  FROM (
    SELECT IF(metadata IS NULL OR metadata = '' OR NOT JSON_VALID(metadata), '{}', metadata) AS m
    FROM organisation
    WHERE domain_id = _domain_id
    LIMIT 1
  ) t;
END$

DELIMITER ;
