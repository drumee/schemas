DELIMITER $

-- ===============================================
DROP PROCEDURE IF EXISTS `mfs_manifest`$
CREATE PROCEDURE `mfs_manifest`(
  IN _nid VARCHAR(16),
  IN _uid VARCHAR(16),
  IN _show_nodes TINYINT
)
BEGIN
  DECLARE _filepath TEXT DEFAULT NULL;
  DECLARE _db_name VARCHAR(80) DEFAULT NULL;
  DECLARE _home_dir VARCHAR(2000) DEFAULT NULL;
  DECLARE _eid VARCHAR(16) DEFAULT NULL;
  DECLARE _owner_id VARCHAR(16) DEFAULT NULL;
  DECLARE _home_id VARCHAR(16) DEFAULT NULL;
  DECLARE _name VARCHAR(80) DEFAULT NULL;

  DROP TABLE IF EXISTS __tmp_manifest;
  SELECT e.home_dir, e.home_id, e.id, COALESCE(h.name, d.fullname), 
    COALESCE(h.owner_id, d.id)  FROM yp.entity e
    LEFT JOIN yp.hub h ON e.id = h.id AND e.type='hub'
    LEFT JOIN yp.drumate d ON e.id = d.id AND e.type='drumate'
    WHERE e.db_name=database() INTO _home_dir, _home_id, _eid, _name, _owner_id;

  CREATE TEMPORARY TABLE __tmp_manifest AS SELECT 
    id, 
    _owner_id AS owner_id,
    _home_dir AS home_dir, 
    _home_id AS home_id, 
    _eid AS hub_id, 
    file_path as filepath, 
    parent_id AS pid, 
    status, 
    filesize,
    user_filename, 
    extension, 
    isalink,
    upload_time AS ctime,
    publish_time AS mtime,
    metadata,
    0 AS privilege,
    category
  FROM media where 1=2;
  ALTER TABLE __tmp_manifest ADD sys_id INT PRIMARY KEY AUTO_INCREMENT;
  ALTER TABLE __tmp_manifest ADD ownpath VARCHAR(2000) AFTER filepath;
  ALTER TABLE __tmp_manifest ADD UNIQUE KEY `hub_id` (`id`, `hub_id`);
  REPLACE INTO __tmp_manifest
    WITH RECURSIVE __parent_tree AS
    (
      SELECT
        m.id, 
        _owner_id,
        _home_dir AS home_dir, 
        IF(m.category = 'hub', (SELECT home_id FROM yp.entity e WHERE e.id=m.id), _home_id ) home_id,
        _eid AS hub_id,
        m.file_path,
        m.file_path  AS ownpath,
        m.parent_id,
        m.status, 
        m.filesize,
        m.user_filename, 
        m.extension, 
        m.isalink,
        m.upload_time AS ctime,
        m.publish_time AS mtime,
        m.metadata,
        user_permission(_uid, m.id ) privilege,
        m.category, 
        null
      FROM
        media m
        WHERE m.id = _nid 
        AND  m.status IN('active', 'locked')
      UNION ALL
        SELECT
        m.id, 
        _owner_id,
        _home_dir AS home_dir, 
        IF(m.category = 'hub', (SELECT home_id FROM yp.entity e WHERE e.id=m.id), _home_id ) home_id,
        _eid AS hub_id,
        m.file_path,
        m.file_path AS ownpath,
        m.parent_id,
        m.status, 
        m.filesize,
        m.user_filename, 
        m.extension, 
        m.isalink,
        m.upload_time AS ctime,
        m.publish_time AS mtime,
        m.metadata,
        user_permission(_uid, m.id ) privilege,
        m.category,
        null
      FROM
        media AS m
      INNER JOIN __parent_tree AS t ON m.parent_id = t.id AND 
        t.category IN('folder',  'root') AND  m.status IN('active', 'locked')
    )
    SELECT * FROM __parent_tree ;

  BEGIN
    DECLARE _finished INTEGER DEFAULT 0;
    DECLARE dbcursor CURSOR FOR SELECT e.id, e.home_dir, filepath,
      db_name FROM __tmp_manifest m
      INNER JOIN (yp.entity e, permission p) ON m.id=e.id AND p.resource_id=m.id 
      WHERE m.category='hub' AND 
      JSON_VALUE(e.settings, "$.syncForbiden") IS NULL AND
      permission&2;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET _finished = 1; 
    OPEN dbcursor;
      STARTLOOP: LOOP
        FETCH dbcursor INTO _eid, _home_dir, _filepath, _db_name;
        IF _finished = 1 THEN 
          LEAVE STARTLOOP;
        END IF;  

        SELECT COALESCE(h.owner_id, d.id), e.home_id FROM yp.entity e
          LEFT JOIN yp.hub h ON e.id = h.id AND e.type='hub'
          LEFT JOIN yp.drumate d ON e.id = d.id AND e.type='drumate'
          WHERE e.db_name=_db_name INTO _owner_id, _home_id;

        -- SET @s = CONCAT("REPLACE INTO __tmp_manifest SELECT id, ", 
        --   QUOTE(_owner_id),
        --   ",",
        --   QUOTE(_home_dir),
        --   ",",
        --   QUOTE(_home_id),
        --   ",",
        --   QUOTE(_eid),
        --   ", CONCAT(", QUOTE(_filepath), ", file_path), 
        --   file_path,
        --   parent_id, 
        --   status, 
        --   filesize, 
        --   user_filename, 
        --   extension, 
        --   isalink,
        --   upload_time AS ctime,
        --   publish_time AS mtime,
        --   metadata,",
        --   _db_name, ".user_permission(", QUOTE(_uid), ", id ) AS privilege,
        --   category, null FROM ", 
        --   _db_name, ".media WHERE extension !='root' AND status IN('active', 'locked')", 
        --   " AND NOT file_path REGEXP '(/__trash__/|/__chat__/)'");
        SET @s = CONCAT(
          "REPLACE INTO __tmp_manifest SELECT id, ?, ?, ?, ?, CONCAT(?, file_path), ", 
          "file_path, parent_id, status, filesize, user_filename, extension, isalink, 
          upload_time AS ctime, publish_time AS mtime, metadata,",
          _db_name, ".user_permission(?, id ) AS privilege, category, null FROM ", 
          _db_name, ".media WHERE extension !='root' AND status IN('active', 'locked')", 
          " AND NOT file_path REGEXP '(/__trash__/|/__chat__/)'");
        -- SELECT @s;
        IF @s IS NOT NULL THEN 
          PREPARE stmt FROM @s;
          EXECUTE stmt USING _owner_id, _home_dir, _home_id, _eid, _filepath, _uid;
          DEALLOCATE PREPARE stmt;
        END IF;

       END LOOP STARTLOOP;
    CLOSE dbcursor;
  END;

  IF _show_nodes > 0 THEN 
    SELECT 
      id AS nid, 
      owner_id,
      REGEXP_REPLACE(home_dir, '^/+', '') AS home_dir, 
      home_id,
      REGEXP_REPLACE(filepath, '/+', '/') filepath, 
      REGEXP_REPLACE(ownpath, '/+', '/') ownpath, 
      IF(m.category='hub', id, hub_id) AS hub_id,
      status, 
      filesize, 
      IFNULL(REGEXP_REPLACE(user_filename, '<.*\>', ''), _name) AS filename, 
      -- parent_path,
      pid,
      m.extension AS ext, 
      isalink,
      ctime,
      if(mtime < ctime, ctime, mtime) AS mtime,
      JSON_VALUE(metadata, "$.md5Hash") AS md5Hash,
      privilege,
      COALESCE(fc.category, m.category) filetype
    FROM __tmp_manifest m 
      LEFT JOIN yp.filecap fc ON m.extension=fc.extension
      WHERE NOT filepath REGEXP '(/__trash__/|/__chat__/)' AND
        m.category NOT IN('root') AND home_id IS NOT NULL;
  END IF;

  SELECT sum(filesize) AS total_size FROM __tmp_manifest;
  SELECT IF(user_filename = '' OR user_filename IS NULL, _name, user_filename) AS filename 
    FROM media WHERE id=_nid;
  SELECT count(*) AS amount, sum(filesize) AS size_per_type, category 
    FROM __tmp_manifest WHERE owner_id = _uid AND category NOT IN('root', 'folder') 
    GROUP BY category;
  SELECT sum(filesize) AS used_size FROM __tmp_manifest 
    WHERE owner_id = _uid AND category NOT IN('root', 'folder');

  DROP TABLE IF EXISTS __tmp_manifest;
END$

DELIMITER ;
