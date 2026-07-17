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
    IF _quota_json IS NULL THEN
      SELECT quota 
      FROM quota 
      WHERE payer_id = _uid 
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
    
    -- Add domain_id and category, then return
    IF _quota_json IS NOT NULL THEN
      RETURN JSON_SET(
        _quota_json,
        '$.domain_id', 1,
        '$.category', JSON_VALUE(_quota_json, '$.plan')
      );
    ELSE
      RETURN NULL;
    END IF;
  END IF;

  -- CASE 1: Check if user is payer (paid subscription)
  SELECT quota 
  FROM quota 
  WHERE payer_id = _uid 
  LIMIT 1
  INTO _quota_json;
  
  -- CASE 2: If not payer, check if user belongs to paid organization
  IF _quota_json IS NULL AND _domain_id > 1 THEN
    SELECT quota 
    FROM quota 
    WHERE domain_id = _domain_id 
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
    -- Add domain_id and category for backward compatibility
    RETURN JSON_SET(
      _quota_json,
      '$.domain_id', _domain_id,
      '$.category', JSON_VALUE(_quota_json, '$.plan')
    );
  ELSE
    -- Return NULL if quota not found
    RETURN NULL;
  END IF;
END$
DELIMITER ;
