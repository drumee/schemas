DELIMITER $


-- ==============================================================
-- Actually delete the media tagged as deleted
-- ==============================================================

DROP PROCEDURE IF EXISTS `mfs_purge`$
CREATE PROCEDURE `mfs_purge`(
  IN _id VARCHAR(16)
)
BEGIN
  DECLARE _node_path VARCHAR(255);
  DECLARE _category VARCHAR(40);
  DECLARE _filesize BIGINT UNSIGNED;
  DECLARE _hub_id VARCHAR(20);
  DECLARE _home_dir VARCHAR(1024);

  SELECT id ,home_dir FROM yp.entity WHERE db_name=database() INTO _hub_id, _home_dir;

  DROP TABLE IF EXISTS _mytree; 
  CREATE TEMPORARY TABLE _mytree (
      id varchar(16) DEFAULT NULL
  );

  INSERT INTO _mytree (id)  
    WITH RECURSIVE mytree AS (
      SELECT id, parent_id FROM media WHERE id = _id
      UNION ALL
      SELECT m.id,m.parent_id
      FROM media AS m JOIN mytree AS t ON m.parent_id = t.id
    )
    SELECT id FROM mytree;


  -- CALL mediaEnv(@_tmp, _hub_id, @_tmp, _home_dir, @_tmp, @_tmp, @_tmp);
  
  SELECT category, filesize FROM media WHERE id=_id into _category, _filesize;



  DROP TABLE IF EXISTS __purge_stack;
  CREATE TEMPORARY TABLE IF NOT EXISTS  __purge_stack LIKE template.tmp_id;

  IF _category='folder' THEN    
    SELECT SUM(filesize) FROM media 
    WHERE id IN (SELECT id FROM _mytree)
      AND category != 'hub' INTO _filesize;
  END IF;

  IF _category='form' THEN
    SET @s = CONCAT("DROP TABLE IF EXISTS `form_", _id, "`");
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;

  INSERT INTO __purge_stack SELECT id, CONCAT(_home_dir, "/__storage__/") 
  FROM media WHERE id IN ( SELECT id FROM _mytree);


  DELETE FROM media WHERE id IN (SELECT nid FROM __purge_stack);

  IF(SELECT count(*) FROM yp.disk_usage where hub_id=_hub_id) > 0 THEN 
    UPDATE yp.disk_usage SET size = (size - _filesize) WHERE hub_id = _hub_id;
  ELSE 
    INSERT INTO yp.disk_usage VALUES(null, _hub_id, 0);
  END IF;

  SELECT * FROM __purge_stack;
  DROP TABLE IF EXISTS __purge_stack;
END $


DELIMITER ;