DELIMITER $

-- =======================================================================
-- mfs_new_node
-- =======================================================================
-- DROP PROCEDURE IF EXISTS `mfs_new_node`$
-- Replace mfs_new_node
DROP PROCEDURE IF EXISTS `mfs_create_node`$
CREATE PROCEDURE `mfs_create_node`(
  IN _attributes JSON,
  IN _metadata JSON,
  OUT _output JSON
)
BEGIN
  DECLARE _vhost VARCHAR(255);
  DECLARE _hub_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _area VARCHAR(50);
  DECLARE _home_dir VARCHAR(512);
  DECLARE _home_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _src_db_name VARCHAR(50);
  DECLARE _accessibility VARCHAR(20);

  DECLARE _fileid   VARCHAR(16) CHARACTER SET ascii DEFAULT '';
  DECLARE _ts   INT(11) DEFAULT 0;
  DECLARE _parent_id TEXT;
  DECLARE _root_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _parent_path TEXT;
  DECLARE _parent_name VARCHAR(100) DEFAULT '';
  DECLARE _filepath VARCHAR(1024);
  DECLARE _username VARCHAR(100);
  DECLARE _org VARCHAR(500);
  DECLARE _root_hub_id VARCHAR(16) CHARACTER SET ascii ;
  DECLARE _user_db_name VARCHAR(255);
  DECLARE _rollback BOOLEAN DEFAULT 0;

  DECLARE _origin_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _owner_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _fname VARCHAR(1024);
  DECLARE _pid VARCHAR(16) CHARACTER SET ascii;
  DECLARE _category VARCHAR(50);
  DECLARE _ext VARCHAR(100);
  DECLARE _mimetype VARCHAR(100);
  DECLARE _geometry VARCHAR(200);
  DECLARE _filesize BIGINT UNSIGNED;
  DECLARE _show BOOLEAN;
  DECLARE _isalink TINYINT(2) UNSIGNED DEFAULT 0;
  DECLARE _target JSON DEFAULT JSON_OBJECT();
  DECLARE _content JSON;

  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
  BEGIN
    SET _rollback = 1;  
    GET DIAGNOSTICS CONDITION 1 
      @sqlstate = RETURNED_SQLSTATE, 
      @errno = MYSQL_ERRNO, 
      @message = MESSAGE_TEXT;
  END;

  START TRANSACTION;

  SELECT JSON_VALUE(_attributes, "$.origin_id") INTO _origin_id;
  SELECT JSON_VALUE(_attributes, "$.owner_id") INTO _owner_id;
  SELECT JSON_VALUE(_attributes, "$.filename") INTO _fname;
  SELECT JSON_VALUE(_attributes, "$.pid") INTO _pid;
  SELECT JSON_VALUE(_attributes, "$.category") INTO _category;
  SELECT JSON_VALUE(_attributes, "$.ext") INTO _ext;
  SELECT JSON_VALUE(_attributes, "$.mimetype") INTO _mimetype;
  SELECT JSON_VALUE(_attributes, "$.geometry") INTO _geometry;
  SELECT JSON_VALUE(_attributes, "$.filesize") INTO _filesize;
  SELECT JSON_VALUE(_attributes, "$.isalink") INTO _isalink;
  SELECT JSON_VALUE(_attributes, "$.showResults") INTO _show;

  SELECT JSON_EXTRACT(_metadata, "$.content") INTO _content;
  SELECT JSON_EXTRACT(_metadata, "$.target") INTO _target;

  SELECT UNIX_TIMESTAMP() INTO _ts;
  SELECT yp.uniqueId() INTO _fileid;

  SELECT database() INTO _src_db_name;
  SELECT  h.id FROM yp.hub h INNER JOIN yp.entity e on e.id = h.id WHERE db_name=_src_db_name INTO _root_hub_id;
  SELECT '' INTO @xhub_name;

  IF _root_hub_id IS NOT NULL THEN
    SELECT db_name FROM yp.entity WHERE id = _owner_id INTO _user_db_name;
    IF _user_db_name IS NOT NULL THEN 
      SET @s = CONCAT("SELECT ", _user_db_name, ".filepath(?) INTO @xhub_name");
      PREPARE stmt FROM @s;
      EXECUTE stmt USING _root_hub_id;
      DEALLOCATE PREPARE stmt;
    END IF;
  END IF;

  SELECT username, link FROM yp.drumate d 
    INNER JOIN yp.organisation o ON o.domain_id = d.domain_id
    WHERE d.id=_owner_id INTO _username, _org;

  SELECT  home_dir from yp.entity WHERE  db_name=database() INTO  _home_dir ; 

  IF IFNULL(_pid, '0') IN('', '0') THEN 
    SELECT id FROM media WHERE parent_id='0' INTO  _pid;
  END IF;

  SELECT id, REGEXP_REPLACE(user_filename, '^[/ ]+|/+|\<.*\>|[/ ]+$', '') 
    FROM media WHERE id=_pid INTO _parent_id, _parent_name;

  IF _parent_id IS NULL OR _parent_id='' THEN 
    SELECT id FROM media m WHERE m.parent_id='0' INTO  _parent_id;
    -- UPDATE yp.entity SET home_layout=_parent_id WHERE db_name=database();
  END IF;
  
  SELECT COUNT(1) FROM media WHERE parent_id = _pid INTO @_count;

  SELECT parent_path(_parent_id) INTO _parent_path;
  SELECT REGEXP_REPLACE(_fname, '^[/ ]+|\<.*\>|[/ ]+$', '') INTO _fname;
  SELECT REGEXP_REPLACE(_fname, '( *)(/+)( *)', '') INTO _fname;
  SELECT unique_filename(_parent_id, _fname, _ext) INTO _fname;

  IF(_ext IS NULL OR _category IN('folder', 'hub', 'root') OR _ext IN('', 'root', 'folder')) THEN
    SELECT CONCAT(_parent_path, '/', _parent_name, '/', _fname)
    INTO _filepath;
    SELECT '' INTO _ext;
  ELSEIF (_category='hub') THEN
    SELECT _username INTO _ext;
  ELSE
    SELECT CONCAT(_parent_path, '/', _parent_name, '/', _fname, '.', _ext) INTO _filepath;
    SELECT IFNULL(category, _category), IFNULL(mimetype, _mimetype) 
      FROM yp.filecap WHERE extension=_ext INTO _category, _mimetype;
  END IF;

  SELECT clean_path(_filepath) INTO _filepath;
  IF _category NOT IN ('hub', 'folder') THEN 
    SELECT JSON_MERGE(_metadata, JSON_OBJECT(
      '_seen_', JSON_OBJECT(_owner_id, UNIX_TIMESTAMP())
    )) INTO _metadata;
  END IF; 

  IF _isalink THEN
    SELECT user_permission(_owner_id, _pid) INTO @privilege;
    SELECT JSON_SET(_target, "$.privilege", @privilege) INTO _target;
    SELECT JSON_SET(_metadata, "$.target", _target) INTO _metadata;
  END IF;

  IF JSON_VALUE(_content, "$.room_id") = "set-me" THEN
    SELECT JSON_SET(_content, "$.room_id", _fileid) INTO _content;
    SELECT JSON_SET(_metadata, "$.content", _content) INTO _metadata;
  END IF;
  INSERT INTO `media` (
    id, 
    origin_id, 
    owner_id,
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
    `metadata`,
    rank
  ) VALUES (
    _fileid, 
    IFNULL(_origin_id, _owner_id), 
    _owner_id,
    _filepath, 
    TRIM('/' FROM _fname),
    _pid, 
    _parent_path,
    _ext, 
    _mimetype, 
    _category, 
    IFNULL(_isalink, 0),
    IFNULL(_filesize, 4096),
    IFNULL(_geometry, '0x0'), 
    _ts, 
    _ts, 
    IF(_category='stylesheet', 'idle', 'active'),
    _metadata,
    @_count
  );

  SELECT JSON_OBJECT(
    "id", _fileid, 
    "nid", _fileid, 
    "pid", _pid, 
    "filepath", _filepath, 
    "parentpath", _parent_path,
    "timestamp", _ts, 
    "status", 'active',
    "count", @_count
  )  INTO _output;
  
  SET @perm = 0;

  UPDATE media SET parent_path=parent_path(_fileid) WHERE id=_fileid;

  IF IFNULL(_show, 0) != 0  THEN
    SELECT 
      m.id, 
      m.id as nid, 
      concat(_home_dir, "/__storage__/") AS mfs_root,
      parent_id AS pid,
      parent_id,
      e.id AS holder_id,
      e.home_id,
      e.home_dir,
      user_permission(_owner_id, m.id)  AS privilege,
      e.id AS owner_id,    
      e.id AS hub_id,    
      yp.vhost(e.id) AS vhost,    
      user_filename AS filename,
      file_path as ownpath,
      CONCAT(@xhub_name, file_path) as file_path,
      CONCAT(@xhub_name, file_path) as filepath,
      filesize,
      e.area,
      caption,
      e.accessibility,
      capability,
      m.extension,
      m.extension AS ext,
      m.category AS ftype,
      m.category AS filetype,
      m.mimetype,
      download_count AS view_count,
      geometry,
      upload_time AS ctime,
      publish_time AS mtime,
      firstname,
      lastname,
      m.category,
      user_filename,
      _username AS username,
      _org AS organization,
      parent_path,
      metadata,
      database() db_name
    FROM media m
      INNER JOIN yp.entity e  ON e.db_name=database()
      LEFT JOIN yp.drumate dr ON e.id = dr.id
      LEFT JOIN yp.domain d ON d.id = e.dom_id
      LEFT JOIN yp.filecap ff ON m.extension=ff.extension

      -- FROM media m LEFT JOIN (yp.filecap, yp.drumate) ON 
      -- m.extension=filecap.extension AND owner_id=yp.drumate.id 
      WHERE m.id = _fileid;
  END IF ;

  SELECT id FROM yp.entity WHERE db_name=database() INTO _hub_id;
  UPDATE yp.disk_usage SET size = (IFNULL(size,0) + IFNULL(_filesize,0)) WHERE hub_id = _hub_id;

  IF _rollback THEN
    ROLLBACK;
    SELECT 1 failed, 
      @sqlstate AS `sqlstate`,
      @errno AS `errno`,
      CONCAT(DATABASE(), ":", @message) AS `message`;
  ELSE
    COMMIT;
  END IF;
END $


DELIMITER ;