  
 DELIMITER $
-- ==============================================================
-- mfs_show_node_by
-- List files + directories under directory identified by node_id
-- ==============================================================


DROP PROCEDURE IF EXISTS `mfs_show_node_by`$
CREATE PROCEDURE `mfs_show_node_by`(
  IN _node_id VARCHAR(16) CHARACTER SET ascii,
  IN _uid VARCHAR(16) CHARACTER SET ascii,
  IN _sort_by VARCHAR(20),
  IN _order   VARCHAR(20),
  IN _page    TINYINT(4)
)
BEGIN
 
  DECLARE _range bigint;
  DECLARE _offset bigint;
  DECLARE _home_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _cur_db VARCHAR(255);
  DECLARE _finished INTEGER DEFAULT 0; 
  DECLARE _nid VARCHAR(16) CHARACTER SET ascii;  
  DECLARE _area VARCHAR(30);
  DECLARE _flag_expiry VARCHAR(30);
  DECLARE _hub_id VARCHAR(16);
  DECLARE _ts INT(11);
  DECLARE _cur_hub_id VARCHAR(16) CHARACTER SET ascii ;
  DECLARE _hub_name VARCHAR(5000) ;
  DECLARE _user_db VARCHAR(255);
  DECLARE _hub_db VARCHAR(255);
  DECLARE _lastread INT(11) DEFAULT 0;

  DECLARE dbcursor CURSOR FOR SELECT id, db_name, home_id, area FROM _myhubs;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET _finished = 1; 

  SELECT UNIX_TIMESTAMP() INTO _ts;

  -- Force user defined var to the same collation;
  SELECT _utf8mb4'' COLLATE utf8mb4_general_ci into @parent_path;
  SELECT _utf8mb4'' COLLATE utf8mb4_general_ci into @hub_name;

  CALL pageToLimits(_page, _offset, _range);    
  SELECT DATABASE() INTO _cur_db;
  SELECT db_name FROM yp.entity WHERE id = _uid INTO _user_db;
  SELECT id FROM yp.entity WHERE db_name=_cur_db INTO _cur_hub_id;
  SELECT id  from media where parent_id='0' INTO _home_id;
  SELECT yp.get_sysconf('guest_id') INTO @guest_id;
  SELECT IFNULL(max(ctime), 0) FROM readlog WHERE uid=_uid INTO _lastread;

  IF _user_db IS NOT NULL THEN 
    -- IF _user_db = _cur_db THEN 
    --   CALL readlog_update(_uid, _lastread, 0);
    -- ELSE
      SELECT '' INTO @hub_name;
      SELECT '/' INTO @parent_path;
      SET @s = CONCAT("
        SELECT user_filename, parent_path
        FROM  ", _user_db, ".media m 
        WHERE m.id=", quote(_cur_hub_id), " INTO @hub_name , @parent_path"
      );
      PREPARE stmt FROM @s;
      EXECUTE stmt ;
      DEALLOCATE PREPARE stmt;
      SELECT CONCAT(@parent_path,'/', @hub_name) INTO _hub_name  WHERE @hub_name  <>  '';
      -- CALL readlog_update(_uid, _lastread, 1);
    -- END IF;
    CALL readlog_update(_uid, _lastread, _user_db <> _cur_db);
  END IF;

  IF _node_id IS NULL OR _node_id='0' THEN 
    SELECT _home_id INTO _node_id;
  END IF;
  
  IF _node_id REGEXP "^/.+" THEN 
    SELECT id FROM media WHERE file_path = clean_path(_node_id) INTO _node_id;
  END IF;

  DROP TABLE IF EXISTS _nodeview;
  CREATE TEMPORARY TABLE _nodeview  LIKE utils.template_nodeview;
  
  INSERT INTO _nodeview SELECT 
    m.id nid,
    m.parent_id,
    REGEXP_REPLACE(CONCAT(IFNULL(_hub_name, ''), m.file_path), '/+', '/') filepath,
    IF(m.category = 'hub', '/', REGEXP_REPLACE(m.file_path, '/+', '/')) ownpath,
    _cur_hub_id holder_id,    
    _home_id home_id, 
    hx.home_id actual_home_id,
    IFNULL(fc.capability, '---') capability,
    _cur_db src_db_name,
    hx.db_name hub_db_name,
    hx.hubname hubname,
    hx.accessibility,
    hx.owner_id,
    COALESCE(hx.id, _cur_hub_id) hub_id,
    m.status status,
    m.user_filename filename,
    m.filesize filesize,
    v0.fqdn,
    hx.area area,
    m.caption,
    m.extension ext,
    m.category ftype,
    m.mimetype mimetype,
    m.metadata,
    m.upload_time ctime,
    m.publish_time mtime,
    IFNULL(r.unread, 0) new_file,
    isalink,
    _page page,
    m.rank,
    user_permission(_uid, m.id ) privilege,
    user_expiry(_uid, m.id ) expiry_time,
    'na' flag_expiry,
    '' hubs,
    '' nodes
  FROM media m
    INNER JOIN yp.entity ch ON ch.db_name=_cur_db
    LEFT JOIN yp.filecap fc ON m.extension=fc.extension
    -- LEFT JOIN _myhubs h0 ON  h0.id=m.id
    LEFT JOIN _myhubs hx ON  hx.id=m.host_id
    LEFT JOIN readlog r ON m.id=r.nid AND r.uid=_uid AND r.ctime >= _lastread
    LEFT JOIN yp.vhost v0 ON  v0.id=m.host_id
    -- LEFT JOIN yp.vhost v1 ON  v1.id=m.hub_id
  WHERE m.parent_id=_node_id AND 
    m.file_path not REGEXP '^/__(chat|trash|upload)__' AND 
    m.`status` IN ('active', 'locked') ;


 OPEN dbcursor;
    STARTLOOP: LOOP
    FETCH dbcursor INTO _hub_id, _hub_db, _home_id, _area;
    IF _finished = 1 THEN 
      LEAVE STARTLOOP;
    END IF;

    SET @perm = 0;
    SET @resexpiry = NULL;
    SET @s = CONCAT("SELECT ", _hub_db, ".user_permission (?, ?) INTO @perm");
    PREPARE stmt FROM @s;
    EXECUTE stmt USING _uid, _nid;
    DEALLOCATE PREPARE stmt; 

    SET @resexpiry = null;    
    SET @s = CONCAT("SELECT ", _hub_db, ".user_expiry (?, ?) INTO @resexpiry");
    PREPARE stmt FROM @s;
    EXECUTE stmt USING _uid, _nid;
    DEALLOCATE PREPARE stmt;

    SELECT 'na' INTO _flag_expiry ;

    IF _area = 'share' THEN
      SET @expiry_time = NULL;
      SET @s = CONCAT("
        SELECT p.expiry_time
        FROM  ",_hub_db, ".permission p 
        INNER JOIN yp.dmz_token t ON p.entity_id = t.guest_id
        INNER JOIN yp.dmz_user u ON p.entity_id = u.id
        INNER JOIN yp.entity e ON e.id=  t.hub_id AND  e.home_id = t.node_id
        WHERE e.db_name=", quote(_hub_db), " AND  u.id = @guest_id  INTO @expiry_time"
      );
      PREPARE stmt FROM @s;
      EXECUTE stmt ;
      DEALLOCATE PREPARE stmt;
      SELECT 
        CASE 
          WHEN IFNULL(@expiry_time,0) = 0 THEN  'infinity' 
          WHEN (@expiry_time - _ts) <= 0  THEN 'expired'
          ELSE 'active'
      END INTO  _flag_expiry; 
      
    END IF;
    UPDATE _nodeview s SET privilege=@perm, expiry_time=@resexpiry, flag_expiry=_flag_expiry
      WHERE nid = _hub_id;
  END LOOP STARTLOOP;

  DROP TABLE IF EXISTS  _nodetree; 
  CREATE TEMPORARY TABLE  _nodetree (
    `seq`  int NOT NULL AUTO_INCREMENT,
    `heritage_id` varchar(16) CHARACTER SET ascii,
    `id` varchar(16) CHARACTER SET ascii,
    `parent_id` varchar(16) CHARACTER SET ascii, 
    `category` varchar(16) ,
    `new_file` int default 0, 
    PRIMARY KEY `seq`(`seq`)
  );

  INSERT INTO  _nodetree (heritage_id, id, parent_id ,category)
  WITH RECURSIVE mytree AS 
  ( 
    SELECT id heritage_id , id, parent_id ,category
    FROM media WHERE id IN (
      SELECT nid from  _nodeview WHERE category in ('folder','hub' ) 
    ) AND  category in ('folder','hub' )
    UNION ALL
    SELECT t.heritage_id, m.id, m.parent_id ,m.category
    FROM media AS m JOIN mytree AS t ON m.parent_id = t.id AND
      t.category IN ('folder','hub' ) 
  ) SELECT heritage_id, id, parent_id ,category  FROM mytree;

  UPDATE  _nodeview t INNER JOIN (
    SELECT  heritage_id, 
      GROUP_CONCAT( CASE WHEN id <> heritage_id THEN  id  ELSE NULL END ) nodes,
      GROUP_CONCAT(CASE WHEN category = 'hub' AND id <> heritage_id THEN  id  ELSE NULL END ) hubs
      FROM  _nodetree GROUP by heritage_id 
    ) h ON nid = heritage_id
  SET t.nodes = h.nodes,t.hubs = h.hubs;

  UPDATE  _nodeview t INNER JOIN (
    SELECT hub_id, SUM(r.unread) new_file FROM readlog r 
        INNER JOIN  _nodetree n ON r.hub_id=n.heritage_id 
        WHERE r.uid=_uid AND r.ctime >= _lastread
        GROUP BY r.hub_id 
    ) h ON t.nid = h.hub_id
  SET t.new_file = h.new_file;

  SELECT 
    *,
    ftype filetype,
    pid parent_id
  FROM _nodeview 
  ORDER BY 
    CASE WHEN LCASE(_sort_by) = 'date' and LCASE(_order) = 'asc'  THEN ctime END ASC,
    CASE WHEN LCASE(_sort_by) = 'date' and LCASE(_order) = 'desc' THEN ctime END DESC,
    CASE WHEN LCASE(_sort_by) = 'name' and LCASE(_order) = 'asc'  THEN filename END ASC,
    CASE WHEN LCASE(_sort_by) = 'name' and LCASE(_order) = 'desc' THEN filename END DESC,
    CASE WHEN LCASE(_sort_by) = 'rank' and LCASE(_order) = 'asc'  THEN rank END ASC,
    CASE WHEN LCASE(_sort_by) = 'rank' and LCASE(_order) = 'desc' THEN rank END DESC,
    CASE WHEN LCASE(_sort_by) = 'size' and LCASE(_order) = 'asc'  THEN filesize END ASC,
    CASE WHEN LCASE(_sort_by) = 'size' and LCASE(_order) = 'desc' THEN filesize END DESC;

  -- DROP TABLE IF EXISTS _nodeview;
  -- DROP TABLE IF EXISTS  _nodeview;
  -- DROP TABLE IF EXISTS  _nodetree;
END $

DELIMITER ;

