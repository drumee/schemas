DELIMITER $
-- ==============================================================
-- Move node inside same hub
-- ==============================================================
-- DROP PROCEDURE IF EXISTS `mfs_move_node`$
DROP PROCEDURE IF EXISTS `mfs_move`$
CREATE PROCEDURE `mfs_move`(
  IN _nid VARCHAR(16),
  IN _pid VARCHAR(16)
)
BEGIN
  DECLARE _src_type VARCHAR(100);
  DECLARE _des_type VARCHAR(100);
  DECLARE _file_name VARCHAR(1024);
  DECLARE _file_path VARCHAR(1024);
  DECLARE _extension VARCHAR(100);
  DECLARE _parent_name VARCHAR(1024);
  DECLARE _parent_path VARCHAR(1024);
  DECLARE _hub_id VARCHAR(16);
  DECLARE _area VARCHAR(50);
  DECLARE _home_dir VARCHAR(512);
  DECLARE _home_id VARCHAR(16);
  DECLARE _src_db_name VARCHAR(50);
  DECLARE _accessibility VARCHAR(16);

  SELECT COUNT(*) FROM media WHERE parent_id = _pid INTO @_count;
  SELECT category, TRIM('/' FROM user_filename) FROM media 
    WHERE id=_pid INTO _des_type, _parent_name;

  SELECT TRIM('/' FROM user_filename), category, extension FROM media WHERE id=_nid 
    INTO _file_name, _src_type, _extension;

  SELECT e.id, e.area, e.home_dir, m.id, e.db_name, e.accessibility from media m 
    INNER JOIN yp.entity e  ON e.db_name=database()
    WHERE parent_id='0' 
    INTO _hub_id, _area, _home_dir, _home_id, _src_db_name, _accessibility;

  -- CALL mediaEnv(
  --   @_vhost, _hub_id, _area, _home_dir, _home_id, _src_db_name, _accessibility);

  IF _des_type='folder' THEN   
    SELECT clean_path(parent_path(_pid)) INTO _parent_path;
    SELECT unique_filename(_pid, _file_name, _extension) INTO _file_name;
    SELECT clean_path(CONCAT(
      _parent_path, '/', _parent_name, '/', _file_name, '.', _extension
      ))INTO _file_path;

    SELECT REPLACE(file_path, CONCAT('.', extension), "/%")
      FROM media WHERE id=_nid INTO @_src_pattern;
    SELECT REPLACE(file_path, CONCAT('.', extension), "/%")
      FROM media WHERE id=_pid INTO @_des_pattern;

    UPDATE media SET parent_id = _pid , rank=@_count WHERE id = _nid;
    UPDATE media SET parent_path = parent_path(_nid) WHERE id = _nid;
    UPDATE media SET file_path = CONCAT(parent_path, '/', user_filename, '.', extension) 
      WHERE id = _nid;
    IF _src_type='folder' THEN
      UPDATE media m SET parent_path=parent_path(m.id) WHERE file_path LIKE @_src_pattern;
      UPDATE media m set file_path=concat(parent_path, '/', m.user_filename, '.', extension)
        WHERE file_path LIKE @_des_pattern;
    END IF;
    IF _src_type='hub' THEN
      SELECT area FROM yp.entity WHERE id = _nid INTO _area;
    END IF;
  END IF;

  SELECT 
    m.id, 
    m.id as nid, 
    concat(_home_dir, "/__storage__/") AS mfs_root,
    parent_id AS pid,
    parent_id,
    _hub_id AS holder_id,
    _home_id AS home_id,
    _home_dir AS home_dir,
    @perm  AS privilege,
    _hub_id AS owner_id,    
    _hub_id AS hub_id,    
    yp.vhost(_hub_id) AS vhost,    
    _area AS area,
    _accessibility AS accessibility,
    user_filename AS filename,
    filesize,
    caption,
    capability,
    m.extension,
    m.extension AS ext,
    m.category AS ftype,
    m.category AS filetype,
    m.mimetype,
    download_count AS view_count,
    geometry,
    upload_time AS mtime,
    publish_time AS ctime,
    firstname,
    lastname,
    m.category,
    user_filename,
    file_path, 
    parent_path
    FROM media m LEFT JOIN (yp.filecap, yp.drumate) ON 
    m.extension=filecap.extension AND origin_id=yp.drumate.id 
  WHERE m.id = _nid;
END $

DELIMITER ;