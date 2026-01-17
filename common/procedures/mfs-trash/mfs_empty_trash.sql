DELIMITER $

DROP PROCEDURE IF EXISTS `mfs_empty_trash`$
CREATE PROCEDURE `mfs_empty_trash`()
BEGIN
  DECLARE _hub_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _db_name VARCHAR(60) CHARACTER SET ascii;
  DECLARE _home_dir VARCHAR(300) CHARACTER SET ascii;
  DECLARE _delta BIGINT DEFAULT 0;
  DECLARE _batch_size INT DEFAULT 1000;

  DECLARE exit handler for sqlexception
  BEGIN
    ROLLBACK;
  END;

  DROP TABLE IF EXISTS `_hubs`; 
  CREATE TEMPORARY TABLE `_hubs`(
    hub_id varchar(16) CHARACTER SET ascii,
    db_name varchar(60) CHARACTER SET ascii,
    home_dir varchar(300) CHARACTER SET ascii,
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

  INSERT INTO _hubs
  SELECT id, db_name, home_dir, 0 FROM yp.entity WHERE db_name = database();

  SELECT hub_id, db_name, home_dir FROM _hubs WHERE is_checked = 0 LIMIT 1
    INTO _hub_id, _db_name, _home_dir;

  WHILE _hub_id IS NOT NULL DO
    START TRANSACTION; 

    SET @st = CONCAT(
      "INSERT INTO _delete (id, hub_id, filesize, category) ",
      "SELECT id, ", QUOTE(_hub_id), ", filesize, category FROM ", 
      _db_name, ".trash_media"
    );
    PREPARE stmt FROM @st;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
      
    SELECT IFNULL(SUM(filesize), 0) INTO _delta
    FROM _delete WHERE hub_id = _hub_id;
    
    BEGIN
      DECLARE _batch_start INT DEFAULT 0;
      DECLARE _total_files INT DEFAULT 0;
      
      SELECT COUNT(*) INTO _total_files 
      FROM _delete WHERE hub_id = _hub_id;

      WHILE _batch_start < _total_files DO
        SELECT JSON_ARRAYAGG(id) INTO @_nids_to_clean
        FROM (
          SELECT id FROM _delete 
          WHERE hub_id = _hub_id
          LIMIT _batch_start, _batch_size
        ) AS batch;
    
        IF @_nids_to_clean IS NOT NULL AND JSON_LENGTH(@_nids_to_clean) > 0 THEN
          SET @st = CONCAT("CALL ", _db_name, ".seo_cleanup_batch(", 
            QUOTE(_hub_id), ", ", QUOTE(@_nids_to_clean), ")");
          PREPARE stmt FROM @st;
          EXECUTE stmt;
          DEALLOCATE PREPARE stmt;
        END IF;

        SET _batch_start = _batch_start + _batch_size;
      END WHILE;
    END;

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

    UPDATE _delete SET db_name = _db_name, home_dir = _home_dir 
    WHERE hub_id = _hub_id;

    UPDATE _hubs SET is_checked = 1 WHERE hub_id = _hub_id;

    COMMIT;

    SELECT NULL, NULL, NULL INTO _hub_id, _db_name, _home_dir;
    SELECT hub_id, db_name, home_dir FROM _hubs WHERE is_checked = 0 LIMIT 1 
      INTO _hub_id, _db_name, _home_dir;
  END WHILE; 
  
  SELECT id, CONCAT(home_dir, "/__storage__/") home_dir FROM _delete;
END$

DELIMITER ;