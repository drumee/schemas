DELIMITER $


DROP PROCEDURE IF EXISTS `changelog_read`$
CREATE PROCEDURE `changelog_read`(
  IN _args JSON
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  DECLARE _user_db VARCHAR(60) CHARACTER SET ascii ;
  DECLARE _uid VARCHAR(60) CHARACTER SET ascii ;
  DECLARE _page INTEGER;
  DECLARE _id INTEGER;
  DECLARE _last INTEGER;
  DECLARE _page_length INTEGER;
  DECLARE _finished BOOLEAN;
  DECLARE _timestamp INT(11);
  DECLARE _exclude JSON;
  DECLARE _i TINYINT(6) unsigned DEFAULT 0;

  SELECT JSON_VALUE(_args, "$.page") INTO _page;
  SELECT JSON_VALUE(_args, "$.page_length") INTO _page_length;
  SELECT JSON_VALUE(_args, "$.timestamp") INTO _timestamp;
  SELECT JSON_VALUE(_args, "$.last") INTO _last;
  SELECT JSON_VALUE(_args, "$.id") INTO _id;
  SELECT JSON_VALUE(_args, "$.uid") INTO _uid;
  SELECT JSON_EXTRACT(_args, "$.exclude") INTO _exclude;
  IF _exclude IS NULL THEN
    SELECT JSON_ARRAY() INTO _exclude;
  ELSE
    IF JSON_TYPE(JSON_EXTRACT(_args, "$.exclude")) != 'ARRAY' THEN 
      SELECT JSON_ARRAY(_exclude) INTO _exclude;
    END IF;
  END IF;
  DROP TABLE IF EXISTS `_hub_ids`;
  CREATE TEMPORARY TABLE `_hub_ids`(
    `id` VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
    PRIMARY KEY (`id`)
  );
  WHILE _i < JSON_LENGTH(_exclude) DO 
    REPLACE INTO _hub_ids SELECT JSON_VALUE(_exclude, CONCAT("$[", _i, "]"));
    SELECT _i + 1 INTO _i;
  END WHILE;

  IF _page_length IS NOT NULL THEN
    SELECT 300 INTO _page_length;
  END IF;

  SELECT db_name FROM yp.entity WHERE id=_uid INTO _user_db;
  IF _user_db IS NOT NULL THEN 
    DROP TABLE IF EXISTS `_user_hubs`;
    CREATE TEMPORARY TABLE `_user_hubs` (
      `id` VARCHAR(16) CHARACTER SET ascii NOT NULL,  
      UNIQUE KEY `id` (`id`)
    );

    SET @st = CONCAT(
      "REPLACE INTO _user_hubs ",
      "SELECT id FROM ", _user_db, ".media WHERE category='hub' ",
      "AND id NOT IN (SELECT id from _hub_ids)"
    );

    PREPARE stmt FROM @st;
    EXECUTE stmt ;
    DEALLOCATE PREPARE stmt; 
    REPLACE INTO _user_hubs SELECT _uid;
    
    IF _page IS NOT NULL THEN 
      SET @rows_per_page = _page_length;
      CALL pageToLimits(_page, _offset, _range); 
      SELECT m.* FROM mfs_changelog m INNER JOIN _user_hubs u ON u.id=m.hub_id 
      ORDER BY m.id DESC LIMIT _offset, _range;

    ELSEIF _timestamp IS NOT NULL THEN 
      SELECT m.* FROM mfs_changelog m INNER JOIN _user_hubs u ON u.id=m.hub_id 
      WHERE m.timestamp >= _timestamp ORDER BY m.id DESC;

    ELSEIF _id IS NOT NULL THEN 
      SELECT m.* FROM mfs_changelog m INNER JOIN _user_hubs u ON u.id=m.hub_id 
      WHERE m.id >= _id ORDER BY m.id DESC;

    ELSEIF _last IS NOT NULL THEN 
      SELECT m.* FROM mfs_changelog m INNER JOIN _user_hubs u ON u.id=m.hub_id 
      ORDER BY m.id DESC LIMIT _last;

    ELSE 
      SELECT unix_timestamp() - 60*60*24 INTO _timestamp;
      SELECT m.* FROM mfs_changelog m INNER JOIN _user_hubs u ON u.id=m.hub_id 
      WHERE m.timestamp >= _timestamp ORDER BY m.id DESC LIMIT _page_length;
    END IF;

  END IF;
  DROP TABLE IF EXISTS `_user_hubs`;
END$

DELIMITER ;
