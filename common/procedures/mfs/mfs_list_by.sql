DELIMITER $

DROP PROCEDURE IF EXISTS `mfs_browse_by`$
DROP PROCEDURE IF EXISTS `mfs_list_by`$
CREATE PROCEDURE `mfs_list_by`(
  IN _args JSON
)
BEGIN

  DECLARE _range bigint;
  DECLARE _offset bigint;
  DECLARE _sort VARCHAR(20);  
  DECLARE _pid VARCHAR(2000);
  DECLARE _order VARCHAR(20);
  DECLARE _type VARCHAR(20);
  DECLARE _page TINYINT(4);

  SELECT IFNULL(JSON_VALUE(_args, '$.page'), 1) INTO _page ;
  SELECT IFNULL(JSON_VALUE(_args, '$.sort'), "name") INTO _sort ;
  SELECT IFNULL(JSON_VALUE(_args, '$.order'), "asc") INTO _order ;
  SELECT IFNULL(JSON_VALUE(_args, '$.type'), "") INTO _type ;
  SELECT IFNULL(JSON_VALUE(_args, '$.pid'), "*") INTO _pid ;

  IF _pid REGEXP "^/.+" THEN 
    SELECT id FROM media WHERE file_path = clean_path(_node_id) INTO _pid;
  END IF;

  CALL pageToLimits(_page, _offset, _range);
  IF _pid = "*" THEN 
    SELECT
      m.id  AS nid,
      parent_id AS pid,
      parent_id AS parent_id,
      origin_id AS gid,
      file_path,
      file_path filepath,
      capability,
      m.status AS status,
      m.extension AS ext,
      m.category AS ftype,
      m.category AS filetype,
      m.mimetype,
      download_count AS view_count,
      geometry,
      upload_time AS ctime,
      publish_time AS ptime,
      user_filename AS filename,
      parent_path,
      filesize,
      firstname,
      lastname,
      remit,
      _page as page,
      me.area,
      me.id as hub_id,
      me.home_id,
      COALESCE(vv.fqdn, v.fqdn) AS vhost
    FROM  media m 
      INNER JOIN yp.entity me  ON me.db_name=database()
      LEFT JOIN yp.filecap f ON m.extension=f.extension
      LEFT JOIN yp.drumate dr ON origin_id=dr.id 
      LEFT JOIN yp.vhost v ON  v.id=me.id
      LEFT JOIN yp.vhost vv ON  vv.id=m.id

    WHERE m.category=_type AND 
      m.file_path NOT REGEXP '^/__(chat|trash|upload)__' AND 
      m.`status` NOT IN ('hidden', 'deleted')
    ORDER BY 
      CASE WHEN LCASE(_sort) = 'date' and LCASE(_order) = 'asc' THEN ctime END ASC,
      CASE WHEN LCASE(_sort) = 'date' and LCASE(_order) = 'desc' THEN ctime END DESC,
      CASE WHEN LCASE(_sort) = 'name' and LCASE(_order) = 'asc' THEN filename END ASC,
      CASE WHEN LCASE(_sort) = 'name' and LCASE(_order) = 'desc' THEN filename END DESC,
      CASE WHEN LCASE(_sort) = 'rank' and LCASE(_order) = 'asc' THEN rank END ASC,
      CASE WHEN LCASE(_sort) = 'rank' and LCASE(_order) = 'desc' THEN rank END DESC,
      CASE WHEN LCASE(_sort) = 'size' and LCASE(_order) = 'asc' THEN filesize END ASC,
      CASE WHEN LCASE(_sort) = 'size' and LCASE(_order) = 'desc' THEN filesize END DESC
    LIMIT _offset ,_range;

  ELSE
    SELECT
      m.id  AS nid,
      parent_id AS pid,
      parent_id AS parent_id,
      origin_id AS gid,
      file_path,
      file_path filepath,
      capability,
      m.status AS status,
      m.extension AS ext,
      m.category AS ftype,
      m.category AS filetype,
      m.mimetype,
      download_count AS view_count,
      geometry,
      upload_time AS ctime,
      publish_time AS ptime,
      user_filename AS filename,
      parent_path,
      filesize,
      firstname,
      lastname,
      remit,
      _page as page,
      me.area,
      me.id as hub_id,
      me.home_id,
      COALESCE(vv.fqdn, v.fqdn) AS vhost
    FROM  media m 
      INNER JOIN yp.entity me  ON me.db_name=database()
      LEFT JOIN yp.filecap f ON m.extension=f.extension
      LEFT JOIN yp.drumate dr ON origin_id=dr.id 
      LEFT JOIN yp.vhost v ON  v.id=me.id
      LEFT JOIN yp.vhost vv ON  vv.id=m.id

    WHERE m.category=_type AND parent_id=_pid AND 
      m.file_path not REGEXP '^/__(chat|trash|upload)__' AND 
      m.`status` NOT IN ('hidden', 'deleted')
    ORDER BY 
      CASE WHEN LCASE(_sort) = 'date' and LCASE(_order) = 'asc' THEN ctime END ASC,
      CASE WHEN LCASE(_sort) = 'date' and LCASE(_order) = 'desc' THEN ctime END DESC,
      CASE WHEN LCASE(_sort) = 'name' and LCASE(_order) = 'asc' THEN filename END ASC,
      CASE WHEN LCASE(_sort) = 'name' and LCASE(_order) = 'desc' THEN filename END DESC,
      CASE WHEN LCASE(_sort) = 'rank' and LCASE(_order) = 'asc' THEN rank END ASC,
      CASE WHEN LCASE(_sort) = 'rank' and LCASE(_order) = 'desc' THEN rank END DESC,
      CASE WHEN LCASE(_sort) = 'size' and LCASE(_order) = 'asc' THEN filesize END ASC,
      CASE WHEN LCASE(_sort) = 'size' and LCASE(_order) = 'desc' THEN filesize END DESC
    LIMIT _offset ,_range;
  END IF;
END $

DELIMITER ;