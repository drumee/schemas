-- =========================================================
-- entity_register
-- =========================================================

DELIMITER $

DROP PROCEDURE IF EXISTS `entity_create`$
CREATE PROCEDURE `entity_create`(
  IN _type VARCHAR(20)
)
BEGIN
  DECLARE _db_host VARCHAR(255);
  DECLARE _fs_host VARCHAR(255);
  DECLARE _home_dir VARCHAR(255);
  DECLARE _hid VARCHAR(16);
  DECLARE _now INT(11);
  DECLARE _domain VARCHAR(80);
  DECLARE _db_name VARCHAR(80);
  DECLARE _icon VARCHAR(1024) DEFAULT "/-/images/logo/desk.jpg";
  DECLARE _settings MEDIUMTEXT;
  DECLARE _rollback BOOLEAN DEFAULT 0;  

  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
  BEGIN
    SET _rollback = 1;  
    GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, 
    @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
    SET @full_error = CONCAT("ERROR ", @errno, " (", @sqlstate, "): ", @text);
  END;

  SELECT uniqueId(), UNIX_TIMESTAMP(), make_db_name()
    INTO _hid, _now, _db_name;


  SELECT conf_value FROM sys_conf WHERE conf_key='icon' INTO _icon;

  SELECT
    dbhost, fshost,
    CONCAT(
      IF( mfs_root REGEXP '/+$', mfs_root, CONCAT(mfs_root, '/')), 
      substring(uniqueId(), 1, 4), '/', _hid, '/'
    ),
    settings, domainname
    FROM settings WHERE build=1 INTO
    _db_host, _fs_host, _home_dir, _settings, _domain;

  START TRANSACTION;
    INSERT INTO entity (
      `id`,`db_name`,`db_host`,`fs_host`, `home_dir`,
      `settings`, `type`, `area`, icon,
      `status`, `ctime`, `mtime`, `dom_id`)
    VALUES (
      _hid, _db_name, _db_host, _fs_host, _home_dir,
      _settings, _type, 'pool',  _icon,
      'frozen', _now, _now, 1);

    INSERT INTO yp.disk_usage VALUES(null, _hid, 0);

    SET @s = CONCAT("CREATE DATABASE `", _db_name,
      "` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci");
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

  IF _rollback THEN
    ROLLBACK;
    SELECT 1 as failed, @full_error AS reason;
  ELSE
    COMMIT;
  END IF;

  SELECT * FROM entity WHERE id = _hid;
END$

DELIMITER ;