DELIMITER $

-- =========================================================================
-- mfs_node_attr - Server Side Usage
-- 
-- =========================================================================
DROP PROCEDURE IF EXISTS `mfs_parent_node_attr`$
CREATE PROCEDURE `mfs_parent_node_attr`(
  IN _node_id VARCHAR(16)
)
BEGIN
  DECLARE _parent_id VARCHAR(16);
  SELECT parent_id FROM media WHERE id=_node_id INTO _parent_id;
  CALL mfs_node_attr(_parent_id);
END$

-- =========================================================================
-- mfs_node_attr - Server Side Usage
-- file_path is omitted by security
-- =========================================================================
DROP PROCEDURE IF EXISTS `mfs_node_attr`$
CREATE PROCEDURE `mfs_node_attr`(
  IN _key VARCHAR(1024) 
)
BEGIN

  DECLARE _area VARCHAR(25);
  DECLARE _vhost VARCHAR(255);
  DECLARE _home_dir VARCHAR(500);
  DECLARE _hub_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _dom_id VARCHAR(16) ;
  DECLARE _home_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _parent_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _db_name VARCHAR(50);
  DECLARE _hub_name VARCHAR(150);
  DECLARE _hub_db VARCHAR(150);
  DECLARE _actual_home_id VARCHAR(150) CHARACTER SET ascii;
  DECLARE _actual_hub_id VARCHAR(150) CHARACTER SET ascii;
  DECLARE _actual_db VARCHAR(150);
  DECLARE _node_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _remit TINYINT(4) DEFAULT 0;

  IF _key regexp  '^\/.+' THEN 
    SELECT id FROM media 
      WHERE REPLACE(file_path, '/', '') = 
      REPLACE(IF(category='folder' OR category ='hub', CONCAT(_key, '.', extension), _key), '/','')
      INTO _node_id;
  ELSE 
    SELECT _key INTO _node_id;
  END IF;


  SELECT 
    COALESCE(h.name, dr.fullname) AS `name`,
    e.id,
    e.home_id,
    e.home_dir,
    d.id,
    e.area,
    v.fqdn,
    e.db_name
  FROM yp.entity e
    INNER JOIN yp.vhost v ON e.id = v.id 
    INNER JOIN yp.domain d ON d.id = e.dom_id
    LEFT JOIN yp.drumate dr ON e.id = dr.id 
    LEFT JOIN yp.hub h ON e.id = h.id 
  WHERE e.db_name = database() 
  INTO 
    _hub_name,
    _hub_id, 
    _home_id, 
    _home_dir,
    _dom_id, 
    _area,
    _vhost,
    _db_name;

  SELECT _home_id , _hub_id, _db_name
    INTO _actual_home_id, _actual_hub_id, _actual_db;



  SELECT
    m.id,
    m.id  AS nid,
    _actual_home_id AS actual_home_id, 
    _actual_hub_id AS actual_hub_id,
    _actual_db AS actual_db,
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
    COALESCE(fc.category, m.category) ftype,
    COALESCE(fc.category, m.category) filetype,
    COALESCE(fc.mimetype, m.mimetype) mimetype,
    download_count AS view_count,
    isalink,
    IF(m.isalink =1 AND m.category NOT IN ('hub')  ,JSON_UNQUOTE(JSON_EXTRACT(m.metadata, "$.target.nid")), NULL) target_nid , 
    IF(m.isalink =1 AND m.category NOT IN ('hub')  ,JSON_UNQUOTE(JSON_EXTRACT(m.metadata, "$.target.hub_id")), NULL)  target_hub_id, 
    IF(m.isalink =1 AND m.category NOT IN ('hub')  ,JSON_UNQUOTE(JSON_EXTRACT(m.metadata, "$.target.mfs_root")), NULL)  target_mfs_root, 
    m.metadata metadata,
    geometry,
    upload_time AS ctime,
    publish_time AS ptime,
    publish_time AS mtime,
    CASE 
      WHEN m.category='hub' THEN _hub_name
      WHEN m.parent_id='0' THEN _hub_name
      ELSE user_filename
    END AS filename,
    parent_path,
    file_path,
    filesize,
    _remit AS remit
  FROM  media m LEFT JOIN (yp.filecap fc, yp.drumate) 
  ON m.extension=fc.extension AND origin_id=drumate.id 
  WHERE m.id=_node_id;
END $


DELIMITER ;

