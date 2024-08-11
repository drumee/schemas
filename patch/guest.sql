-- CREATE TABLE `guest` ( `id` INT NOT NULL AUTO_INCREMENT , `session_id` INT NOT NULL , `auth_code` INT NOT NULL , `email` INT NOT NULL , `acl_key` INT NOT NULL , PRIMARY KEY (`id`)) ENGINE = InnoDB;
-- ALTER TABLE `guest` CHANGE `session_id` `guest_name` VARCHAR(120) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
-- ALTER TABLE `guest` CHANGE `id` `id` VARCHAR(16) CHARACTER SET ascii COLLATE ascii_bin NOT NULL;
-- ALTER TABLE `guest` ADD `ctime` INT(11) UNSIGNED NOT NULL AFTER `id`, ADD INDEX (`ctime`);
-- ALTER TABLE `guest` ADD UNIQUE(`auth_code`);

-- ALTER TABLE `guest` CHANGE `acl_key` `acl_key` VARBINARY(32) NOT NULL;
-- ALTER TABLE `guest` CHANGE `email` `email` VARCHAR(255) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL;
-- ALTER TABLE `guest` CHANGE `auth_code` `auth_code` VARCHAR(80) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL;
-- ALTER TABLE `guest` CHANGE `acl_key` `comment` VARCHAR(40) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
DELIMITER $

DROP PROCEDURE IF EXISTS `acl_add_guest`$
CREATE PROCEDURE `acl_add_guest`(
  IN _rid VARBINARY(16),
  IN _rtype VARCHAR(80),
  IN _permission TINYINT(4),
  IN _code VARCHAR(16),
  IN _email VARCHAR(80),
  IN _name VARCHAR(80)
)
BEGIN

  DECLARE _now INT(11) DEFAULT 0;
  DECLARE _guest_id VARCHAR(16);

  SELECT uniqueId(), UNIX_TIMESTAMP() into _guest_id, _now;
  CALL acl_grant(_rid, _rtype, _guest_id, _permission);

  INSERT INTO
    guest VALUES(_guest_id, _now, _name, sha2(_code, 256), _email, _code);
  SELECT id, ctime, guest_name, auth_code, email, comment, pkey FROM guest
    LEFT JOIN acl ON entity_id=guest.id WHERE id = _guest_id;

END$

-- =======================================================================
--
-- =======================================================================
DROP PROCEDURE IF EXISTS `acl_remove_guest`$
CREATE PROCEDURE `acl_remove_guest`(
  IN _code VARCHAR(16),
  IN _email VARCHAR(80)
)
BEGIN

  DECLARE _guest_id VARCHAR(16);

  SELECT id FROM guest WHERE auth_code=sha2(_code, 256)  into _guest_id;
  DELETE FROM acl WHERE entity_id=_guest_id;
  DELETE FROM guest WHERE id=_guest_id;

END$


DELIMITER ;
