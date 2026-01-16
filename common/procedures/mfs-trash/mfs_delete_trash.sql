DELIMITER $

DROP PROCEDURE IF EXISTS `mfs_delete_trash`$
CREATE PROCEDURE `mfs_delete_trash`(IN _nodes JSON)
BEGIN
  DECLARE _idx INT DEFAULT 0;
  DECLARE _nid VARCHAR(16) CHARACTER SET ascii;
  DECLARE _hub_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _db_name VARCHAR(60) CHARACTER SET ascii;
  DECLARE _home_dir VARCHAR(300) CHARACTER SET ascii;
  DECLARE _delta BIGINT DEFAULT 0;
  DECLARE _batch_size INT DEFAULT 1000;
 
  DECLARE exit handler for sqlexception
  BEGIN
    ROLLBACK;
  END;
   
  DECLARE exit handler for sqlwarning
  BEGIN
    ROLLBACK;
  END;

  DROP TABLE IF EXISTS _mytree; 
  CREATE  TEMPORARY TABLE _mytree (
    id varchar(16) CHARACTER SET ascii DEFAULT NULL,
    parent_id varchar(16) CHARACTER SET ascii DEFAULT NULL,
    filesize bigint default 0,
    category varchar(16) NOT NULL DEFAULT 'other',
    hub_id varchar(16) CHARACTER SET ascii DEFAULT NULL,
    home_dir VARCHAR(512) DEFAULT null,
    nid varchar(16) CHARACTER SET ascii DEFAULT NULL
  );

  -- Per-node temp table for current deletion
  DROP TABLE IF EXISTS _current_node;
  CREATE TEMPORARY TABLE _current_node (
    id varchar(16) CHARACTER SET ascii,
    parent_id varchar(16) CHARACTER SET ascii,
    filesize bigint default 0,
    category varchar(16)
  );

  WHILE _idx < JSON_LENGTH(_nodes) DO 

    SELECT JSON_UNQUOTE(JSON_EXTRACT(_nodes, CONCAT("$[", _idx, "]"))) INTO @_node;
    SELECT JSON_VALUE(@_node, "$.nid") INTO _nid;
    SELECT JSON_VALUE(@_node, "$.hub_id") INTO _hub_id;
    SELECT  db_name, home_dir FROM yp.entity WHERE id = _hub_id INTO _db_name, _home_dir;

    START TRANSACTION;

    -- Clear previous node data
    DELETE FROM _current_node;

    -- Build recursive tree for this node
    SET @st = CONCAT( 
      "INSERT INTO _current_node(id, parent_id, category, filesize) ", 
      "WITH RECURSIVE mytree AS (
        SELECT id, parent_id, category, filesize 
          FROM ", _db_name, ".trash_media WHERE id=", QUOTE(_nid),"
        UNION ALL
        SELECT m.id, m.parent_id, m.category, m.filesize
          FROM ", _db_name, ".trash_media AS m 
          JOIN mytree AS t ON m.parent_id = t.id
      )
      SELECT id, parent_id, category, filesize FROM mytree"
    );

    PREPARE stmt FROM @st;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt; 

    -- Copy to global _mytree for final return
    INSERT INTO _mytree(id, nid, parent_id, category, filesize, hub_id, home_dir)
    SELECT id, _nid, parent_id, category, filesize, _hub_id, _home_dir
    FROM _current_node;

    -- Calculate delta for this node
    SELECT IFNULL(SUM(filesize), 0) INTO _delta FROM _current_node;

    BEGIN
      DECLARE _batch_start INT DEFAULT 0;
      DECLARE _total_files INT DEFAULT 0;
      
      SELECT COUNT(*) INTO _total_files 
      FROM _current_node WHERE category NOT IN ('folder', 'hub', 'root');

      WHILE _batch_start < _total_files DO
        SELECT JSON_ARRAYAGG(id) INTO @_nids_to_clean
        FROM (
          SELECT id FROM _current_node 
          WHERE category NOT IN ('folder', 'hub', 'root')
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
    
    -- Delete files based on snapshot
    SET @st = CONCAT(
      "DELETE FROM ", _db_name, ".trash_media ",
      "WHERE id IN (SELECT id FROM _current_node)"
    );
    PREPARE stmt FROM @st;
    EXECUTE stmt ;
    DEALLOCATE PREPARE stmt;

    UPDATE yp.disk_usage 
    SET size = GREATEST(0, IFNULL(size, 0) - _delta)
    WHERE hub_id = _hub_id;

    COMMIT;

    SELECT _idx + 1 INTO _idx;
  END WHILE;

  -- Return all deleted files for physical cleanup (purge.js)
  SELECT 
    id, category, parent_id, CONCAT(home_dir, "/__storage__/") home_dir
  FROM _mytree
  WHERE category NOT IN ('hub') ;

END$

DELIMITER ;
