DELIMITER $

DROP PROCEDURE IF EXISTS `changelog_read`$
CREATE PROCEDURE `changelog_read`(
  IN _uid VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci,
  IN _id INT(10)
)
BEGIN

  DECLARE _user_db VARCHAR(60) CHARACTER SET ascii ;
  DECLARE _ts INT(11);

  SELECT db_name FROM yp.entity WHERE id=_uid INTO @user_db;
  IF @user_db IS NOT NULL THEN 
    DROP TABLE IF EXISTS `_user_hubs`;
    CREATE TEMPORARY TABLE `_user_hubs` (
      `id` VARCHAR(16) CHARACTER SET ascii NOT NULL,  
      UNIQUE KEY `id` (`id`)
    );

    SET @st = CONCAT(
      "REPLACE INTO _user_hubs ",
      "SELECT id FROM ", @user_db, ".media WHERE category='hub'"
    );

    PREPARE stmt FROM @st;
    EXECUTE stmt ;
    DEALLOCATE PREPARE stmt; 
    REPLACE INTO _user_hubs SELECT _uid;
    
    SELECT m.* FROM mfs_changelog m INNER JOIN _user_hubs u ON u.id=m.hub_id;
    DROP TABLE IF EXISTS `_user_hubs`;
  END IF;
END$

DELIMITER ;
