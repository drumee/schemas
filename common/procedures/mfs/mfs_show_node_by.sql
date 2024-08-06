  
 DELIMITER $
-- ==============================================================
-- mfs_show_node_by
-- List files + directories under directory identified by node_id
-- ==============================================================


DROP PROCEDURE IF EXISTS `mfs_show_node_by_next`$
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
  DECLARE _src_db_name VARCHAR(255);
  DECLARE _finished       INTEGER DEFAULT 0; 
  DECLARE _nid VARCHAR(16) CHARACTER SET ascii;  
  DECLARE _parent_id VARCHAR(16) CHARACTER SET ascii;  
  DECLARE _hub_db_name VARCHAR(255);
  DECLARE _ftype VARCHAR(255);

  DECLARE _sys_id INT;
  DECLARE _temp_sys_id INT;
  DECLARE _db VARCHAR(400);


  DECLARE _tempid VARCHAR(16) CHARACTER SET ascii;
  DECLARE _category VARCHAR(16);
  DECLARE _area VARCHAR(30);
  DECLARE _hub_area VARCHAR(30);
  DECLARE _flag_expiry VARCHAR(30);
  DECLARE _lvl INT;
  DECLARE _hubs MEDIUMTEXT DEFAULT NULL;
  DECLARE _hub_id VARCHAR(16);
  DECLARE _username VARCHAR(100);
  DECLARE _org VARCHAR(500);
  DECLARE _ts INT(11);
  DECLARE _expiry_time INT(11);
  DECLARE _root_hub_id VARCHAR(16) CHARACTER SET ascii ;
  DECLARE _hub_name VARCHAR(5000) ;
  DECLARE _user_db_name VARCHAR(255);

  SELECT UNIX_TIMESTAMP() INTO _ts;

  CALL pageToLimits(_page, _offset, _range);  
  SELECT database() INTO _src_db_name;
  SELECT id  from media where parent_id='0' INTO _home_id;

  SELECT  h.id, e.area 
    FROM yp.hub h INNER JOIN yp.entity e on e.id = h.id 
    WHERE db_name=_src_db_name INTO _root_hub_id, _hub_area;
  SELECT '' INTO _hub_name;

  IF _root_hub_id IS NOT NULL THEN
    SELECT db_name FROM yp.entity WHERE id = _uid INTO _user_db_name;
    SELECT '' INTO @hub_name;
    IF _user_db_name IS NOT NULL THEN 
      SET @s = CONCAT("
          SELECT user_filename,parent_path
          FROM  ",_user_db_name,".media m 
          WHERE m.id='",_root_hub_id,"' INTO @hub_name , @parent_path"
        );
      PREPARE stmt FROM @s;
      EXECUTE stmt ;
      DEALLOCATE PREPARE stmt;
      SELECT CONCAT(@parent_path,'/',@hub_name) INTO _hub_name  WHERE @hub_name  <>  '';
    END IF;
  END IF;

  SELECT yp.get_sysconf('guest_id') INTO @guest_id;

  IF _node_id IS NULL OR _node_id='0' THEN 
    SELECT _home_id INTO _node_id;
  END IF;
  
  IF _node_id REGEXP "^/.+" THEN 
    SELECT id FROM media WHERE file_path = clean_path(_node_id) INTO _node_id;
  END IF;

  DROP TABLE IF EXISTS _temp_show_node;
  CREATE TEMPORARY TABLE _temp_show_node  AS  
  SELECT 
    m.id AS nid,
    m.parent_id AS pid,
    m.parent_id AS parent_id,
    CONCAT(_hub_name, m.file_path) as filepath,
    IF(m.category = 'hub', '/', m.file_path) AS ownpath,
    me.id  AS holder_id,    
    _home_id  AS home_id,   
    null capability,
    _src_db_name AS src_db_name,
    he.db_name hub_db_name,
    hh.name hubname,
    COALESCE(he.accessibility,me.accessibility) AS  accessibility,
    COALESCE(he.id, hh.owner_id) AS owner_id,
    COALESCE(he.id, me.id) AS hub_id,
    COALESCE(he.status, m.status) AS status,
    m.user_filename AS filename,
    m.filesize AS filesize,
    COALESCE(vv.fqdn, v.fqdn) AS vhost,
    he.area AS area,
    m.caption,
    m.extension AS ext,
    m.category AS ftype,
    m.mimetype mimetype,
    m.metadata,
    m.download_count AS view_count,
    m.geometry,
    m.upload_time AS ctime,
    m.publish_time AS mtime,
    is_new(m.metadata, COALESCE(he.id, hh.owner_id) , _uid)  new_file,
    isalink,
     _page as page,
     m.rank,
    IF(m.category = 'hub' , null, user_permission(_uid, m.id )) privilege,
    IF(m.category = 'hub' , null, user_expiry(_uid, m.id )) expiry_time
  FROM media m
    INNER JOIN yp.entity me  ON me.db_name=database()
    LEFT JOIN yp.vhost v ON  v.id=me.id
    LEFT JOIN yp.vhost vv ON  vv.id=m.id
    LEFT JOIN yp.entity he ON m.id = he.id AND m.category='hub'
    LEFT JOIN yp.hub hh ON m.id = hh.id AND m.category='hub'
  WHERE m.parent_id=_node_id AND 
    m.file_path not REGEXP '^/__(chat|trash|upload)__' AND 
    m.`status` NOT IN ('hidden', 'deleted') ;

  ALTER TABLE _temp_show_node ADD sys_id INT PRIMARY KEY AUTO_INCREMENT;
  ALTER TABLE _temp_show_node ADD flag_expiry VARCHAR(30) DEFAULT 'na';
  ALTER TABLE _temp_show_node modify  new_file int DEFAULT 0;

  SELECT sys_id, IF(ftype = 'hub', hub_db_name, null), IF(ftype = 'hub', nid, null) , area
    FROM _temp_show_node WHERE sys_id > 0  AND  (hub_db_name is not null) ORDER BY sys_id ASC LIMIT 1 
    INTO _sys_id , _db, _nid,_area;


  WHILE _sys_id <> 0 DO

    SET @perm = 0;
    SET @resexpiry = NULL;
    SET @s = CONCAT("SELECT ",
      _db,".user_permission (?, ?) INTO @perm"
    );
    PREPARE stmt FROM @s;
    EXECUTE stmt USING _uid, _nid;
    DEALLOCATE PREPARE stmt; 

    
    SET @resexpiry = null;    
    SET @s = CONCAT("SELECT ",
      _db,".user_expiry (?, ?) INTO @resexpiry"
    );
    PREPARE stmt FROM @s;
    EXECUTE stmt USING _uid, _nid;
    DEALLOCATE PREPARE stmt;

   SELECT 'na' INTO _flag_expiry ;

    IF _area = 'share' THEN
        SET @expiry_time = NULL;
        SET @s = CONCAT("
          SELECT p.expiry_time
          FROM  ",_db,".permission p 
          INNER JOIN yp.dmz_token t ON p.entity_id = t.guest_id
          INNER JOIN yp.dmz_user u ON p.entity_id = u.id
          INNER JOIN yp.entity e ON e.id=  t.hub_id AND  e.home_id = t.node_id
          WHERE e.db_name='",_db,"' AND  u.id = @guest_id  INTO @expiry_time"
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

    
    UPDATE _temp_show_node s SET privilege = @perm, expiry_time = @resexpiry ,flag_expiry =_flag_expiry 
      WHERE sys_id = _sys_id;
    SELECT _sys_id INTO  _temp_sys_id ;  
    SELECT 0 , NULL,NULL INTO  _sys_id, _db , _area; 

    SELECT IFNULL(sys_id,0), IF(ftype = 'hub', hub_db_name, src_db_name), nid ,area
    FROM _temp_show_node WHERE sys_id >_temp_sys_id AND ftype = 'hub' AND hub_db_name IS NOT NULL ORDER BY sys_id ASC LIMIT 1 
    INTO _sys_id, _db, _nid,_area;

  END WHILE;


  DROP TABLE IF EXISTS _show_node;
  CREATE TEMPORARY TABLE _show_node  AS 
    SELECT * FROM _temp_show_node WHERE 
      (expiry_time = 0 OR expiry_time > UNIX_TIMESTAMP()) AND 
      privilege > 0 ORDER BY 
      CASE WHEN LCASE(_sort_by) = 'date' and LCASE(_order) = 'asc' THEN ctime END ASC,
      CASE WHEN LCASE(_sort_by) = 'date' and LCASE(_order) = 'desc' THEN ctime END DESC,
      CASE WHEN LCASE(_sort_by) = 'name' and LCASE(_order) = 'asc' THEN filename END ASC,
      CASE WHEN LCASE(_sort_by) = 'name' and LCASE(_order) = 'desc' THEN filename END DESC,
      CASE WHEN LCASE(_sort_by) = 'rank' and LCASE(_order) = 'asc' THEN rank END ASC,
      CASE WHEN LCASE(_sort_by) = 'rank' and LCASE(_order) = 'desc' THEN rank END DESC,
      CASE WHEN LCASE(_sort_by) = 'size' and LCASE(_order) = 'asc' THEN filesize END ASC,
      CASE WHEN LCASE(_sort_by) = 'size' and LCASE(_order) = 'desc' THEN filesize END DESC
    LIMIT _offset ,_range;

  ALTER table _show_node ADD hubs MEDIUMTEXT ;
  ALTER table _show_node ADD nodes MEDIUMTEXT ;
  ALTER table _show_node ADD actual_home_id VARCHAR(16) ;

  DROP TABLE IF EXISTS _node_tree; 
  CREATE TEMPORARY TABLE _node_tree (
    `seq`  int NOT NULL AUTO_INCREMENT,
    `heritage_id` varchar(16) CHARACTER SET ascii,
    `id` varchar(16) CHARACTER SET ascii,
    `parent_id` varchar(16) CHARACTER SET ascii, 
    `category` varchar(16) ,
    `new_file` int default 0, 
    PRIMARY KEY `seq`(`seq`)
  );

  INSERT INTO _node_tree 
  (heritage_id, id, parent_id ,category)
  WITH RECURSIVE mytree AS 
  ( 
    SELECT id heritage_id , id, parent_id ,category
    FROM media WHERE id IN  (
      SELECT nid from _show_node WHERE category in ('folder','hub' ) 
    ) AND   category in ('folder','hub' )
    UNION ALL
    SELECT t.heritage_id,m.id,m.parent_id ,m.category
    FROM media AS m JOIN mytree AS t ON m.parent_id = t.id AND
      t.category IN ('folder','hub' ) 
  ) SELECT heritage_id, id, parent_id ,category  FROM mytree;


  SELECT MAX(seq) FROM _node_tree  INTO _lvl; 
  SELECT id,category FROM _node_tree WHERE seq = _lvl 
  INTO _tempid  ,_category;

  WHILE ( _lvl >= 1 AND  _tempid IS NOT NULL) DO
    IF (_category = 'hub') THEN
      SET @_temp_read_cnt = 0; 
      SELECT db_name, home_id FROM yp.entity WHERE id = _tempid INTO _hub_db_name, @actual_home_id; 
      IF (_hub_db_name IS NOT NULL) THEN 
        SET @s = CONCAT(
          "SELECT IFNULL(SUM(is_new(metadata, owner_id, ?)), 0) FROM ", _hub_db_name ,
          ".media WHERE file_path not REGEXP '^/__(chat|trash)__' AND category != 'root' INTO @_temp_file_count"
        );
        PREPARE stmt FROM @s;
        EXECUTE stmt USING _uid;
        DEALLOCATE PREPARE stmt;
        UPDATE  _node_tree   SET new_file = @_temp_file_count WHERE id = _tempid;
        -- Optimization :  @actual_home_id is available from from yp.entity
        -- SET @s = CONCAT("SELECT id FROM ", 
        --   _hub_db_name ,".media WHERE parent_id='0' AND category = 'root' INTO @actual_home_id"
        -- );
        -- PREPARE stmt FROM @s;
        -- EXECUTE stmt;
        -- DEALLOCATE PREPARE stmt;
        UPDATE _show_node SET actual_home_id=@actual_home_id WHERE nid = _tempid;

      END IF;
    END IF;
    SELECT _lvl - 1  INTO _lvl; 
    SELECT NULL, NULL INTO _tempid,_category;
    SELECT id,category FROM _node_tree WHERE seq = _lvl 
    INTO _tempid,_category;
  END WHILE;

  UPDATE  _node_tree t 
  INNER JOIN media m USING(id) 
  SET t.new_file=is_new(m.metadata, owner_id, _uid)
  WHERE t.category <>  'hub'  AND t.category != 'root';

  UPDATE _show_node t 
  INNER JOIN ( SELECT  heritage_id , 
    SUM(new_file) new_file ,
    GROUP_CONCAT( CASE WHEN id <> heritage_id THEN  id  ELSE NULL END ) nodes,
    GROUP_CONCAT(CASE WHEN category = 'hub' AND id <> heritage_id THEN  id  ELSE NULL END ) hubs
  FROM _node_tree GROUP by heritage_id ) h ON nid = heritage_id

  SET t.new_file =h.new_file, t.nodes = h.nodes,t.hubs = h.hubs;

  SELECT
    nid,
    pid,
    parent_id,
    REGEXP_REPLACE(filepath, '/+', '/') filepath, 
    REGEXP_REPLACE(ownpath, '/+', '/') ownpath,
    holder_id,
    home_id,
    fc.capability capability,
    src_db_name,
    hub_db_name,
    hubname,
    accessibility,
    owner_id,
    status,
    filename,
    hub_id,
    IFNULL(area, _hub_area) area,
    filesize,
    vhost,
    isalink,
    caption,
    ext,
    metadata,
    view_count,
    geometry,
    ctime,
    mtime,
    COALESCE(fc.category, m.ftype) ftype,
    COALESCE(fc.category, m.ftype) filetype,
    COALESCE(fc.mimetype, m.mimetype) mimetype,
    JSON_VALUE(metadata, "$.md5Hash") AS md5Hash,
    new_file,
    page,
    rank,
    privilege,
    expiry_time,
    m.sys_id sys_id,
    hubs,
    nodes,
    IFNULL(actual_home_id, _home_id) actual_home_id,
    flag_expiry dmz_expiry
  FROM _show_node m 
    LEFT JOIN yp.filecap fc ON m.ext=fc.extension
  
  ORDER BY 
    CASE WHEN LCASE(_sort_by) = 'date' and LCASE(_order) = 'asc' THEN ctime END ASC,
    CASE WHEN LCASE(_sort_by) = 'date' and LCASE(_order) = 'desc' THEN ctime END DESC,
    CASE WHEN LCASE(_sort_by) = 'name' and LCASE(_order) = 'asc' THEN filename END ASC,
    CASE WHEN LCASE(_sort_by) = 'name' and LCASE(_order) = 'desc' THEN filename END DESC,
    CASE WHEN LCASE(_sort_by) = 'rank' and LCASE(_order) = 'asc' THEN rank END ASC,
    CASE WHEN LCASE(_sort_by) = 'rank' and LCASE(_order) = 'desc' THEN rank END DESC,
    CASE WHEN LCASE(_sort_by) = 'size' and LCASE(_order) = 'asc' THEN filesize END ASC,
    CASE WHEN LCASE(_sort_by) = 'size' and LCASE(_order) = 'desc' THEN filesize END DESC;

  DROP TABLE IF EXISTS _temp_show_node;
  DROP TABLE IF EXISTS _show_node;
  DROP TABLE IF EXISTS _node_tree;
END $

DELIMITER ;

