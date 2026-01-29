DELIMITER $

DROP PROCEDURE IF EXISTS `mfs_empty_trash`$
CREATE PROCEDURE `mfs_empty_trash`()
BEGIN
  DECLARE _hub_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _db_name VARCHAR(60) CHARACTER SET ascii;
  DECLARE _home_dir VARCHAR(300) CHARACTER SET ascii;
  DECLARE _dom_id INT UNSIGNED; 
  DECLARE _delta BIGINT DEFAULT 0;

  DECLARE CONTINUE HANDLER FOR 1264 BEGIN END;

  DECLARE exit handler for sqlexception
  BEGIN
    GET DIAGNOSTICS CONDITION 1 
      @sqlstate = RETURNED_SQLSTATE, 
      @errno = MYSQL_ERRNO, 
      @text = MESSAGE_TEXT;
    SET FOREIGN_KEY_CHECKS = 1;
    ROLLBACK;
    SELECT 'ERROR' as status, CONCAT('Err ', @errno, ': ', @text) as message; 
  END;

  SET FOREIGN_KEY_CHECKS = 0; 

  DROP TABLE IF EXISTS `_hubs`; 
  CREATE TEMPORARY TABLE `_hubs`(
    hub_id varchar(16) CHARACTER SET ascii,
    db_name varchar(60) CHARACTER SET ascii,
    home_dir varchar(300) CHARACTER SET ascii,
    dom_id int unsigned, 
    is_checked int default 0      
  );

  DROP TABLE IF EXISTS `_delete`; 
  CREATE TEMPORARY TABLE `_delete`(
    id varchar(16) CHARACTER SET ascii,
    hub_id varchar(16) CHARACTER SET ascii,
    db_name varchar(60) CHARACTER SET ascii,
    home_dir varchar(300) CHARACTER SET ascii,
    filesize bigint default 0,
    category varchar(16)
  );

  -- Load personal hub
  INSERT INTO _hubs (hub_id, db_name, home_dir, dom_id, is_checked)
  SELECT DISTINCT id, db_name, home_dir, dom_id, 0 
  FROM yp.entity WHERE db_name = database();

  -- Load shared hubs using permission (not media.origin_id)
  INSERT INTO _hubs (hub_id, db_name, home_dir, dom_id, is_checked)
  SELECT DISTINCT e.id, e.db_name, e.home_dir, e.dom_id, 0 
  FROM yp.entity e 
  WHERE e.id IN (
    SELECT m.id 
    FROM media m 
    INNER JOIN permission p ON p.resource_id = m.id 
    WHERE p.permission >= 15 AND m.status = 'active' AND m.category = 'hub'
  );
    
  SELECT hub_id, db_name, home_dir, dom_id 
  FROM _hubs WHERE is_checked = 0 LIMIT 1 
  INTO _hub_id, _db_name, _home_dir, _dom_id;

  WHILE _hub_id IS NOT NULL DO
    START TRANSACTION; 

    SET @st = CONCAT(
      "INSERT INTO _delete (id, hub_id, filesize, category) ",
      "SELECT id, ", QUOTE(_hub_id), ", filesize, category ",
      "FROM ", _db_name, ".trash_media"
    );
    PREPARE stmt FROM @st; 
    EXECUTE stmt; 
    DEALLOCATE PREPARE stmt;
      
    SELECT IFNULL(SUM(filesize), 0) INTO _delta 
    FROM _delete WHERE hub_id = _hub_id;

    SET @st = CONCAT(
      "DELETE FROM ", _db_name, ".seo_index ",
      "WHERE nid IN (SELECT id FROM _delete WHERE hub_id = ", QUOTE(_hub_id), ")"
    );
    PREPARE stmt FROM @st; 
    EXECUTE stmt; 
    DEALLOCATE PREPARE stmt;

    SET @st = CONCAT(
      "DELETE FROM ", _db_name, ".seo_register ",
      "WHERE nid IN (SELECT id FROM _delete WHERE hub_id = ", QUOTE(_hub_id), ")"
    );
    PREPARE stmt FROM @st; 
    EXECUTE stmt; 
    DEALLOCATE PREPARE stmt;

    SET @st = CONCAT(
      "DELETE FROM ", _db_name, ".trash_media ",
      "WHERE id IN (SELECT id FROM _delete WHERE hub_id = ", QUOTE(_hub_id), ")"
    );
    PREPARE stmt FROM @st; 
    EXECUTE stmt; 
    DEALLOCATE PREPARE stmt;

    UPDATE yp.disk_usage 
    SET size = GREATEST(0, IFNULL(size, 0) - _delta) 
    WHERE hub_id = _hub_id;

    UPDATE _delete 
    SET db_name = _db_name, home_dir = _home_dir 
    WHERE hub_id = _hub_id;

    UPDATE _hubs 
    SET is_checked = 1 
    WHERE hub_id = _hub_id;

    COMMIT;

    SELECT NULL, NULL, NULL, NULL 
    INTO _hub_id, _db_name, _home_dir, _dom_id;
    
    SELECT hub_id, db_name, home_dir, dom_id 
    FROM _hubs WHERE is_checked = 0 LIMIT 1 
    INTO _hub_id, _db_name, _home_dir, _dom_id;
  END WHILE; 
  
  SET FOREIGN_KEY_CHECKS = 1;

  SELECT 
    id, 
    hub_id, 
    db_name, 
    category, 
    filesize, 
    CONCAT(TRIM(TRAILING '/' FROM home_dir), "/__storage__/") home_dir 
  FROM _delete;
END$

DELIMITER ;