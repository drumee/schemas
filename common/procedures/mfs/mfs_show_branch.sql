DELIMITER $
DROP PROCEDURE IF EXISTS `mfs_tree`$
DROP PROCEDURE IF EXISTS `mfs_show_tree`$

-- ===============================================
DROP PROCEDURE IF EXISTS `mfs_show_branch`$
CREATE PROCEDURE `mfs_show_branch`(
  IN _nid VARCHAR(16)
)
BEGIN
  DECLARE _file_path TEXT DEFAULT NULL;
  DECLARE _db_name VARCHAR(80) DEFAULT NULL;
  DECLARE _home_dir VARCHAR(2000) DEFAULT NULL;
  DECLARE _eid VARCHAR(16) DEFAULT NULL;
  DECLARE _name VARCHAR(80) DEFAULT NULL;

  DROP TABLE IF EXISTS __tmp_tree;
  SELECT e.home_dir, e.id, COALESCE(h.name, d.fullname) FROM yp.entity e
    LEFT JOIN yp.hub h ON e.id = h.id AND e.type='hub'
    LEFT JOIN yp.drumate d ON e.id = d.id AND e.type='drumate'
    WHERE e.db_name=database() INTO _home_dir, _eid, _name;

  CREATE TEMPORARY TABLE __tmp_tree AS SELECT 
    id, 
    _home_dir AS home_dir, 
    _eid AS hub_id, 
    file_path, 
    parent_path, 
    parent_id AS pid, 
    status, 
    filesize,
    user_filename, 
    extension, 
    isalink,
    upload_time AS ctime,
    publish_time AS mtime,
    category
  FROM media where 1=2;
  INSERT INTO __tmp_tree
    WITH RECURSIVE __parent_tree AS
    (
      SELECT
        m.id, 
        _home_dir AS home_dir, 
        _eid AS hub_id,
        m.file_path,
        m.parent_path,
        m.parent_id,
        m.status, 
        m.filesize,
        m.user_filename, 
        m.extension, 
        m.isalink,
        m.upload_time AS ctime,
        m.publish_time AS mtime,
        m.category
      FROM
        media m
        WHERE m.id = _nid 
      UNION ALL
        SELECT
        m.id, 
        _home_dir AS home_dir, 
        _eid AS hub_id,
        m.file_path,
        m.parent_path,
        m.parent_id,
        m.status, 
        m.filesize,
        m.user_filename, 
        m.extension, 
        m.isalink,
        m.upload_time AS ctime,
        m.publish_time AS mtime,
        m.category
      FROM
        media AS m
      INNER JOIN __parent_tree AS t ON m.parent_id = t.id AND 
        t.category IN('folder', 'hub', 'root')
    )
    SELECT * FROM __parent_tree WHERE status IN('active', 'locked') ORDER BY category ASC;
  BEGIN
    DECLARE _finished INTEGER DEFAULT 0;
    DECLARE dbcursor CURSOR FOR SELECT e.id, e.home_dir, 
      REGEXP_REPLACE(file_path, CONCAT('\\\.', extension, '$'), ''),
      db_name FROM __tmp_tree m
      INNER JOIN (yp.entity e, permission p) ON m.id=e.id AND p.resource_id=m.id 
      WHERE m.category='hub' AND permission&2;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET _finished = 1; 
    OPEN dbcursor;
      STARTLOOP: LOOP
        FETCH dbcursor INTO _eid, _home_dir, _file_path, _db_name;
        IF _finished = 1 THEN 
          LEAVE STARTLOOP;
        END IF;    
        SET @s = CONCAT("INSERT INTO __tmp_tree SELECT id, ", 
          QUOTE(_home_dir),
          ",",
          QUOTE(_eid),
          ", clean_path(CONCAT(", 
          QUOTE(_file_path), 
          ", file_path)), 
          parent_path, 
          parent_id, 
          status, 
          filesize, 
          user_filename, 
          extension, 
          isalink,
          upload_time AS ctime,
          publish_time AS mtime,
          category FROM ", 
          _db_name, 
          ".media WHERE extension !='root' AND status IN('active', 'locked')");
        -- SELECT @s;
        IF @s IS NOT NULL THEN 
          PREPARE stmt FROM @s;
          EXECUTE stmt;
          DEALLOCATE PREPARE stmt;
        END IF;
       END LOOP STARTLOOP;
    CLOSE dbcursor;
  END;

  SELECT 
    id, 
    TRIM(TRAILING '/' FROM home_dir) home_dir, 
    IF(category IN('hub', 'folder'),
      REGEXP_REPLACE(REGEXP_REPLACE(file_path, CONCAT('\\\.', extension, '$'), ''), '^/+', ''), 
      REGEXP_REPLACE(file_path, '^/+', '')
    ) AS file_path,
    hub_id,
    status, 
    filesize, 
    user_filename, 
    parent_path,
    pid,
    extension, 
    isalink,
    ctime,
    mtime,
    category
  FROM __tmp_tree WHERE isalink=0 AND NOT file_path REGEXP '/__trash__/';

  SELECT sum(filesize) AS size FROM __tmp_tree;
  SELECT IF(user_filename = '' OR user_filename IS NULL, _name, user_filename) AS filename 
    FROM media WHERE id=_nid;
  SELECT count(*) AS amount, sum(filesize) AS size, category 
    FROM __tmp_tree GROUP BY category;

  DROP TABLE IF EXISTS __tmp_tree;
END$

DELIMITER ;
