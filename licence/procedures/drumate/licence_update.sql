
DELIMITER $

DROP PROCEDURE IF EXISTS `licence_update`$
CREATE PROCEDURE `licence_update`(
 IN _key VARCHAR(128) CHARACTER SET ascii,
 IN _signature TEXT CHARACTER SET ascii,
 IN _content JSON
)
BEGIN
  DECLARE _reseller_id VARCHAR(16) DEFAULT NULL;
  DECLARE _ctime INT(11) UNSIGNED;
  DECLARE _atime INT(11) UNSIGNED;
  
  SELECT id FROM yp.entity WHERE db_name=database() 
    INTO _reseller_id ;
  -- SELECT _reseller_id;
  SELECT UNIX_TIMESTAMP() INTO _atime;
  UPDATE licence.licence SET 
    atime=UNIX_TIMESTAMP(),
    `signature`=_signature,
    content=_content 
  WHERE `key`=_key AND reseller_id=_reseller_id;
  SELECT * FROM licence.licence WHERE `key` = _key;

END$

DELIMITER ;