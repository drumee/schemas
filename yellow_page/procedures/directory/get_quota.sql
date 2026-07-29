DELIMITER $
DROP PROCEDURE IF EXISTS `get_quota`$
CREATE PROCEDURE `get_quota`(
  IN _args TEXT
)
BEGIN
  DECLARE _uid VARCHAR(16);
  DECLARE _domain_id INTEGER;
  DECLARE _quota_json JSON;
  DECLARE _is_free_user BOOLEAN DEFAULT FALSE;

  -- Get user basic info
  SELECT id, domain_id
  FROM drumate 
  WHERE id=_args OR email=_args 
  INTO _uid, _domain_id;

  IF _uid IS NULL THEN
    SET _is_free_user = TRUE;
    SET _domain_id = 1;
  ELSE
    -- CASE 1: tenant-first — the ORGANISATION's row (payer_id =
    -- organisation.id) outranks a personal payer row when the user lives
    -- in an org domain (a pro→team upgrader owns both for a while and must
    -- get the TEAM entitlement, not their stale personal one).
    IF _domain_id > 1 THEN
      SELECT q.quota FROM quota q
        INNER JOIN organisation o ON o.domain_id = q.domain_id AND o.id = q.payer_id
       WHERE q.domain_id = _domain_id LIMIT 1 INTO _quota_json;
    END IF;

    -- CASE 2: personal payer row
    --
    -- An EXPIRED reward is skipped, which drops the user through to the free
    -- tier below -- the claim-reward campaign grants 5 years of unlimited
    -- storage as a source='reward' row, and yp.quota.period_end is enforced
    -- here rather than by a sweeper: nothing has to still be installed and
    -- running in 2031 for the term to actually end.
    --
    -- Scoped to source='reward' on purpose. Stripe rows also carry period_end,
    -- but it is informational there -- cancellation DELETEs the row
    -- (payment_clear_entitlement) -- so expiring them here would start revoking
    -- live subscriptions whose renewal webhook was merely late.
    --
    -- period_end is DEFAULT NULL in the deployed schema, so NULL has to read as
    -- "no expiry" alongside 0, or every legacy row would evaluate as expired.
    IF _quota_json IS NULL THEN
      SELECT quota
      FROM quota
      WHERE payer_id = _uid
        AND (IFNULL(source, 'free') <> 'reward'
             OR IFNULL(period_end, 0) = 0
             OR period_end > UNIX_TIMESTAMP())
      LIMIT 1
      INTO _quota_json;
    END IF;

    -- CASE 3: Still no quota, treat as free user
    IF _quota_json IS NULL THEN
      SET _is_free_user = TRUE;
    END IF;
  END IF;

  -- Get free plan quota if needed
  IF _is_free_user THEN
    SELECT quota 
    FROM quota 
    WHERE payer_id = 'ffffffffffffffff' AND domain_id = 1
    LIMIT 1
    INTO _quota_json;
  END IF;

  -- Return extracted values (handle NULL quota_json)
  IF _quota_json IS NOT NULL THEN
    SELECT 
      JSON_VALUE(_quota_json, '$.plan') AS category,
      _domain_id AS domain_id,
      JSON_VALUE(_quota_json, '$.disk') AS storage,
      -- The unlimited signal, for callers that read this PROCEDURE's named
      -- columns rather than the FUNCTION's whole JSON. media.js chekcDiskLimit
      -- is one, and it is the upload gate -- without this column it would see
      -- only `storage` and fall back to comparing against the BIGINT sentinel
      -- as a STRING, which the driver may or may not hand it as one.
      IF(JSON_VALUE(_quota_json, '$.unlimited') IN ('true', '1'), 1, 0) AS unlimited,
      JSON_VALUE(_quota_json, '$.seat') AS seat,
      JSON_VALUE(_quota_json, '$.organization') AS organization,
      JSON_VALUE(_quota_json, '$.history_length') AS history_length,
      JSON_VALUE(_quota_json, '$.billing_cycle') AS billing_cycle;
  END IF;
  
