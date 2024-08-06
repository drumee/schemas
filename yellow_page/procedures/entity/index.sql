-- =========================================================
-- entity_register
-- =========================================================

DELIMITER $

-- =========================================================
-- entity_update_settings
-- =========================================================

DROP PROCEDURE IF EXISTS `entity_update_settings`$
CREATE PROCEDURE `entity_update_settings`(
  IN _id    VARCHAR(16),
  IN _name      VARCHAR(100),
  IN _value     VARCHAR(1024)
)
BEGIN
    UPDATE entity SET `settings` = JSON_SET(`settings`, CONCAT("$.", _name), _value) 
      WHERE id = _id;
    SELECT id, settings FROM entity WHERE id = _id;
END $

-- =========================================================
-- 
-- =========================================================
DROP PROCEDURE IF EXISTS `entity_update_profile`$
CREATE PROCEDURE `entity_update_profile`(
  IN _id    VARCHAR(16),
  IN _name      VARCHAR(100),
  IN _value     VARCHAR(1024)
)
BEGIN
    UPDATE entity SET `profile` = JSON_SET(`profile`, CONCAT("$.", _name), _value) 
      WHERE id = _id;
    SELECT id, settings FROM entity WHERE id = _id;
END $


-- =========================================================
-- 
-- =========================================================
DROP PROCEDURE IF EXISTS `dir_entity_exists`$
CREATE PROCEDURE `dir_entity_exists`(
   IN _ident VARBINARY(80),
   IN _email VARBINARY(280)
)
BEGIN
  DECLARE __ident VARCHAR(80);
  DECLARE __email VARCHAR(280);
  SELECT ident FROM entity WHERE ident=_ident INTO __ident;
  SELECT email FROM drumate WHERE email=_email INTO __email;
  SELECT __ident AS ident, __email AS email;
END$


-- =========================================================
-- freeze_entity
-- =========================================================

DROP PROCEDURE IF EXISTS `freeze_entity`$
CREATE PROCEDURE `freeze_entity`(
   IN _key VARBINARY(80)
)
BEGIN
  DECLARE _id VARBINARY(16);
  DECLARE _ident VARBINARY(80);
  DECLARE _type VARCHAR(80);

  SELECT id, ident,`type` FROM entity WHERE ident=_key OR id=_key INTO _id, _ident, _type;
  UPDATE entity SET status = 'frozen' WHERE  id=_id;
  UPDATE postfix.mailbox SET active = 0 WHERE  id=_id;
  UPDATE postfix.alias SET active = 0 WHERE  id=_id;
END$

-- =========================================================
-- Retrieve a retrieve entity
-- =========================================================

DROP PROCEDURE IF EXISTS `retrieve_entity`$
CREATE PROCEDURE `retrieve_entity`(
   IN _key VARBINARY(80)
)
BEGIN
  DECLARE _id VARBINARY(16);
  DECLARE _ident VARCHAR(255);
  DECLARE _type VARCHAR(255);

  SELECT id, ident, `type` FROM entity WHERE ident=_key OR id=_key INTO _id, _ident, _type;

  START TRANSACTION;
    UPDATE entity SET status = 'active' WHERE  id=_id;
    UPDATE postfix.mailbox SET active = 1 WHERE  local_part=_ident;
    UPDATE postfix.alias SET active = 1 WHERE  address=concat(_ident, '@', main_domain());
  COMMIT;

  SELECT id, ident,`type` FROM entity WHERE ident=_key OR id=_key INTO _id, _ident, _type;
  IF _type = 'drumate' THEN
    SELECT * FROM user_csv WHERE id=_id;
  ELSE
    SELECT * FROM site_csv WHERE id=_id;
  END IF;
END$

-- =========================================================
-- 
-- =========================================================

DROP PROCEDURE IF EXISTS `set_default_homepage`$
CREATE PROCEDURE `set_default_homepage`(
   IN _key VARBINARY(80)
)
BEGIN
  DECLARE _id VARBINARY(16);
  DECLARE _db_name VARCHAR(512);
  DECLARE _homepage VARCHAR(512);
  
  SELECT id, db_name, homepage FROM entity WHERE ident=_key OR id=_key INTO
    _id,_db_name, _homepage;
  
  IF _homepage = '{}' OR _homepage IS NULL THEN
    SET @sql = CONCAT(    
      'SELECT hashtag FROM ' ,
      _db_name ,'.block  ORDER BY ctime ASC LIMIT 1 INTO @hashtag'            
    );
    PREPARE stmt FROM @sql ;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    UPDATE entity SET homepage = @hashtag  WHERE id=_id;
  END IF;
END$

DELIMITER ;

