DELIMITER $
DROP PROCEDURE IF EXISTS `get_quota`$
CREATE PROCEDURE `get_quota`(
  IN _args TEXT
)
BEGIN
  DECLARE _uid VARCHAR(16);
  DECLARE _domain_id INTEGER;
  DECLARE _category VARCHAR(512) CHARACTER SET ascii COLLATE ascii_general_ci;
  DECLARE _plan VARCHAR(80);
  DECLARE _quota JSON;

  -- Get user basic info
  SELECT id, domain_id, IFNULL(quota, "{}") 
  FROM drumate 
  WHERE id=_args OR email=_args 
  INTO _uid, _domain_id, _quota;

  IF _uid IS NOT NULL THEN
    -- CASE 1: Check if user is payer (paid subscription)
    SELECT plan 
    FROM quota 
    WHERE payer_id = _uid 
    INTO _plan;
  
    -- CASE 2: If not payer, check if user belongs to paid organization
    IF _plan IS NULL AND _domain_id > 1 THEN
      SELECT plan 
      FROM quota 
      WHERE domain_id = _domain_id 
      INTO _plan;
    END IF;

    -- CASE 3: Determine final category
    IF _plan IS NOT NULL THEN
      -- User is payer or member of paid org
      SELECT _plan INTO _category;
    ELSE
      -- Free user: use profile.category (existing logic)
      SELECT IFNULL(JSON_VALUE(profile, "$.category"), "default") 
      FROM drumate 
      WHERE id = _uid 
      INTO _category;
    END IF;
  ELSE
    -- User not found
    SET _category = 'default';
    SET _domain_id = 1;
  END IF;

  SELECT IFNULL(_category, 'default') INTO _category;
  
  SELECT 
    category,
    COALESCE(JSON_VALUE(_quota, "$.private_hub"), private_hub) private,
    COALESCE(JSON_VALUE(_quota, "$.share_hub"), share_hub) share ,
    COALESCE(JSON_VALUE(_quota, "$.public_hub"), public_hub) public,
    COALESCE(JSON_VALUE(_quota, "$.disk"), desk_disk) storage,
    COALESCE(JSON_VALUE(_quota, "$.organization"), organization) organization,
    COALESCE(JSON_VALUE(_quota, "$.meeting_call"), conference) conference,
    _domain_id AS domain_id 
  FROM group_quota WHERE category=_category
  LIMIT 1;

  -- If category not found, fallback to default
  IF ROW_COUNT() = 0 THEN
    SELECT 
      'default' AS category,
      private_hub AS private,
      share_hub AS share,
      public_hub AS public,
      desk_disk AS storage,
      organization,
      conference,
      _domain_id AS domain_id
    FROM group_quota 
    WHERE category = 'default'
    LIMIT 1;
  END IF;
END$

DELIMITER $
DROP FUNCTION IF EXISTS `get_quota`$
CREATE FUNCTION `get_quota`(
  _id VARCHAR(16)
)
RETURNS JSON DETERMINISTIC
BEGIN 
  DECLARE _uid VARCHAR(16);
  DECLARE _domain_id INTEGER;
  DECLARE _category VARCHAR(512) CHARACTER SET ascii COLLATE ascii_general_ci;
  DECLARE _plan VARCHAR(80);
  DECLARE _quota JSON;
  DECLARE _res JSON;

  -- Get user basic info
  SELECT id 
    FROM drumate 
    WHERE id=_id OR email=_id 
    INTO _uid, _domain_id, _quota;

  -- If user not found, use default category
  IF _uid IS NULL THEN
    SET _category = 'default';
    SET _domain_id = 1;
  ELSE
    -- CASE 1: Check if user is payer
    SELECT plan 
    FROM quota 
    WHERE payer_id = _uid 
    INTO _plan;
  
    -- CASE 2: If not payer, check if user belongs to paid organization
    IF _plan IS NULL AND _domain_id > 1 THEN
      SELECT plan 
      FROM quota 
      WHERE domain_id = _domain_id 
      INTO _plan;
    END IF;
  
    -- CASE 3: Determine final category
    IF _plan IS NOT NULL THEN
      -- User is payer or member of paid org
      SELECT _plan INTO _category;
    ELSE
      -- Free user: use profile.category
      SELECT IFNULL(JSON_VALUE(profile, "$.category"), "default") 
      FROM drumate 
      WHERE id = _uid 
      INTO _category;
    END IF;
  END IF;

  SELECT IFNULL(_category, 'default') INTO _category;

  SELECT JSON_OBJECT(
    'category', category,
    'domain_id', _domain_id,
    'private', COALESCE(JSON_VALUE(_quota, "$.private_hub"), private_hub),
    'share', COALESCE(JSON_VALUE(_quota, "$.share_hub"), share_hub) ,
    'public', COALESCE(JSON_VALUE(_quota, "$.public_hub"), public_hub),
    'storage', COALESCE(JSON_VALUE(_quota, "$.disk"), desk_disk),
    'organization', COALESCE(JSON_VALUE(_quota, "$.organization"), organization),
    'conference', COALESCE(JSON_VALUE(_quota, "$.meeting_call"), conference)
  )
  FROM group_quota WHERE category=_category LIMIT 1 INTO _res;

  -- Fallback to 'default' if category not found
  IF _res IS NULL THEN
    SELECT JSON_OBJECT(
      'category', 'default',
      'domain_id', _domain_id,
      'private', private_hub,
      'share', share_hub,
      'public', public_hub,
      'storage', desk_disk,
      'organization', organization,
      'conference', conference
    )
    FROM group_quota 
    WHERE category = 'default'
    LIMIT 1
    INTO _res;
  END IF;

  RETURN _res;
END$
DELIMITER ;
