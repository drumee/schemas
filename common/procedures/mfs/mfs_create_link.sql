DELIMITER $

DROP PROCEDURE IF EXISTS `mfs_create_link`$
CREATE PROCEDURE `mfs_create_link`(
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

  SELECT e.id, home_dir, fqdn FROM yp.entity e INNER JOIN yp.vhost v on e.id = v.id 
    WHERE db_name=DATABASE() 
  INTO _src_id, _src_home_dir, _src_vhost;

  SELECT db_name FROM yp.entity WHERE id = _recipient_id INTO _dest_db;

  SELECT id, origin_id, user_filename, metadata,`status`, category,
    extension, mimetype, `geometry`, filesize 
  FROM media WHERE id =_nid 
  INTO _id, _origin_id, _file_name, _metadata,_status, _category,
    _extension, _mimetype, _geometry, _file_size;   
 
  SELECT id FROM media WHERE parent_id = '0' INTO _src_home_id;   
 
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

  IF _dest_db IS NOT NULL THEN 
    SET @st = CONCAT("CALL ", _dest_db, ".mfs_create_node(?, ?, @results)");
    PREPARE stmt2 FROM @st;
    EXECUTE stmt2 USING @args, @metadata;
    DEALLOCATE PREPARE stmt2;
  ELSE
    SELECT 1 failed, "Empty destination" reason;
  END IF;

END $

DELIMITER ;














-- -- Register happen only in destination 
-- DROP PROCEDURE IF EXISTS `mfs_register_tree`$

DELIMITER ;

 ---  CALL mfs_create_link_by ( 'dfad3f03dfad3f0f','46fb4fc946fb4fce' ,'ebf7e640ebf7e653','46fb4fc946fb4fce');

