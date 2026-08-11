DELIMITER $

DROP PROCEDURE IF EXISTS `drumate_remove_profile`$
CREATE PROCEDURE `drumate_remove_profile`(
  IN _id    VARCHAR(16),
  IN _field  VARCHAR(255)
)
BEGIN

  SET @st = CONCAT("UPDATE drumate SET profile = JSON_REMOVE(profile,  '$.", _field ,"') WHERE id=?");
  PREPARE stamt FROM @st;
  EXECUTE stamt USING _id;
  DEALLOCATE PREPARE stamt; 

END$

-- =========================================================
-- Updates profile information of a drumate.
-- =========================================================
DROP PROCEDURE IF EXISTS `drumate_update_profile`$
CREATE PROCEDURE `drumate_update_profile`(
  IN _id    VARBINARY(16),
  IN _data  JSON
)
BEGIN
  DECLARE _value VARCHAR(1024);
  DECLARE _path VARCHAR(100);
  DECLARE _paths VARCHAR(1024);
  DECLARE _i TINYINT(4) DEFAULT 0;
  -- Set very short timeout (1 second)
  DECLARE CONTINUE HANDLER FOR 1205
  BEGIN
      -- Just continue silently
  END;
  SET SESSION lock_wait_timeout = 1;

  SELECT JSON_ARRAY(
    "address.city", 
    "address.country", 
    "address.location", 
    "address", 
    "archived",
    "areacode", 
    "avatar",
    "bio",
    "category",
    "connected",
    "country_code",
    "billing_cycle",
    "dob", 
    "plain_id",
    "email_verified",
    "email", 
    "firstname", 
    "group", 
    "ident",
    -- Onboarding answers mirrored onto the profile by loby's
    -- onboarding.update_profile. That service has always built industry,
    -- team_size and intent into its payload, but this whitelist never carried
    -- them, so the loop skipped all three and they were dropped in silence:
    -- completed onboardings ended up with the answers in
    -- onboarding_responses and a profile that had none of them.
    "industry",
    "intent",
    "intro"  ,
    "lang",
    "lastname",
    "mfa", 
    "mobile_verified",
    "mobile",
    "onboarded",
    "otp",
    -- Account-holds-a-real-password flag. Stamped by change_password,
    -- forgot-password and the yp.login self-heal; without this entry every
    -- one of those stamps was silently dropped by the whitelist loop.
    "password_set",
    "personaldata",
    "profile_type",
    "privacy.directory.networking", 
    "privacy.directory.visibility",
    "privacy.log.connection", 
    "privacy", 
    "quota",
    "role",
    "surname",
    "team_size",
    "username",
    "wallpaper"
  ) INTO _paths;
  WHILE _i < JSON_LENGTH(_paths) DO 
    SELECT JSON_VALUE(_paths, CONCAT("$[", _i, "]")) INTO _path;
    SELECT JSON_VALUE(_data, CONCAT("$.", _path)) INTO _value;
    -- SELECT _i, _path, _value;
    IF _value IS NOT NULL THEN 
      UPDATE drumate SET `profile` = 
        JSON_SET(`profile`, CONCAT("$.",_path), _value) WHERE id=_id;
    END IF;
    SELECT _i + 1 INTO _i;
  END WHILE;
  UPDATE entity SET mtime=UNIX_TIMESTAMP() WHERE id=_id;
  SET SESSION lock_wait_timeout = DEFAULT;
  SELECT * FROM drumate WHERE id=_id;
END$


DELIMITER ;
