DELIMITER $

-- =========================================================
-- mfs_find
-- =========================================================
DROP PROCEDURE IF EXISTS `mfs_find`$
CREATE PROCEDURE `mfs_find`(
  IN _uid VARCHAR(512),
  IN _pattern VARCHAR(84),
  IN _page TINYINT(4)
)
BEGIN

  DECLARE _range bigint;
  DECLARE _offset bigint;
  DECLARE _finished       INTEGER DEFAULT 0; 
  DECLARE _nid VARCHAR(16);   
  CALL pageToLimits(_page, _offset, _range);
  
   

    
  CREATE TEMPORARY TABLE _search_node  AS     
  SELECT  
    m.id  as nid,
    m.extension as ext,
    m.origin_id  AS origin_id,
    m.file_path as filepath,
    COALESCE(he.id,me.id) AS hub_id,
    -- yp.get_vhost(COALESCE(he.ident,me.ident)) AS vhost,
    COALESCE(he.status,m.status) AS status,
    COALESCE(hh.name,m.user_filename) AS filename,
    COALESCE(me.space,m.filesize) AS filesize,
    _uid AS oid,
    ff.capability,
    IF(m.category='hub', m.extension, me.area) AS area,
    m.category as filetype,
    firstname,
    lastname,
    caption,
    upload_time as mtime,
    download_count as views,
    MATCH(`caption`,`user_filename`,`metadata`)
      against(_pattern IN NATURAL LANGUAGE MODE WITH QUERY EXPANSION)
    + IF(MATCH(`caption`,`user_filename`,`metadata`)
      against(concat(_pattern, '*') IN BOOLEAN MODE), 30, 0)
    + IF(user_filename = _pattern, 100, 0)
    + IF(user_filename LIKE concat("%", _pattern, "%"), 27, 0) AS score
    FROM media m  
    LEFT  JOIN yp.filecap ff ON m.extension=ff.extension
    LEFT  JOIN yp.entity he ON m.id = he.id AND m.category='hub'
    LEFT  JOIN yp.hub hh ON m.id = hh.id AND m.category='hub'
    INNER JOIN yp.drumate d  ON m.origin_id=d.id 
    INNER JOIN yp.entity me  ON me.db_name=database()
    WHERE  m.status='active'
    HAVING  score > 25
     LIMIT _offset, _range;
    
    ALTER table _search_node ADD privilege  tinyint(4) unsigned ;
    ALTER table _search_node ADD expiry_time int(11) ;
    
    BEGIN
      DECLARE dbcursor CURSOR FOR SELECT  nid FROM _search_node;
      DECLARE CONTINUE HANDLER FOR NOT FOUND SET _finished = 1; 
      OPEN dbcursor;
        STARTLOOP: LOOP
          FETCH dbcursor INTO _nid;
          
            IF _finished = 1 THEN 
              LEAVE STARTLOOP;
            END IF;
          
            SET @perm = 0;
            SET @s = CONCAT("SELECT user_permission (", QUOTE(_uid),",",QUOTE(_nid), ") INTO @perm");
            PREPARE stmt FROM @s;
            EXECUTE stmt;
            DEALLOCATE PREPARE stmt; 
            
            SET @resexpiry = null;    
            SET @s = CONCAT("SELECT user_expiry (", QUOTE(_uid),",",QUOTE(_nid), ") INTO @resexpiry");
            PREPARE stmt FROM @s;
            EXECUTE stmt;
            DEALLOCATE PREPARE stmt;

            UPDATE   _search_node SET privilege = @perm ,expiry_time = @resexpiry WHERE nid = _nid;

          END LOOP STARTLOOP; 
      CLOSE dbcursor;
    END; 
    
    -- SELECT nid,ext,origin_id,oid,capability,area, filetype,filename,firstname,lastname,caption,filesize,mtime, views,score ,privilege              
    SELECT * FROM _search_node WHERE (expiry_time = 0 OR expiry_time > UNIX_TIMESTAMP())
    ORDER BY score DESC, mtime ASC LIMIT _offset, _range;

    DROP TABLE IF EXISTS _search_node;
END $



