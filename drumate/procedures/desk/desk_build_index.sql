DELIMITER $

-- ===============================================
DROP PROCEDURE IF EXISTS `desk_build_index`$
CREATE PROCEDURE `desk_build_index`(
  IN _args JSON
)
BEGIN
  DECLARE _filepath TEXT DEFAULT NULL;
  DECLARE _db_name VARCHAR(80) DEFAULT NULL;
  DECLARE _home_dir VARCHAR(2000) DEFAULT NULL;
  DECLARE _uid VARCHAR(16) DEFAULT NULL;
  DECLARE _eid VARCHAR(16) DEFAULT NULL;
  DECLARE _owner_id VARCHAR(16) DEFAULT NULL;
  DECLARE _home_id VARCHAR(16) DEFAULT NULL;
  DECLARE _actual_home_id VARCHAR(16) DEFAULT NULL;
  DECLARE _name VARCHAR(80) DEFAULT NULL;
  DECLARE _ts INT(11) UNSIGNED;

  SELECT e.home_dir, e.home_id, e.id, COALESCE(h.name, d.fullname), 
    COALESCE(h.owner_id, d.id)  FROM yp.entity e
    LEFT JOIN yp.hub h ON e.id = h.id AND e.type='hub'
    LEFT JOIN yp.drumate d ON e.id = d.id AND e.type='drumate'
    WHERE e.db_name=database() INTO _home_dir, _home_id, _uid, _name, _owner_id;

  DROP TEMPORARY TABLE IF EXISTS _tmp_manifest;
  CREATE TEMPORARY TABLE `_tmp_manifest` (
    `id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
    `home_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
    `actual_home_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
    `hub_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
    `filepath` varchar(2000) DEFAULT "/",
    `ownpath` varchar(2000) DEFAULT "/",
    `pid` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
    `status` varchar(20) NOT NULL DEFAULT 'active',
    `filesize` bigint(20) unsigned DEFAULT 0,
    `user_filename` varchar(128) DEFAULT NULL,
    `extension` varchar(100) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
    `isalink` tinyint(2) unsigned NOT NULL DEFAULT 0,
    `ctime` int(11) unsigned DEFAULT 0,
    `mtime` int(11) unsigned DEFAULT 0,
    `metadata` JSON,
    `privilege` int(2) DEFAULT 0,
    `area` varchar(9) DEFAULT "",
    `category` varchar(16) NOT NULL DEFAULT 'other',
    PRIMARY KEY (`id`,`hub_id`),
    UNIQUE KEY `filepath` (`filepath`)
  );

  REPLACE INTO _tmp_manifest
    WITH RECURSIVE __parent_tree AS
    (
      SELECT
        m.id, 
        _home_id,
        IF(m.category = 'hub', (SELECT home_id FROM yp.entity e WHERE e.id=m.id), _home_id),
        _uid AS hub_id,
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
        IF(m.category = 'hub', (SELECT area FROM yp.entity e WHERE e.id=m.id), "" ),
        m.category
      FROM
        media m
        WHERE m.id = _home_id 
        AND  m.status IN('active', 'locked')
      UNION ALL
        SELECT
        m.id, 
        _home_id,
        IF(m.category = 'hub', (SELECT home_id FROM yp.entity e WHERE e.id=m.id), _home_id ) home_id,
        _uid AS hub_id,
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
        IF(m.category = 'hub', (SELECT area FROM yp.entity e WHERE e.id=m.id), "" ),
        m.category
      FROM
        media AS m
      INNER JOIN __parent_tree AS t ON m.parent_id = t.id AND 
        t.category IN('folder',  'root') AND  m.status IN('active', 'locked')
    )
    SELECT * FROM __parent_tree ;

  BEGIN
    DECLARE _finished INTEGER DEFAULT 0;
    DECLARE dbcursor CURSOR FOR SELECT e.id, filepath, db_name FROM _tmp_manifest m
      INNER JOIN (yp.entity e, permission p) ON m.id=e.id AND p.resource_id=m.id 
      WHERE m.category='hub' AND permission&2;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET _finished = 1; 
    OPEN dbcursor;
      STARTLOOP: LOOP
        FETCH dbcursor INTO _eid, _filepath, _db_name;
        IF _finished = 1 THEN 
          LEAVE STARTLOOP;
        END IF;  

        SELECT e.home_id FROM yp.entity e
          INNER JOIN yp.hub h ON e.id = h.id
          WHERE e.db_name=_db_name INTO _actual_home_id;

        SET @s = CONCAT(
          "REPLACE INTO _tmp_manifest SELECT id, ?, ?, ?, CONCAT(?, file_path), ", 
          "file_path, parent_id, status, filesize, user_filename, extension, isalink, 
          upload_time AS ctime, publish_time AS mtime, metadata,",
          _db_name, ".user_permission(?, id ) AS privilege, '', category FROM ", 
          _db_name, ".media WHERE extension !='root' AND status IN('active', 'locked')");
        -- SELECT @s;
        IF @s IS NOT NULL THEN 
          PREPARE stmt FROM @s;
          EXECUTE stmt USING _home_id, _actual_home_id, _eid, _filepath, _uid;
          DEALLOCATE PREPARE stmt;
        END IF;

       END LOOP STARTLOOP;
    CLOSE dbcursor;
  END;

  SELECT UNIX_TIMESTAMP() INTO _ts;
  REPLACE INTO media_index SELECT 
      IF(m.category='hub', id, hub_id) AS hub_id,
      home_id,
      actual_home_id,
      pid,
      id AS nid, 
      JSON_VALUE(metadata, "$.md5Hash") AS md5Hash,
      m.area,
      m.category,
      m.extension AS ext, 
      status, 
      m.isalink,
      privilege,
      filesize, 
      IFNULL(REGEXP_REPLACE(user_filename, '<.*\>', ''), _name) AS filename, 
      REGEXP_REPLACE(filepath, '/+', '/') filepath, 
      REGEXP_REPLACE(ownpath, '/+', '/') ownpath, 
      if(mtime < ctime, ctime, mtime) AS mtime,
      ctime,
      _ts
    FROM _tmp_manifest m 
      LEFT JOIN yp.filecap fc ON m.extension=fc.extension
      WHERE NOT filepath REGEXP '(/__trash__/|/__chat__/)' AND
        m.category NOT IN('root') AND home_id IS NOT NULL;

  -- DROP TEMPORARY TABLE IF EXISTS _tmp_manifest;
END$

DELIMITER ;
