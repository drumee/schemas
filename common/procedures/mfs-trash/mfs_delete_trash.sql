
DELIMITER $


DROP PROCEDURE IF EXISTS `mfs_delete_trash`$
CREATE PROCEDURE `mfs_delete_trash`(IN _nodes JSON)
BEGIN
  DECLARE _idx INT DEFAULT 0;
  DECLARE _nid VARCHAR(16) CHARACTER SET ascii;
  DECLARE _hub_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _db_name VARCHAR(60) CHARACTER SET ascii;
  DECLARE _home_dir VARCHAR(300) CHARACTER SET ascii;
 
  DECLARE exit handler for sqlexception
  BEGIN
    ROLLBACK;
  END;
   
  DECLARE exit handler for sqlwarning
  BEGIN
    ROLLBACK;
  END;

  START TRANSACTION;

  DROP TABLE IF EXISTS _mytree; 
  CREATE  TEMPORARY TABLE _mytree (
    id varchar(16)  CHARACTER SET ascii DEFAULT NULL,
    parent_id varchar(16)  CHARACTER SET ascii DEFAULT NULL,
    filesize bigint default 0,
    category varchar(16) NOT NULL DEFAULT 'other',
    hub_id varchar(16)  CHARACTER SET ascii DEFAULT NULL,
    home_dir VARCHAR(512) DEFAULT null,
    nid varchar(16)  CHARACTER SET ascii DEFAULT NULL
  );

  -- Temp table to accumulate disk_usage changes (batch update later)
  DROP TABLE IF EXISTS _disk_usage_deltas;
  CREATE TEMPORARY TABLE _disk_usage_deltas (
    hub_id varchar(16) CHARACTER SET ascii NOT NULL,
    delta bigint DEFAULT 0,
    PRIMARY KEY (hub_id)
  );

  WHILE _idx < JSON_LENGTH(_nodes) DO 

    SELECT JSON_UNQUOTE(JSON_EXTRACT(_nodes, CONCAT("$[", _idx, "]"))) INTO @_node;
    SELECT JSON_VALUE(@_node, "$.nid") INTO _nid;
    SELECT JSON_VALUE(@_node, "$.hub_id") INTO _hub_id;
    SELECT  db_name,home_dir FROM yp.entity WHERE id = _hub_id INTO _db_name , _home_dir;
   
    SET @st = CONCAT( 
      "INSERT INTO _mytree(id, nid, parent_id, category, filesize ) ", 
      "WITH RECURSIVE mytree AS (
        SELECT id, ", QUOTE(_nid), " nid, parent_id, category, filesize 
          FROM ", _db_name, ".trash_media WHERE id=", QUOTE(_nid),"
        UNION ALL
        SELECT m.id, ", QUOTE(_nid), " nid, m.parent_id, m.category, m.filesize
          FROM ", _db_name, ".trash_media AS m JOIN mytree AS t ON m.parent_id = t.id
      )
      SELECT id, nid, parent_id, category, filesize FROM mytree"
    );

    PREPARE stmt FROM @st;
    EXECUTE stmt ;
    DEALLOCATE PREPARE stmt; 

    UPDATE _mytree 
    SET hub_id =_hub_id ,home_dir =_home_dir 
    WHERE  nid =_nid;

    -- Accumulate delta (negative = deletion) for batch update later
    INSERT INTO _disk_usage_deltas (hub_id, delta)
    SELECT _hub_id, -(SELECT SUM(filesize) FROM _mytree WHERE nid = _nid)
    ON DUPLICATE KEY UPDATE 
      delta = delta - (SELECT SUM(filesize) FROM _mytree WHERE nid = _nid); 

    -- SEO Index Cleanup
    SELECT JSON_ARRAYAGG(id) INTO @_nids_to_clean
    FROM _mytree 
    WHERE nid = _nid 
      AND category NOT IN ('folder', 'hub', 'root');
    
    IF @_nids_to_clean IS NOT NULL AND JSON_LENGTH(@_nids_to_clean) > 0 THEN
      SET @st = CONCAT("CALL ", _db_name, ".seo_cleanup_batch(", 
        QUOTE(_hub_id), ", ", QUOTE(@_nids_to_clean), ")");
      PREPARE stmt FROM @st;
      EXECUTE stmt;
      DEALLOCATE PREPARE stmt;
    END IF;

    SET @st = CONCAT(
      "DELETE FROM " , _db_name, ".trash_media ",
      "WHERE id IN (SELECT id FROM _mytree WHERE nid =", QUOTE(_nid),")");
    PREPARE stmt FROM @st;
    EXECUTE stmt ;
    DEALLOCATE PREPARE stmt;

    SELECT _idx + 1 INTO _idx;
  END WHILE; 

  COMMIT;

  -- MOVED: Batch update disk_usage after commit
  -- Triggers will fire here and sync quota_usage automatically
  BEGIN
    DECLARE _finished INT DEFAULT 0;
    DECLARE _update_hub_id VARCHAR(16);
    DECLARE _update_delta BIGINT;
    
    DECLARE update_cursor CURSOR FOR 
      SELECT hub_id, delta FROM _disk_usage_deltas;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET _finished = 1;
    
    OPEN update_cursor;
    
    update_loop: LOOP
      FETCH update_cursor INTO _update_hub_id, _update_delta;
      
      IF _finished = 1 THEN
        LEAVE update_loop;
      END IF;
      
      UPDATE yp.disk_usage 
      SET size = GREATEST(0, IFNULL(size, 0) + _update_delta)
      WHERE hub_id = _update_hub_id;
      
    END LOOP;
    
    CLOSE update_cursor;
  END;

  SELECT 
    id, category, parent_id,CONCAT(home_dir, "/__storage__/") home_dir
  FROM _mytree
  WHERE category NOT IN ('hub') ;

END$


DELIMITER ;
