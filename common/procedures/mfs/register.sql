-- DELIMITER $

-- =======================================================================
-- mfs_register
-- =======================================================================
-- DROP PROCEDURE IF EXISTS `mfs_register_node`$
-- DROP PROCEDURE IF EXISTS `mfs_register`$
-- CREATE PROCEDURE `mfs_register`(
--   IN _origin_id       VARCHAR(16),
--   IN _user_filename   VARCHAR(512),
--   IN _pid             VARCHAR(20),
--   IN _category        VARCHAR(50),
--   IN _extension       VARCHAR(100),
--   IN _mimetype        VARCHAR(100),
--   IN _geometry        VARCHAR(200),
--   IN _file_size       INT(20) UNSIGNED,
--   IN _show_results    BOOLEAN
-- )
-- BEGIN
--   DECLARE _vhost VARCHAR(255);
--   DECLARE _hub_id VARCHAR(16);
--   DECLARE _area VARCHAR(50);
--   DECLARE _home_dir VARCHAR(512);
--   DECLARE _home_id VARCHAR(16);
--   DECLARE _src_db_name VARCHAR(50);
--   DECLARE _accessibility VARCHAR(20);

--   DECLARE _fileid   VARCHAR(16) DEFAULT '';
--   DECLARE _ts   INT(11) DEFAULT 0;
--   DECLARE _parent_id TEXT;
--   DECLARE _root_id VARCHAR(16);
--   DECLARE _parent_path TEXT;
--   DECLARE _parent_name VARCHAR(100) DEFAULT '';
--   DECLARE _file_path   VARCHAR(1024);
--   DECLARE _file_name VARCHAR(1024);

--   SELECT UNIX_TIMESTAMP() INTO _ts;
--   SELECT yp.uniqueId() INTO _fileid;

--   CALL mediaEnv(_vhost, _hub_id, _area, _home_dir, _home_id, _src_db_name, _accessibility);

--   IF IFNULL(_pid, '0') IN('', '0') THEN 
--     SELECT id FROM media WHERE parent_id='0' INTO  _pid;
--   END IF;

--   SELECT id, TRIM('/' FROM user_filename) FROM media WHERE id=_pid 
--     INTO _parent_id, _parent_name;
--   IF _parent_id IS NULL OR _parent_id='' THEN 
--     SELECT id FROM media m WHERE m.parent_id='0' INTO  _parent_id;
--     -- UPDATE yp.entity SET home_layout=_parent_id WHERE db_name=database();
--   END IF;
  

--   SELECT COUNT(*) FROM media WHERE parent_id = _pid INTO @_count;

--   SELECT parent_path(_parent_id) INTO _parent_path;
--   SELECT REPLACE(_user_filename, CONCAT('.', _extension), '') INTO _file_name;
--   SELECT unique_filename(_parent_id, _file_name, _extension) INTO _file_name;
--   SELECT CONCAT(_parent_path, '/', _parent_name, '/', _file_name, '.', _extension) 
--     INTO _file_path;
-- --  SELECT _pid, @fn;

--   INSERT INTO `media` (
--     id, 
--     origin_id, 

--     file_path, 
--     user_filename, 
--     parent_id, 
--     parent_path,

--     extension, 
--     mimetype, 
--     category,
--     isalink,

--     filesize, 
--     `geometry`, 
--     publish_time, 
--     upload_time, 

--     `status`,
--     rank
--   ) VALUES (
--     _fileid, 
--     _origin_id, 

--     clean_path(_file_path), 
--     TRIM('/' FROM _file_name),
--     _pid, 
--     _parent_path,

--     _extension, 
--     _mimetype, 
--     _category, 
--     0,

--     IFNULL(_file_size, 4096),
--     IFNULL(_geometry, '0x0'), 
--     _ts, 
--     _ts, 

--     IF(_category='stylesheet', 'idle', 'active'),
--     @_count
--   );
--   -- insert as results for multi rows copy
--   -- copy_tree shall retrieve copied rows in the table
--   DROP TABLE IF EXISTS __register_stack;
--   CREATE TEMPORARY TABLE __register_stack LIKE template.tmp_media;
--   INSERT INTO __register_stack VALUES (
--     _fileid, 
--     _origin_id, 

--     clean_path(_file_path), 
--     _file_name,
--     _pid, 
--     _parent_path,

--     _extension, 
--     _mimetype, 
--     _category, 
--     0,

--     IFNULL(_file_size, 4096),
--     IFNULL(_geometry, '0x0'), 
--     _ts, 
--     _ts, 

--     'active',
--     @_count
--   );

--   SET @perm = 0;
--   SET @s = CONCAT(
--     "SELECT " ,_src_db_name,".user_permission (", 
--     QUOTE(_origin_id),",",QUOTE(_fileid), ") INTO @perm");
--   PREPARE stmt FROM @s;
--   EXECUTE stmt;
--   DEALLOCATE PREPARE stmt;   

--   IF _category NOT IN ('hub', 'folder') THEN 
--     UPDATE media SET metadata=JSON_MERGE(
--       IFNULL(metadata, '{}'), 
--       JSON_OBJECT('_seen_', JSON_OBJECT(_origin_id, 1))
--     )
--     WHERE id=_fileid;
--   END IF; 

--   IF IFNULL(_show_results, 0) != 0  THEN
--     SELECT 
--       m.id, 
--       m.id as nid, 
--       concat(_home_dir, "/__storage__/") AS mfs_root,
--       parent_id AS pid,
--       parent_id,
--       _hub_id AS holder_id,
--       _home_id AS home_id,
--       _home_dir AS home_dir,
--       @perm  AS privilege,
--       _hub_id AS owner_id,    
--       _hub_id AS hub_id,    
--       _vhost AS vhost,    
--       user_filename AS filename,
--       filesize,
--       _area AS area,
--       caption,
--       _accessibility AS accessibility,
--       capability,
--       m.extension,
--       m.extension AS ext,
--       m.category AS ftype,
--       m.category AS filetype,
--       m.mimetype,
--       download_count AS view_count,
--       geometry,
--       upload_time AS ctime,
--       publish_time AS ptime,
--       firstname,
--       lastname,
--       m.category,
--       user_filename,
--       file_path, 
--       parent_path
--       FROM media m LEFT JOIN (yp.filecap, yp.drumate) ON 
--       m.extension=filecap.extension AND origin_id=yp.drumate.id 
--       WHERE m.id = _fileid;
--   END IF ;

--   IF(SELECT count(*) FROM yp.disk_usage where hub_id=_hub_id) > 0 THEN 
--     UPDATE yp.disk_usage SET size = (size + _file_size) WHERE hub_id = _hub_id;
--   ELSE 
--     INSERT INTO yp.disk_usage VALUES(null, _hub_id, _file_size);
--   END IF;

-- END $


-- DELIMITER ;