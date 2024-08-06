DELIMITER $

-- ================================================
-- 
-- ""
-- ================================================
DROP PROCEDURE IF EXISTS `mfs_init_folders`$
CREATE PROCEDURE `mfs_init_folders`(
  IN _folders JSON,
  IN _clear_existing boolean
)
BEGIN
  DECLARE _i INT(4) DEFAULT 0; 
  DECLARE _pid VARCHAR(16);
  DECLARE _home_id VARCHAR(16);
  DECLARE _uid VARCHAR(16);
  DECLARE _status VARCHAR(16);
  DECLARE _path TEXT;
  SELECT id FROM media WHERE parent_id='0' INTO _home_id;
  IF _clear_existing THEN 
    DELETE FROM media WHERE status='active' AND parent_id=_home_id;
    SELECT id FROM yp.entity WHERE db_name=database() INTO _uid;
    UPDATE media SET origin_id=_uid;
  END IF;
  WHILE _i < JSON_LENGTH(_folders) DO 
    SELECT JSON_EXTRACT(_folders, CONCAT("$[", _i, "]")) INTO @_node;
    SELECT JSON_VALUE(@_node, "$.path") INTO _path;
    SELECT TRIM(TRAILING '/' FROM TRIM(LEADING '/' FROM _path)) INTO _path;
    SELECT IFNULL(JSON_VALUE(@_node, "$.pid"), _home_id) INTO _pid;
    SELECT IFNULL(JSON_VALUE(@_node, "$.status"), 'active') INTO _status;
    CALL mfs_make_dir(_pid, JSON_ARRAY(_path), 0);
--    SELECT @_node, _pid, JSON_ARRAY(_path), _i, @_ex;
    SELECT _i + 1 INTO _i;
  END WHILE;
END$


DELIMITER ;