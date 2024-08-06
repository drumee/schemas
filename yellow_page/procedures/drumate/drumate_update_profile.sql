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

  SELECT JSON_ARRAY(
    "address.city", 
    "address.country", 
    "address.location", 
    "address", 
    "archived",
    "areacode", 
    "avatar", 
    "connected",
    "dob", 
    "doc",
    "email_verified",
    "email", 
    "firstname", 
    "group", 
    "ident", 
    "intro"  ,
    "lang", 
    "lastname", 
    "mobile_verified",
    "mobile",
    "otp",
    "personaldata",
    "profile_type"
    "privacy.directory.networking", 
    "privacy.directory.visibility",
    "privacy.log.connection", 
    "privacy", 
    "role",
    "surname",
    "quota", 
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
  SELECT * FROM drumate WHERE id=_id;
END$


DELIMITER ;
