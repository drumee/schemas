DELIMITER $
DROP PROCEDURE IF EXISTS `mfs_list_all`$
CREATE PROCEDURE `mfs_list_all`(
  IN _node_id VARCHAR(16),
  IN _page TINYINT(4),
  IN _type VARCHAR(10)
)
BEGIN
  DECLARE _range BIGINT;
  DECLARE _offset BIGINT;
  DECLARE _vhost VARCHAR(255);
  DECLARE _hub_id VARCHAR(16);
  DECLARE _area VARCHAR(50);
  DECLARE _home_dir VARCHAR(512);
  DECLARE _home_id VARCHAR(16);
  DECLARE _db_name VARCHAR(50);
  DECLARE _accessibility VARCHAR(16);

  IF _type IS NULL OR _type = '' THEN
    SET _type = 'all';
  END IF;

  CALL pageToLimits(_page, _offset, _range);
  CALL mediaEnv(_vhost, _hub_id, _area, _home_dir, _home_id, _db_name, _accessibility);
  SELECT
    media.id AS nid,
    parent_id AS pid,
    parent_id AS parent_id,
    _hub_id AS holder_id,
    _home_id AS home_id,
    IF(media.category='hub', 
      (SELECT id FROM yp.entity WHERE entity.id=media.id), _hub_id
    ) AS oid,    
    caption,
    capability,
    IF(media.category='hub', (
      SELECT accessibility FROM yp.entity WHERE entity.id=media.id), _accessibility
    ) AS accessibility,
    IF(media.category='hub', (
      SELECT status FROM yp.entity WHERE entity.id=media.id), status
    ) AS status,
    media.extension AS ext,
    media.category AS ftype,
    media.category AS filetype,
    media.mimetype,
    download_count AS view_count,
    geometry,
    upload_time AS ctime,
    publish_time AS ptime,
    parent_path,
    IF(parent_path='' or parent_path is NULL , '/', parent_path) AS user_path,
    IF(media.category='hub', (
      SELECT `name` FROM yp.hub WHERE hub.id=media.id), user_filename
    ) AS filename,
    IF(media.category='hub', (
      SELECT space FROM yp.entity WHERE entity.id=media.id), filesize
    ) AS filesize,
    firstname,
    lastname,
    remit,
    IF(media.category='hub', (
      SELECT utils.vhost(ident) FROM yp.entity WHERE entity.id=media.id), _vhost
    ) AS vhost,    
    _page as page,
    IF(media.category='hub', media.extension, _area) AS area
  FROM  media LEFT JOIN (yp.filecap, yp.drumate) ON 
  media.extension=filecap.extension AND origin_id=yp.drumate.id 
  WHERE parent_id=_node_id AND status='active'
    AND (
      _type = 'all'
      OR (_type = 'docs' AND media.category = 'document' AND media.extension != 'pdf')
      OR (_type = 'pdf' AND media.category = 'document' AND media.extension = 'pdf')
      OR (_type = 'image' AND media.category = 'image')
      OR (_type = 'other' AND media.category NOT IN ('folder', 'hub', 'root', 'document', 'image'))
    )
  ORDER BY ctime DESC LIMIT _offset, _range;
END$
DELIMITER ;