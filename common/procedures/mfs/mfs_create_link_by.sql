DELIMITER $

DROP PROCEDURE IF EXISTS `mfs_create_link_by`$
CREATE PROCEDURE `mfs_create_link_by`(
  IN _nid VARCHAR(16),
  IN _uid VARCHAR(16),
  IN _dest_id VARCHAR(16),
  IN _recipient_id VARCHAR(16)
)
BEGIN

  DECLARE _is_root tinyint(2) ;
  DECLARE _origin_id      VARCHAR(16);
  DECLARE _file_name      VARCHAR(512);
  DECLARE _metadata       JSON;
  DECLARE _category       VARCHAR(50);
  DECLARE _extension      VARCHAR(100);
  DECLARE _mimetype       VARCHAR(100);
  DECLARE _file_size      INT(20) UNSIGNED;
  DECLARE _geometry       VARCHAR(200);
  DECLARE _status         VARCHAR(50);
  DECLARE _finished       INTEGER DEFAULT 0;
  DECLARE _seq            INTEGER;
  DECLARE _id             VARCHAR(16);
  DECLARE _dest_db VARCHAR(50);
  DECLARE _src_id VARCHAR(50);
  DECLARE _src_vhost VARCHAR(1000);
  DECLARE _src_home_dir VARCHAR(1000);
  DECLARE _src_home_id VARCHAR(16);
  DECLARE _sys_id INT;
  DECLARE _temp_sys_id INT;

  SELECT e.id, home_dir, fqdn FROM yp.entity e INNER JOIN yp.vhost v on e.id = v.id
  WHERE db_name=DATABASE()
  INTO _src_id, _src_home_dir, _src_vhost;

  SELECT db_name FROM yp.entity WHERE id = _recipient_id INTO _dest_db;

  SELECT id FROM media WHERE parent_id = '0' INTO _src_home_id;


 DROP TABLE IF EXISTS  _src_media;
  CREATE TEMPORARY TABLE _src_media (
    `sys_id`  int NOT NULL AUTO_INCREMENT,
    `id` varchar(16) DEFAULT NULL,
    PRIMARY KEY `sys_id`(`sys_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8;


  INSERT INTO _src_media SELECT null, id from media
    WHERE parent_id = _nid AND category NOT IN ('hub', 'folder') ;
  SELECT sys_id , id  FROM _src_media WHERE sys_id > 0  ORDER BY sys_id ASC LIMIT 1
    INTO _sys_id ,  _nid;


  WHILE _sys_id <> 0 DO


    SELECT id, origin_id, user_filename, metadata,`status`, category,
      extension, mimetype, `geometry`, filesize
    FROM media WHERE id =_nid
    INTO _id, _origin_id, _file_name, _metadata,_status, _category,
      _extension, _mimetype, _geometry, _file_size;

    SET @args = JSON_OBJECT(
      "owner_id", _uid,
      "origin_id", _origin_id,
      "filename",_file_name,
      "pid", _dest_id,
      "category", _category,
      "ext", _extension,
      "mimetype", _mimetype,
      "filesize", 0,
      "geometry", _geometry,
      "isalink", 1
    );

    SET @results = JSON_OBJECT();
    SET @metadata = JSON_OBJECT('target',
      JSON_OBJECT(
        'nid', _nid,
        'hub_id', _src_id,
        'home_id', _src_home_id,
        'vhost', _src_vhost,
        'privilege', @privilege
      )
    );
    SET @st = CONCAT("CALL ", _dest_db, ".mfs_create_node(?, ?, @results)");

    PREPARE stmt2 FROM @st;
    EXECUTE stmt2 USING @args, @metadata;
    DEALLOCATE PREPARE stmt2;

    SELECT JSON_VALUE(@results, "$.id") INTO @temp_nid;
    SELECT JSON_VALUE(@results, "$.pid") INTO @pid;

    SET @st = CONCAT( "SELECT ", _dest_db, ".user_permission(?, ?) INTO @privilege");

    PREPARE stmt3 FROM @st;
    EXECUTE stmt3 USING _uid, @temp_nid;
    DEALLOCATE PREPARE stmt3;

    SELECT _sys_id INTO  _temp_sys_id ;
    SELECT 0 , NULL INTO  _sys_id, _nid ;
    SELECT sys_id , id  FROM _src_media WHERE sys_id > _temp_sys_id  ORDER BY sys_id ASC LIMIT 1
      INTO _sys_id , _nid;
  END WHILE;


  -- SELECT @st;

END $
DELIMITER ;
