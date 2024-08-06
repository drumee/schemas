DELIMITER $
DROP PROCEDURE IF EXISTS `mfs_show_bin`$
CREATE PROCEDURE `mfs_show_bin`(
  IN _page TINYINT(4)
)
BEGIN
  DECLARE _hub_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _db_name VARCHAR(60) CHARACTER SET ascii;
  DECLARE _home_dir VARCHAR(300) CHARACTER SET ascii;
  DECLARE _home_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _range bigint;
  DECLARE _offset bigint;


  CALL pageToLimits(_page, _offset, _range);

  DROP TABLE IF EXISTS `_hubs`; 
  CREATE  TEMPORARY TABLE `_hubs` (
      hub_id varchar(16)  CHARACTER SET ascii DEFAULT NULL,
      db_name varchar(60)  CHARACTER SET ascii DEFAULT NULL,
      home_dir varchar(300)  CHARACTER SET ascii DEFAULT NULL,
      is_checked int default 0      
  );

  DROP TABLE IF EXISTS _bin_media;
  CREATE TEMPORARY TABLE _bin_media  AS
    SELECT
      m.id  AS nid,
      m.parent_id AS pid,
      m.parent_id AS parent_id,
      _home_id AS home_id,
      ff.capability,
      me.id AS owner_id,
      me.id AS hub_id,
      m.status AS status,
      m.user_filename AS filename,
      m.filesize AS filesize,
      yp.vhost(me.id) AS vhost,
      m.extension AS ext,
      m.category AS ftype,
      m.category AS filetype,
      m.mimetype,
      m.upload_time AS mtime,
      m.publish_time AS ctime
    FROM  trash_media m
      INNER JOIN yp.entity me  ON me.db_name=database()
      LEFT JOIN yp.filecap ff ON m.extension=ff.extension
    WHERE m.status='deleted';

  INSERT INTO _hubs
  SELECT id hub, db_name,home_dir,0 FROM 
  yp.entity WHERE id IN(
  SELECT id FROM media m INNER JOIN permission p 
  ON p.resource_id = m.id AND p.permission>=15 AND m.status='active' );

  SELECT hub_id,db_name,home_dir  FROM _hubs WHERE is_checked = 0 LIMIT 1 INTO _hub_id ,_db_name , _home_dir;
  WHILE  _hub_id IS NOT NULL DO 

    SET @sql = CONCAT(
      "INSERT INTO _bin_media (",
        "nid, pid, parent_id, home_id, capability, owner_id, hub_id, status, filename, filesize, vhost, ext, ftype,  filetype, mimetype, ctime, mtime) ", 
      "SELECT 
        m.id  AS nid,
        m.parent_id AS pid,
        m.parent_id AS parent_id,
        me.home_id AS home_id,
        ff.capability,
        me.id AS owner_id,
        me.id AS hub_id,
        m.status AS status,
        m.user_filename AS filename,
        m.filesize AS filesize,
        yp.vhost(me.id) AS vhost,
        m.extension AS ext,
        m.category AS ftype,
        m.category AS filetype,
        m.mimetype,
        m.upload_time AS ctime,
        m.publish_time AS mtime
      FROM ", _db_name, ".trash_media m
        INNER JOIN yp.entity me ON me.db_name=", QUOTE(_db_name),"
        LEFT JOIN yp.filecap ff ON m.extension=ff.extension
      WHERE m.status='deleted'"
    );

    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;       
    
    UPDATE _hubs SET is_checked = 1 WHERE _hub_id =hub_id;
    SELECT NULL,NULL,NULL INTO _hub_id ,_db_name , _home_dir;
    SELECT hub_id,db_name,home_dir  FROM _hubs WHERE is_checked = 0 LIMIT 1 INTO _hub_id ,_db_name , _home_dir;
  END WHILE;

  IF _offset < 0 THEN 
    SELECT * FROM _bin_media WHERE filename!='__trash__' ORDER BY ctime DESC;
  ELSE
    SELECT *, _page AS page FROM _bin_media WHERE filename!='__trash__' 
      ORDER BY ctime, filename DESC LIMIT _offset, _range;
  END IF;

  DROP TABLE IF EXISTS _bin_media;

END $



DELIMITER ;