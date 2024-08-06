DELIMITER $

DROP PROCEDURE IF EXISTS `mfs_rename`$
CREATE PROCEDURE `mfs_rename`(
  IN _nid VARCHAR(16),
  IN _new_name VARCHAR(255)
)
BEGIN

  DECLARE _category VARCHAR(40);
  DECLARE _parent_id VARCHAR(16);
  DECLARE _old_name VARCHAR(255);
  DECLARE _uniq_name VARCHAR(255);
  DECLARE _extension VARCHAR(255);

  SELECT category, parent_id, user_filename FROM media WHERE id=_nid 
    INTO _category, _parent_id, _old_name;  


  DROP TABLE IF EXISTS _mytree; 
  CREATE TEMPORARY TABLE _mytree (
    id varchar(16) DEFAULT NULL
  );

  INSERT INTO _mytree (id)  
  WITH RECURSIVE mytree AS (
    SELECT id, parent_id FROM media WHERE id = _nid
    UNION ALL
    SELECT m.id,m.parent_id
    FROM media AS m JOIN mytree AS t ON m.parent_id = t.id
  )
  SELECT id FROM mytree;

  IF _new_name != TRIM('/' FROM _old_name) THEN   
    UPDATE media SET 
      parent_path = parent_path(_nid), publish_time=UNIX_TIMESTAMP(),
      user_filename=unique_filename(_parent_id, _new_name, _extension) 
      WHERE id=_nid;
    UPDATE media SET parent_path = parent_path(id), file_path=filepath(id)
      WHERE id IN ( SELECT id FROM _mytree);
    -- UPDATE media SET file_path=filepath(id)
    --   WHERE id IN ( SELECT id FROM _mytree);
  END IF ;                    

  SELECT
    *,
    extension as ext,
    id as nid,
    origin_id as oid,
    parent_id as pid,
    IF(parent_id='0', 'root', 'branch') as npos,
    TRIM(TRAILING '/' FROM user_filename) as fname,
    TRIM(TRAILING '/' FROM user_filename) as filename,
    category AS filetype,
    upload_time AS ctime,
    publish_time AS mtime,
    file_path as filepath,
    category as ftype
  FROM media WHERE id=_nid;

END $


DELIMITER ;