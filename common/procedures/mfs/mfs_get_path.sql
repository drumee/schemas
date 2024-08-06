DELIMITER $
DROP PROCEDURE IF EXISTS `mfs_get_path`$
CREATE PROCEDURE `mfs_get_path` (
  IN _id VARCHAR(16)
)
DETERMINISTIC
BEGIN
  DECLARE _nid VARCHAR(16);
  DECLARE _pid VARCHAR(16);
  DECLARE _fname VARCHAR(255);
  DECLARE _ppath VARCHAR(600);
  DECLARE _vhost VARCHAR(255);
  DECLARE _hub_id VARCHAR(16);
  DECLARE _area VARCHAR(50);
  DECLARE _home_dir VARCHAR(512);
  DECLARE _home_id VARCHAR(16);
  DECLARE _db_name VARCHAR(50);
  DECLARE _accessibility VARCHAR(16);
  DECLARE _ext varchar(50);  
 
  -- DECLARE _chat_upload_id VARCHAR(16);

  -- CALL mediaEnv(_vhost, _hub_id, _area, _home_dir, _home_id, _db_name, _accessibility);
  -- SELECT node_id_from_path('/__chat__/__upload__') INTO _chat_upload_id;

  SELECT e.id, e.area, e.home_dir, m.id, e.db_name, e.accessibility from media m 
    INNER JOIN yp.entity e  ON e.db_name=database()
    WHERE parent_id='0' 
    INTO _hub_id, _area, _home_dir, _home_id, _db_name, _accessibility;

  DROP TABLE IF EXISTS  __media_path;  
  CREATE TEMPORARY TABLE `__media_path` (
    hub_id varchar(16) DEFAULT NULL,
    home_id varchar(16) DEFAULT NULL,
    nid varchar(16) DEFAULT NULL, 
    pid varchar(16) DEFAULT NULL, 
    filename varchar(1024) DEFAULT NULL, 
    parent_path varchar(1024) DEFAULT NULL,
    ext varchar(50) DEFAULT NULL,  
    area varchar(50) DEFAULT NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8;   

  SELECT m.id, m.parent_id, m.user_filename, m.parent_path,
    m.extension AS ext,
    IF(m.category='hub', m.extension, me.area)
    FROM media m
    INNER JOIN yp.entity me  ON me.db_name=database()
  WHERE m.id=_id INTO _nid, _pid, _fname, _ppath, _ext,_area;

  INSERT INTO __media_path 
    SELECT _hub_id, _home_id, _nid, _pid, _fname, _ppath,_ext,_area FROM media WHERE id=_id;

  WHILE _pid != "0" DO
    SELECT m.id, m.parent_id, m.user_filename, m.parent_path,
    m.extension AS ext,
    IF(m.category='hub', m.extension, me.area)
    FROM media m  
    INNER JOIN yp.entity me  ON me.db_name=database()
  WHERE m.id=_pid INTO _nid, _pid, _fname, _ppath, _ext,_area ;

  INSERT INTO __media_path SELECT _hub_id, _home_id, _nid, _pid, _fname, _ppath,_ext,_area;
  END WHILE;


  -- ALTER table __media_path ADD  chat_upload_id varchar(16) DEFAULT NULL;
  -- UPDATE __media_path SET chat_upload_id = _chat_upload_id;

  SELECT * FROM __media_path;
END$


DELIMITER ;


