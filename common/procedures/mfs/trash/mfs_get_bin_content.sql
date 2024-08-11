DELIMITER $


--   NEED TO DELETE - GOPINATH 
-- ==============================================================
-- List all media in the trash bin
-- ==============================================================
-- DEPRECATED ??
DROP PROCEDURE IF EXISTS `mfs_get_bin_content`$
CREATE PROCEDURE `mfs_get_bin_content`(
  IN _id VARCHAR(16)
)
BEGIN
  DECLARE _node_path VARCHAR(255);
  DECLARE _category VARCHAR(40);
  DECLARE _home_dir VARCHAR(500);
  DECLARE _uid VARCHAR(16);

  -- DECLARE _sb_db_name VARCHAR(255);
  -- DECLARE _sb_home_dir VARCHAR(500);
  -- DECLARE _sb_id VARCHAR(500);

  DECLARE _db_name VARCHAR(50);
  DECLARE _finished INTEGER DEFAULT 0;
  DECLARE _hubid VARCHAR(16);
  

  
  -- SELECT s.db_name,s.home_dir,s.id FROM yp.entity e INNER JOIN 
  -- yp.hub sb on sb.owner_id=e.id INNER JOIN yp.entity s on s.id=sb.id  
  -- WHERE e.db_name = DATABASE() AND s.area='restricted'  INTO _sb_db_name, _sb_home_dir,_sb_id ; 

 
  SELECT id, home_dir FROM yp.entity WHERE db_name=database() INTO _uid, _home_dir;

  DROP TABLE IF EXISTS  _bin_media; 
  CREATE TEMPORARY TABLE `_bin_media` (
  `id` varchar(16) DEFAULT NULL,
  `hub_root` varchar(512) DEFAULT NULL,
  `owner_id` varchar(16) DEFAULT NULL,
  `mfs_root` varchar(500) DEFAULT NULL,
  `parent_id` varchar(16) NOT NULL DEFAULT '',
  `category`  varchar(16),  --  enum('hub', 'web' ,'folder','link','video','image','audio','document','stylesheet','script','vector','other') NOT NULL DEFAULT 'other',
  `privilege` tinyint(2) DEFAULT NULL,
  `user_filename` varchar(128) DEFAULT NULL,
  `parent_path` varchar(1024) DEFAULT NULL,
  `bound` varchar(128) DEFAULT '__Nobound__',
  `db_name` varchar(128) DEFAULT NULL
  ); 

  IF _id IS NULL OR _id="" OR _id='0' THEN
    INSERT INTO _bin_media  
    SELECT id, 
      (SELECT home_dir FROM yp.entity y WHERE y.id=m.id) AS hub_root,
      IFNULL((SELECT owner_id FROM yp.hub y WHERE y.id=m.id),_uid) AS owner_id,
      concat(_home_dir, "/__storage__/"), 
      parent_id,
      category, 
      user_permission(_uid, m.id) AS privilege, 
      user_filename, 
      concat(_home_dir, "/__storage__/", parent_path),
      '__Nobound__',
      IF(category='hub', 
        (SELECT db_name FROM yp.entity y WHERE y.id=m.id),
      database()) AS db_name
    FROM media m WHERE 
    parent_id NOT IN (SELECT id FROM media WHERE status='deleted')
    AND m.status='deleted';
    
    BEGIN
    DECLARE dbcursor CURSOR FOR  SELECT id, db_name FROM 
      yp.entity WHERE id IN(
         SELECT id FROM media m INNER JOIN permission p 
          ON p.resource_id = m.id AND p.permission>=15 AND m.status='active'
    );
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET _finished = 1;
    OPEN dbcursor;
     
      STARTLOOP: LOOP
        FETCH dbcursor INTO _hubid , _db_name ;
         IF _finished = 1 THEN 
            LEAVE STARTLOOP;
         END IF;    

        SET @sql = CONCAT("
          INSERT INTO _bin_media 
          SELECT 
            m.id,
            null as hub_root,
            null as owner_id,
            concat(e.home_dir, '/__storage__/'),
            parent_id,
            category,
            null as privilege,
            user_filename,
            concat(e.home_dir, '/__storage__/', parent_path) parent_path,
            '__Nobound__',
            " ,QUOTE(_db_name ),"
          FROM " ,_db_name ,".media m 
          INNER JOIN yp.entity e on e.id = ",QUOTE(_hubid),"  
         --  LEFT JOIN " ,_db_name ,".permission p on p.entity_id = ",QUOTE(_uid)," AND  p.resource_id = m.id
          WHERE 
         --  ( IFNULL(p.expiry_time,0) = 0 OR   IFNULL(p.expiry_time,0) > UNIX_TIMESTAMP() )
           parent_id NOT IN (SELECT id FROM " ,_db_name , ".media WHERE status='deleted')
          AND m.status='deleted'");
        PREPARE stmt FROM @sql ;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
      END LOOP STARTLOOP;   

    CLOSE dbcursor;
    END;
  ELSE
    INSERT INTO _bin_media 
    SELECT id, 
      (SELECT home_dir FROM yp.entity y WHERE y.id=m.id) AS hub_root,
      IFNULL((SELECT owner_id FROM yp.hub y WHERE y.id=m.id),_uid) AS owner_id,
      concat(_home_dir, "/__storage__/"),
      parent_id,
      category, 
      user_permission(_uid, _id) AS privilege, 
      user_filename, 
      concat(_home_dir, "/__storage__/", parent_path),
      null,
       IF(category='hub', 
        (SELECT db_name FROM yp.entity y WHERE y.id=m.id),
      database()) AS db_name
    FROM media m WHERE id=_id;

    BEGIN
    DECLARE dbcursor CURSOR FOR  SELECT id, db_name FROM  yp.entity WHERE id IN(
      SELECT id FROM media m INNER JOIN permission p 
          ON p.resource_id = m.id AND p.permission>=15 AND m.status='active');
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET _finished = 1;
    OPEN dbcursor;
     
      STARTLOOP: LOOP
        FETCH dbcursor INTO _hubid , _db_name ;
         IF _finished = 1 THEN 
            LEAVE STARTLOOP;
         END IF;    

        SET @sql = CONCAT("
          INSERT INTO _bin_media 
          SELECT 
            m.id,
            null as hub_root,
            null as owner_id,
            concat(e.home_dir, '/__storage__/'),
            parent_id,
            category,
            null as privilege,
            user_filename,
            concat(e.home_dir, '/__storage__/', parent_path) parent_path,
            '__Nobound__',
            " ,QUOTE(_db_name ),"
          FROM " ,_db_name ,".media m 
          INNER JOIN yp.entity e on e.id = ",QUOTE(_hubid),"  
          WHERE 
          m.id =" ,QUOTE(_id) );
        PREPARE stmt FROM @sql ;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
      END LOOP STARTLOOP;   

    CLOSE dbcursor;
    END;
  END IF;
  SELECT *  FROM _bin_media;
  DROP TABLE IF EXISTS _bin_media;
END $

DELIMITER ;

