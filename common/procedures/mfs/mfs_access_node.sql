DELIMITER $

-- =========================================================================
-- mfs_node_access - 
-- Same as mfs_access_node but but permission 
-- =========================================================================
DROP PROCEDURE IF EXISTS `mfs_access_node`$
CREATE PROCEDURE `mfs_access_node`(
  IN _uid VARCHAR(500) CHARACTER SET ascii,
  IN _node_id VARCHAR(1000) CHARACTER SET ascii
)
BEGIN

  DECLARE _area VARCHAR(25);
  DECLARE _nid VARCHAR(16) CHARACTER SET ascii DEFAULT NULL;
  DECLARE _vhost VARCHAR(255);
  DECLARE _home_dir VARCHAR(500);
  DECLARE _hub_id VARCHAR(16) CHARACTER SET ascii ;
  DECLARE _dom_id VARCHAR(16);
  DECLARE _home_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _parent_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _db_name VARCHAR(50);
  DECLARE _file_type VARCHAR(50);
  DECLARE _hub_name VARCHAR(150);
  DECLARE _hub_db VARCHAR(150);
  DECLARE _actual_home_id VARCHAR(150) CHARACTER SET ascii DEFAULT NULL;
  DECLARE _actual_hub_id VARCHAR(150) CHARACTER SET ascii DEFAULT NULL;
  DECLARE _actual_db VARCHAR(150) DEFAULT NULL;
  DECLARE _remit TINYINT(4) DEFAULT 0;
  DECLARE _perm TINYINT(2) DEFAULT 0;
  DECLARE _root_hub_id VARCHAR(16) CHARACTER SET ascii ;
  DECLARE _user_db_name VARCHAR(255);
  DECLARE _src_db_name VARCHAR(255);

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
      -- quite silently
    END;

  SELECT database() INTO _src_db_name;
  SELECT  h.id FROM yp.hub h INNER JOIN yp.entity e on e.id = h.id 
    WHERE db_name=_src_db_name INTO _root_hub_id;
  SELECT '' INTO @xhub_name;
  

  IF _root_hub_id IS NOT NULL THEN
    SELECT db_name FROM yp.entity WHERE id = _uid INTO _user_db_name;
    IF _user_db_name IS NOT NULL THEN 
      SET @s = CONCAT("SELECT ", _user_db_name, ".filepath(?) INTO @xhub_name");
      PREPARE stmt FROM @s;
      EXECUTE stmt USING _root_hub_id;
      DEALLOCATE PREPARE stmt;
    END IF;
  END IF;

  IF _node_id REGEXP ".*/.*" THEN 
    SELECT id FROM media WHERE file_path=_node_id INTO _nid;
    IF _nid IS NULL THEN 
      SIGNAL SQLSTATE '45000';
    ELSE
      SELECT _nid INTO _node_id;
    END IF;
  END IF;

  SELECT category FROM media WHERE id=_node_id INTO _file_type;
  IF _file_type = 'folder' THEN 
    DROP TABLE IF EXISTS _node_tree; 
    CREATE TEMPORARY TABLE _node_tree (
      `seq`  int NOT NULL AUTO_INCREMENT,
      `heritage_id` varchar(16) CHARACTER SET ascii,
      `id` varchar(16) CHARACTER SET ascii,
      `parent_id` varchar(16) CHARACTER SET ascii, 
      `category` varchar(16) ,
      `area` MEDIUMTEXT ,
      `new_file` int default 0, 
      PRIMARY KEY `seq`(`seq`)
    );
    INSERT INTO _node_tree 
    (heritage_id, id, parent_id, category, area)
    WITH RECURSIVE mytree AS 
    ( 
      SELECT mm.id heritage_id, mm.id, mm.parent_id, mm.category, e.area FROM media mm 
      LEFT JOIN yp.entity e ON e.id=mm.id 
      WHERE mm.category in ('folder','hub' )
      UNION ALL
      SELECT t.heritage_id, m.id, m.parent_id, m.category, e.area FROM media m
      JOIN mytree AS t ON m.parent_id = t.id AND t.category IN ('folder','hub' ) 
      LEFT JOIN yp.entity e ON e.id=m.id 
    ) SELECT heritage_id, id, parent_id, category, area FROM mytree;
    SELECT 
      GROUP_CONCAT(DISTINCT CASE WHEN id <> heritage_id THEN id ELSE NULL END) nodes,
      GROUP_CONCAT(DISTINCT CASE WHEN category = 'hub' AND id <> heritage_id THEN id ELSE NULL END) hubs,
      GROUP_CONCAT(DISTINCT CASE WHEN category = 'hub' AND id <> heritage_id THEN area ELSE NULL END) areas
    FROM _node_tree WHERE heritage_id=_node_id GROUP BY heritage_id
      INTO @nodes, @hubs, @areas;
  END IF;

  SELECT 
    COALESCE(h.id, dr.id) AS id,
    e.home_id,
    e.home_dir,
    d.id,
    e.area,
    v.fqdn  AS vhost,
    e.db_name 
  FROM yp.entity e
    INNER JOIN yp.domain d ON d.id = e.dom_id
    LEFT JOIN yp.vhost v ON v.id = e.id
    LEFT JOIN yp.entity dr ON e.id = dr.id AND e.area='personal'
    LEFT JOIN yp.entity h ON e.id = h.id AND e.area IN('private', 'public', 'share','dmz','restricted')
  WHERE e.db_name = database() GROUP BY (id) LIMIT 1
  INTO 
    _hub_id, 
    _home_id, 
    _home_dir,
    _dom_id, 
    _area,
    _vhost,
    _db_name;

  SELECT IFNULL(privilege, 0) FROM yp.privilege WHERE  domain_id = _dom_id AND  `uid`=_uid
    INTO _remit;

  SELECT 
    COALESCE(h.name, dr.fullname) AS `name`,
    IFNULL(e.area, _area), 
    IFNULL(e.home_id, _home_id), 
    IFNULL(e.id, _hub_id),
    IFNULL(e.db_name, _db_name)
  FROM yp.entity e 
    LEFT JOIN yp.drumate dr ON e.id = dr.id AND e.type='drumate'
    LEFT JOIN yp.hub h ON e.id = h.id 
    WHERE e.id=_node_id 
  INTO 
    _hub_name, 
    _area,
    _actual_home_id, 
    _actual_hub_id,
    _actual_db;
  SELECT user_permission(_uid, _node_id) INTO _perm;

  SELECT
    m.id,
    m.id  AS nid,
    IFNULL(_actual_home_id, _home_id) AS actual_home_id, 
    IFNULL(_actual_hub_id, _hub_id) AS actual_hub_id,
    IFNULL(_actual_db, _db_name) AS actual_db,
    _db_name AS db_name,
    concat(_home_dir, "/__storage__/") AS mfs_root,
    concat(_home_dir, "/__storage__/") AS home_dir,
    parent_id AS pid,
    parent_id AS parent_id,
    _hub_id AS hub_id,
    _vhost AS vhost,
    caption,
    _area AS accessibility,
    _area AS area,
    _home_id AS home_id,
    capability,
    m.status AS status,
    m.extension,
    m.extension AS ext,
    COALESCE(m.category, fc.category) ftype,
    COALESCE(m.category, fc.category) filetype,
    COALESCE(m.mimetype, fc.mimetype) mimetype,
    isalink,
    JSON_VALUE(m.metadata, "$.md5Hash") AS md5Hash,
    IF(m.isalink =1 AND m.category NOT IN ('hub'), JSON_VALUE(m.metadata, "$.target.nid"), NULL) target_nid , 
    IF(m.isalink =1 AND m.category NOT IN ('hub'), JSON_VALUE(m.metadata, "$.target.hub_id"), NULL)  target_hub_id, 
    IF(m.isalink =1 AND m.category NOT IN ('hub'), JSON_VALUE(m.metadata, "$.target.mfs_root"), NULL)  target_mfs_root, 
    _perm  as permission,
    _perm  as privilege,
    download_count AS view_count,
    m.metadata metadata,
    geometry,
    upload_time AS ctime,
    publish_time AS mtime,
    CASE 
      WHEN m.category='hub' THEN COALESCE(user_filename, _hub_name)
      WHEN m.parent_id='0' THEN COALESCE(user_filename, _hub_name)
      ELSE user_filename
    END AS filename,
    parent_path,
    CONCAT(@xhub_name, file_path) as file_path,
    REGEXP_REPLACE(CONCAT(@xhub_name, file_path), '/+', '/') as filepath,
    REGEXP_REPLACE(file_path, '/+', '/') as ownpath,
    filesize,
    firstname,
    lastname,
    _remit AS remit,
    @nodes nodes, 
    @hubs hubs, 
    @areas areas
  FROM  media m LEFT JOIN (yp.filecap fc, yp.drumate) 
  ON m.extension=fc.extension AND origin_id=drumate.id 
  WHERE m.id=_node_id
