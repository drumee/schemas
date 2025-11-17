-- File: schemas/yellow_page/procedures/mfs_token_cleanup.sql
-- Purpose: Clean up expired MFS export tokens and their associated permissions
--          This should be run periodically (e.g., daily cron job)

DELIMITER $

DROP PROCEDURE IF EXISTS `mfs_token_cleanup`$

CREATE PROCEDURE `mfs_token_cleanup`()
BEGIN
  DECLARE _done INT DEFAULT 0;
  DECLARE _token VARCHAR(64);
  DECLARE _hub_id VARCHAR(16);
  DECLARE _hub_db VARCHAR(80);
  DECLARE _pseudo_entity VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci;
  DECLARE _ctime INT UNSIGNED;
  DECLARE _deleted_count INT DEFAULT 0;
  
  DECLARE token_cursor CURSOR FOR
    SELECT t.token, t.hub_id, t.pseudo_entity_uid, e.db_name
    FROM yp.mfs_token t
    INNER JOIN yp.entity e ON t.hub_id = e.id
    WHERE t.expiry_time > 0 AND t.expiry_time < UNIX_TIMESTAMP();
  
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET _done = 1;
  
  SELECT UNIX_TIMESTAMP() INTO _ctime;
  
  OPEN token_cursor;
  
  read_loop: LOOP
    FETCH token_cursor INTO _token, _hub_id, _pseudo_entity, _hub_db;
    
    IF _done THEN
      LEAVE read_loop;
    END IF;
    
    SET @delete_perm = CONCAT(
      'DELETE FROM ', _hub_db, '.permission WHERE entity_id = ?'
    );
    PREPARE stmt FROM @delete_perm;
    EXECUTE stmt USING _pseudo_entity;
    DEALLOCATE PREPARE stmt;
    
    DELETE FROM yp.mfs_token WHERE token = _token;
    
    DELETE FROM yp.pseudo_entity WHERE pseudo_entity = _pseudo_entity AND token = _token;
    
    SET _deleted_count = _deleted_count + 1;
    
  END LOOP;
  
  CLOSE token_cursor;
  
  SELECT 
    0 AS failed,
    _deleted_count AS tokens_deleted,
    FROM_UNIXTIME(_ctime) AS cleanup_time,
    'Expired tokens cleaned up successfully' AS message;

END$

DELIMITER ;