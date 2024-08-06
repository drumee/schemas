DELIMITER $


-- =======================================================================
-- 
-- =======================================================================
DROP PROCEDURE IF EXISTS `drumate_freeze`$
CREATE PROCEDURE `drumate_freeze`(
  IN _uid VARCHAR(16)
)
BEGIN

  UPDATE entity set status='frozen' where id=_uid;
  UPDATE drumate SET `profile` = JSON_SET(
    `profile`, '$.old_email', email
  )  WHERE id=_uid;
  UPDATE drumate SET `profile` = JSON_SET(
    `profile`, '$.email', CONCAT(_uid, '/', email)
  )  WHERE id=_uid;
  UPDATE vhost SET `fqdn` = CONCAT('--frozen--', fqdn) WHERE id=_uid;
  UPDATE privilege SET `privilege` = 0 WHERE `uid`=_uid;
  UPDATE drumate SET username = _uid WHERE id=_uid;

END$


DELIMITER ;