UNION ALL
  SELECT
    m.id,
    m.id  AS nid,
    IFNULL(_actual_home_id, _home_id) AS actual_home_id, 
    IFNULL(_actual_hub_id, _hub_id) AS actual_hub_id,
    IFNULL(_actual_db, _db_name) AS actual_db,
    _db_name AS db_name,
    concat(_home_dir, "/__storage__/") AS mfs_root,
    concat(_home_dir, "/__storage__/") AS home_dir,
    parent_id AS pid,
    parent_id AS parent_id,
    _hub_id AS hub_id,
    _vhost AS vhost,
    caption,
    _area AS accessibility,
    _area AS area,
    _home_id AS home_id,
    capability,
    m.status AS status,
    m.extension,
    m.extension AS ext,
    COALESCE(m.category, fc.category) ftype,
    COALESCE(m.category, fc.category) filetype,
    COALESCE(m.mimetype, fc.mimetype) mimetype,
    isalink,
    JSON_VALUE(m.metadata, "$.md5Hash") AS md5Hash,
    IF(m.isalink =1 AND m.category NOT IN ('hub'), JSON_VALUE(m.metadata, "$.target.nid"), NULL) target_nid , 
    IF(m.isalink =1 AND m.category NOT IN ('hub'), JSON_VALUE(m.metadata, "$.target.hub_id"), NULL)  target_hub_id, 
    IF(m.isalink =1 AND m.category NOT IN ('hub'), JSON_VALUE(m.metadata, "$.target.mfs_root"), NULL)  target_mfs_root, 
    _perm AS permission,
    _perm AS privilege,
    download_count AS view_count,
    m.metadata metadata,
    geometry,
    upload_time AS ctime,
    publish_time AS mtime,
    CASE 
      WHEN m.category='hub' THEN COALESCE(user_filename, _hub_name)
      WHEN m.parent_id='0' THEN COALESCE(user_filename, _hub_name)
      ELSE user_filename
    END AS filename,
    parent_path,
    CONCAT(@xhub_name, file_path) as file_path,
    REGEXP_REPLACE(CONCAT(@xhub_name, file_path), '/+', '/') AS filepath,
    IF(COALESCE(fc.category, m.category) = 'hub', '/', REGEXP_REPLACE(file_path, '/+', '/')) AS ownpath,
    filesize,
    firstname,
    lastname,
    _remit AS remit,
    @nodes nodes, 
    @hubs hubs, 
    @areas areas
  FROM  trash_media m LEFT JOIN (yp.filecap fc, yp.drumate) 
  ON m.extension=fc.extension AND origin_id=drumate.id 
  WHERE m.id=_node_id;

END $


DELIMITER ;