-- =========================================================
-- media_search
-- =========================================================
DROP PROCEDURE IF EXISTS `media_search`$
CREATE PROCEDURE `media_search`(
  IN _pattern VARCHAR(84),
  IN _page TINYINT(4)
)
BEGIN

  DECLARE _range bigint;
  DECLARE _offset bigint;
  DECLARE _finished       INTEGER DEFAULT 0; 
  DECLARE _nid VARCHAR(16);   
  DECLARE _uid VARCHAR(16);
  DECLARE _db_name VARCHAR(50);
  DECLARE _sys_id INT;
  DECLARE _temp_sys_id INT;
  DECLARE _db VARCHAR(400);

  CALL pageToLimits(_page, _offset, _range);


  
  SELECT id FROM yp.entity where db_name = DATABASE() INTO _uid;   

  DROP TABLE IF EXISTS _search_node;
  CREATE TEMPORARY TABLE _search_node  AS     
  SELECT  
    m.id  as nid,
    m.parent_id AS parent_id,
    m.extension as ext,
    m.origin_id  AS origin_id,
    filepath(m.id) as filepath,
    cast( he.db_name    as VARCHAR(5000))AS hub_db_name, 
    COALESCE(he.id,me.id) AS hub_id,
    cast(null   as VARCHAR(5000))AS hub_name ,
    COALESCE(he.status,m.status) AS status,
    COALESCE(hh.name,m.user_filename) AS filename,
    COALESCE(me.space,m.filesize) AS filesize,
    _uid AS oid,
    ff.capability,
    IF(m.category='hub', he.area, me.area) AS area,
    m.category as filetype,
    null firstname,
    null lastname,
    caption,
    upload_time as mtime,
    publish_time as ctime,
    download_count as views,
    IF(COALESCE(hh.name,m.user_filename) = _pattern, 100, 0)
    + IF(COALESCE(hh.name,m.user_filename) LIKE concat("%", _pattern, "%"), 50, 0) AS score,
    user_expiry(_uid, m.id ) expiry_time,
    user_permission(_uid, m.id ) privilege
    FROM media m  
    INNER JOIN yp.entity me  ON me.db_name=database()
    LEFT JOIN yp.filecap ff ON m.extension=ff.extension
    LEFT JOIN yp.entity he ON m.id = he.id AND m.category='hub'
    LEFT JOIN yp.hub hh ON m.id = hh.id AND m.category='hub'
    --   INNER JOIN yp.drumate d  ON m.origin_id=d.id 
    WHERE  m.status IN ('active', 'locked')  AND
    m.file_path not REGEXP '^/__(chat|trash)__'  AND
    m.`status` != 'hidden' 
    HAVING  score > 25 AND privilege > 0  AND
    (expiry_time = 0 OR expiry_time > UNIX_TIMESTAMP());

    ALTER TABLE _search_node ADD sys_id INT PRIMARY KEY AUTO_INCREMENT;

    SELECT sys_id, IF(filetype = 'hub', hub_db_name, null), IF(filetype = 'hub', nid, null) 
    FROM _search_node WHERE sys_id > 0  AND  (hub_db_name is not null) ORDER BY sys_id ASC LIMIT 1 
    INTO _sys_id , _db, _nid;

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

        
        UPDATE _search_node s SET privilege = @perm, expiry_time = @resexpiry  
          WHERE sys_id = _sys_id;
        SELECT _sys_id INTO  _temp_sys_id ;  
        SELECT 0 , NULL INTO  _sys_id, _db ; 

        SELECT IFNULL(sys_id,0), IF(filetype = 'hub', hub_db_name, null), nid 
        FROM _search_node WHERE sys_id >_temp_sys_id AND filetype = 'hub' AND hub_db_name IS NOT NULL ORDER BY sys_id ASC LIMIT 1 
        INTO _sys_id, _db, _nid;

    END WHILE;

    BEGIN
        DECLARE dbcursor CURSOR FOR 
          SELECT db_name , id FROM yp.entity WHERE id IN (
            SELECT id FROM media m INNER JOIN permission p 
              ON p.resource_id = m.id AND m.status='active'
          );
        DECLARE CONTINUE HANDLER FOR NOT FOUND SET _finished = 1;
        OPEN dbcursor;
          STARTLOOP: LOOP
            FETCH dbcursor INTO _db_name , _nid;
            IF _finished = 1 THEN 
                LEAVE STARTLOOP;
            END IF;  

            SELECT NULL INTO @file_path;
            SELECT parent_path(_nid) INTO @parent_path;
            SELECT  name  FROM  yp.hub WHERE id = _nid  INTO @hub_name;
        

            SET @sql = CONCAT("
             INSERT INTO  _search_node 
             SELECT  
              m.id  as nid,
              m.parent_id AS parent_id,
              m.extension as ext,
              m.origin_id  AS origin_id,
              CONCAT (  @parent_path , @hub_name, ", _db_name,".filepath(m.id))  as filepath,
              null,
              COALESCE(he.id,me.id) AS hub_id,
              @hub_name hub_name,  
              COALESCE(he.status,m.status) AS status,
              COALESCE(hh.name,m.user_filename) AS filename,
              COALESCE(me.space,m.filesize) AS filesize,
              ? AS oid,
              ff.capability,
              IF(m.category='hub', he.area, me.area) AS area,
              m.category as filetype,
              null firstname,
              null lastname,
              caption,
              upload_time as ctime,
              publish_time as mtime,
              download_count as views,
              IF(COALESCE(hh.name,m.user_filename) = ",QUOTE(_pattern),", 100, 0)
              + IF(COALESCE(hh.name,m.user_filename) LIKE concat('%',",QUOTE( _pattern) ,", '%'), 50, 0) AS score,
              ", _db_name,".user_expiry(?, m.id ) expiry_time,
              ", _db_name,".user_permission(?, m.id ) privilege,
              NULL  
              FROM ", _db_name,".media m  
              INNER JOIN yp.entity me  ON me.db_name=",QUOTE(_db_name)," 
              LEFT JOIN yp.filecap ff ON m.extension=ff.extension
              LEFT JOIN yp.entity he ON m.id = he.id AND m.category='hub'
              LEFT JOIN yp.hub hh ON m.id = hh.id AND m.category='hub'
              -- INNER JOIN yp.drumate d  ON m.origin_id=d.id 
              WHERE  m.status IN ('active', 'locked') AND
              m.file_path not REGEXP '^/__(chat|trash)__'  AND
              m.`status` != 'hidden' 
              HAVING  score > 25 AND privilege > 0  AND
              (expiry_time = 0 OR expiry_time > UNIX_TIMESTAMP())
          ");

          PREPARE stmt FROM @sql;
          EXECUTE stmt USING _uid,_uid,_uid;
          DEALLOCATE PREPARE stmt;   
          END LOOP STARTLOOP;   
        CLOSE dbcursor;
    END;  
             
    SELECT * FROM _search_node WHERE (expiry_time = 0 OR expiry_time > UNIX_TIMESTAMP())
    ORDER BY score DESC, mtime ASC LIMIT _offset, _range;
    DROP TABLE IF EXISTS _search_node;
END $



-- =========================================================
-- mfs_search
-- new version of mfs_search, with category
-- =========================================================
DROP PROCEDURE IF EXISTS `mfs_search`$
CREATE PROCEDURE `mfs_search`(
  IN _pattern VARCHAR(84),
  IN _cat VARCHAR(84),
  IN _page TINYINT(4)
)
BEGIN

  DECLARE _range bigint;
  DECLARE _offset bigint;
  CALL pageToLimits(_page, _offset, _range);

  SELECT   
    media.id   as nid,
    origin_id  AS origin_id,
    @entity_id AS oid,
    extension as ext,
    media.category as filetype,
    user_filename as filename,
    firstname,
    lastname,
    caption,
    filesize,
    upload_time as mtime,
    download_count as views,
    MATCH(`caption`,`user_filename`,`file_path`,`metadata`)
      against(_pattern IN NATURAL LANGUAGE MODE WITH QUERY EXPANSION)
    + IF(MATCH(`caption`,`user_filename`,`file_path`,`metadata`)
      against(concat(_pattern, '*') IN BOOLEAN MODE), 30, 0)
    + IF(user_filename = _pattern, 100, 0)
    + IF(user_filename LIKE concat("%", _pattern, "%"), 27, 0) AS score
    FROM media INNER JOIN yp.drumate ON origin_id=drumate.id HAVING  score > 25 
    AND media.category=_cat
    ORDER BY score DESC, mtime ASC LIMIT _offset, _range;
END $

DELIMITER ;