END$

DELIMITER $
-- get_quota FUNCTION
-- Returns JSON with quota information
DROP FUNCTION IF EXISTS `get_quota`$
CREATE FUNCTION `get_quota`(
  _id VARCHAR(16)
)
RETURNS JSON DETERMINISTIC
BEGIN 
  DECLARE _uid VARCHAR(16);
  DECLARE _domain_id INTEGER;
  DECLARE _quota_json JSON;
  DECLARE _res JSON;

  -- Get user basic info
  SELECT id, domain_id
  FROM drumate 
    WHERE id=_id OR email=_id 
    INTO _uid, _domain_id;

  -- If user not found, return free plan
  IF _uid IS NULL THEN
    SET _domain_id = 1;

    SELECT quota 
    FROM quota 
    WHERE payer_id = 'ffffffffffffffff' AND domain_id = 1
    LIMIT 1
    INTO _quota_json;
    
    -- Add domain_id, category and the storage alias, then return
    IF _quota_json IS NOT NULL THEN
      RETURN JSON_SET(
        _quota_json,
        '$.domain_id', 1,
        '$.category', JSON_VALUE(_quota_json, '$.plan'),
        '$.storage', JSON_EXTRACT(_quota_json, '$.disk')
      );
    ELSE
      RETURN NULL;
    END IF;
  END IF;

  -- CASE 1: tenant-first — the ORGANISATION's row (payer_id =
  -- organisation.id) outranks a personal payer row when the user lives in
  -- an org domain (a pro→team upgrader owns both for a while and must get
  -- the TEAM entitlement, not their stale personal one).
  IF _domain_id > 1 THEN
    SELECT q.quota FROM quota q
      INNER JOIN organisation o ON o.domain_id = q.domain_id AND o.id = q.payer_id
     WHERE q.domain_id = _domain_id LIMIT 1 INTO _quota_json;
  END IF;

  -- CASE 2: personal payer row
  --
  -- Same reward-expiry guard as the PROCEDURE above, and it has to be here too:
  -- this FUNCTION is what feeds desk.get_env, hence Visitor.quota() in the
  -- clients, so without it an expired reward would go on showing "Unlimited" on
  -- the account screen while uploads were being refused against the free 5 GB.
  IF _quota_json IS NULL THEN
    SELECT quota
    FROM quota
    WHERE payer_id = _uid
      AND (IFNULL(source, 'free') <> 'reward'
           OR IFNULL(period_end, 0) = 0
           OR period_end > UNIX_TIMESTAMP())
    LIMIT 1
    INTO _quota_json;
  END IF;

  -- CASE 3: Free user (fallback to free plan)
  IF _quota_json IS NULL THEN
    SELECT quota 
    FROM quota 
    WHERE payer_id = 'ffffffffffffffff' AND domain_id = 1
    LIMIT 1
    INTO _quota_json;
  END IF;

  IF _quota_json IS NOT NULL THEN
    -- Add domain_id and category for backward compatibility, plus `storage`.
    --
    -- The allowance is stored as $.disk, and the PROCEDURE of this same name
    -- already returns it aliased `AS storage`. This FUNCTION returned the raw
    -- JSON, so callers reading it got `disk` and nothing else — and that is
    -- what feeds desk.get_env, hence Visitor.quota() in the clients. Every
    -- consumer asks for `storage`, so the account screen showed a total of
    -- "0 B" with a dead usage bar and diskFree() came out NaN. Emit both: the
    -- alias the callers expect, alongside the key the row is stored under.
    RETURN JSON_SET(
      _quota_json,
      '$.domain_id', _domain_id,
      '$.category', JSON_VALUE(_quota_json, '$.plan'),
      '$.storage', JSON_EXTRACT(_quota_json, '$.disk')
    );
  ELSE
    -- Return NULL if quota not found
    RETURN NULL;
  END IF;
END$
DELIMITER ;
