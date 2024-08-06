DELIMITER $


DROP PROCEDURE IF EXISTS `mfs_make_dir`$
CREATE PROCEDURE `mfs_make_dir`(
  IN _pid TEXT,
  IN _rel_path JSON,
  IN _show_results  BOOLEAN
)
BEGIN

  DECLARE _idx INT(4) DEFAULT 0;
  DECLARE _parent_path TEXT DEFAULT '/'; 
  DECLARE _file_name VARCHAR(80);
  DECLARE _file_path TEXT DEFAULT NULL;
  DECLARE _temp_nid  VARCHAR(16);
  DECLARE _parent_id  VARCHAR(16);
  DECLARE _nid  VARCHAR(16) DEFAULT null;
  DECLARE _hub_id VARCHAR(16);
  DECLARE _home_id VARCHAR(16);
  DECLARE _rollback BOOLEAN DEFAULT 0;

  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
  BEGIN
    SET _rollback = 1;  
    GET DIAGNOSTICS CONDITION 1 
      @sqlstate = RETURNED_SQLSTATE, 
      @errno = MYSQL_ERRNO, 
      @message = MESSAGE_TEXT;
  END;

  START TRANSACTION;

  SELECT id FROM media WHERE parent_id='0' INTO _home_id;

  IF _pid REGEXP "^/" THEN 
    SELECT id, file_path FROM media WHERE file_path=clean_path(_pid) 
      INTO _pid, _file_path;
  END IF; 

  IF _file_path IS NULL THEN 
    SELECT REGEXP_REPLACE(file_path, '\\\.folder$', '')
      FROM media WHERE id = _pid INTO _file_path;
  END IF; 

  IF _file_path IS NULL THEN 
    SELECT _home_id, '' INTO _parent_id, _file_path;
  ELSE 
    SELECT _pid INTO _parent_id;
  END IF;
  
  IF JSON_LENGTH(_rel_path) IS NULL THEN
    SELECT JSON_ARRAY(_rel_path) INTO _rel_path;
  END IF;

  WHILE _idx < JSON_LENGTH(_rel_path) DO 
    SELECT JSON_VALUE(_rel_path, CONCAT("$[", _idx, "]")) INTO _file_name;
    SELECT _idx + 1 INTO _idx;
    IF _file_name != '' THEN 
      SELECT _file_path INTO _parent_path;
      SELECT clean_path(CONCAT(_file_path, '/', _file_name)) INTO _file_path;
      SELECT NULL INTO _nid;
      -- Check existence 
      SELECT id FROM media WHERE file_path = _file_path INTO _nid;
      IF _nid IS NULL THEN
        SELECT yp.uniqueId() INTO _temp_nid;
        INSERT INTO `media` (
          id, 
          origin_id, 
          file_path, 
          user_filename, 
          parent_id, 
          parent_path,

          extension, 
          mimetype, 
          category,
          isalink,

          filesize, 
          `geometry`, 
          publish_time, 
          upload_time, 

          `status`,
          rank
        ) VALUES (
          _temp_nid,
          _hub_id, 
          _file_path,
          TRIM('/' FROM _file_name),
          _parent_id, 
          _parent_path,

          '', 
          'folder', 
          'folder', 
          0,

          0,
          '0x0', 
          UNIX_TIMESTAMP(), 
          UNIX_TIMESTAMP(), 

          'active',
          0
        );
        SELECT _temp_nid INTO _parent_id;
      ELSE 
        SELECT id, parent_path, file_path FROM media WHERE id = _nid 
          INTO _parent_id, _parent_path, _file_path;
        SELECT _nid INTO _temp_nid;
      END IF;
    END IF;
  END WHILE;


  IF _rollback THEN
    ROLLBACK;
    SELECT 1 failed, 
      @sqlstate AS `sqlstate`,
      @errno AS `errno`,
      CONCAT(DATABASE(), ":", @message) AS `message`;
  ELSE
    COMMIT;
    IF IFNULL(_show_results, 1) = 1  THEN
      CALL mfs_node_attr(_temp_nid);
    END IF;  
  END IF;

END $


DELIMITER ;