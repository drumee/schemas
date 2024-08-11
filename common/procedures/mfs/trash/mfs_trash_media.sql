
DELIMITER $


DROP PROCEDURE IF EXISTS `mfs_empty_trash`$
CREATE PROCEDURE `mfs_empty_trash`()
BEGIN

  DECLARE _hub_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _db_name VARCHAR(60) CHARACTER SET ascii;
  DECLARE _home_dir VARCHAR(300) CHARACTER SET ascii;

  DECLARE exit handler for sqlexception
  BEGIN
  
    ROLLBACK;
  END;


  START TRANSACTION;

    DROP TABLE IF EXISTS `_hubs`; 
    CREATE  TEMPORARY TABLE `_hubs` 
    (
      hub_id varchar(16)  CHARACTER SET ascii DEFAULT NULL,
      db_name varchar(60)  CHARACTER SET ascii DEFAULT NULL,
      home_dir varchar(300)  CHARACTER SET ascii DEFAULT NULL,
      is_checked int default 0      
    );

    DROP TABLE IF EXISTS `_delete`; 
    CREATE  TEMPORARY TABLE `_delete` 
    (
      id varchar(16)  CHARACTER SET ascii DEFAULT NULL,
      hub_id varchar(16)  CHARACTER SET ascii DEFAULT NULL,
      db_name varchar(60)  CHARACTER SET ascii DEFAULT NULL,
      home_dir varchar(300)  CHARACTER SET ascii DEFAULT NULL
    );


    INSERT INTO _hubs
    SELECT id hub, db_name,home_dir,0 FROM 
    yp.entity WHERE id IN(
    SELECT id FROM media m INNER JOIN permission p 
    ON p.resource_id = m.id AND p.permission>=15 AND m.status='active' );
    INSERT INTO _hubs
    SELECT id, db_name,home_dir,0 FROM yp.entity WHERE db_name=database() ;

    SELECT hub_id,db_name,home_dir  FROM _hubs WHERE is_checked = 0 LIMIT 1 INTO _hub_id ,_db_name , _home_dir;
    WHILE  _hub_id IS NOT NULL DO 

        SET @st = CONCAT("UPDATE yp.disk_usage SET size = size - (SELECT IFNULL(SUM(filesize),0) FROM " ,_db_name, ".trash_media) WHERE hub_id =",QUOTE( _hub_id),";");
        PREPARE stmt FROM @st;
        EXECUTE stmt ;
        DEALLOCATE PREPARE stmt; 

        SET @st = CONCAT("INSERT INTO _delete (id ,hub_id )
            SELECT  id ,", QUOTE( _hub_id )," FROM ",_db_name, ".trash_media WHERE category NOT IN ('hub') ");
        PREPARE stmt FROM @st;
        EXECUTE stmt ;
        DEALLOCATE PREPARE stmt; 

        SET @st = CONCAT("DELETE FROM ",_db_name, ".trash_media");
        PREPARE stmt FROM @st;
        EXECUTE stmt ;
        DEALLOCATE PREPARE stmt; 

        UPDATE _delete SET db_name = _db_name ,home_dir =_home_dir WHERE  hub_id =_hub_id;

        UPDATE _hubs SET is_checked = 1 WHERE _hub_id =hub_id;
        SELECT NULL,NULL,NULL INTO _hub_id ,_db_name , _home_dir;
        SELECT hub_id,db_name,home_dir  FROM _hubs WHERE is_checked = 0 LIMIT 1 INTO _hub_id ,_db_name , _home_dir;


     END WHILE; 
  COMMIT;
  SELECT id,  CONCAT(home_dir, "/__storage__/") home_dir FROM _delete;

END$


DROP PROCEDURE IF EXISTS `mfs_delete_trash`$
CREATE PROCEDURE `mfs_delete_trash`(IN _nodes JSON)
BEGIN
  DECLARE _idx INT DEFAULT 0;
  DECLARE _nid VARCHAR(16) CHARACTER SET ascii;
  DECLARE _hub_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _db_name VARCHAR(60) CHARACTER SET ascii;
  DECLARE _home_dir VARCHAR(300) CHARACTER SET ascii;
 
  DECLARE exit handler for sqlexception
  BEGIN
    ROLLBACK;
  END;
   
  DECLARE exit handler for sqlwarning
  BEGIN
    ROLLBACK;
  END;

  START TRANSACTION;

  DROP TABLE IF EXISTS _mytree; 
  CREATE  TEMPORARY TABLE _mytree (
          id varchar(16)  CHARACTER SET ascii DEFAULT NULL,
          parent_id varchar(16)  CHARACTER SET ascii DEFAULT NULL,
          filesize bigint default 0,
          category varchar(16) NOT NULL DEFAULT 'other',
          hub_id varchar(16)  CHARACTER SET ascii DEFAULT NULL,
          home_dir VARCHAR(512) DEFAULT null,
          nid varchar(16)  CHARACTER SET ascii DEFAULT NULL
        );


  WHILE _idx < JSON_LENGTH(_nodes) DO 

    SELECT JSON_UNQUOTE(JSON_EXTRACT(_nodes, CONCAT("$[", _idx, "]"))) INTO @_node;
    SELECT JSON_VALUE(@_node, "$.nid") INTO _nid;
    SELECT JSON_VALUE(@_node, "$.hub_id") INTO _hub_id;

    SELECT  db_name,home_dir FROM yp.entity WHERE id = _hub_id INTO _db_name , _home_dir;
   
      SET @st = CONCAT
        ( " 
           INSERT INTO _mytree( id, nid,parent_id,category ,filesize )
           WITH RECURSIVE mytree AS (
            SELECT id, ", QUOTE(_nid)," nid, parent_id,category ,filesize 
            FROM ",_db_name,".trash_media WHERE id =", QUOTE(_nid),"
            UNION ALL
            SELECT m.id, ", QUOTE(_nid), " nid, m.parent_id ,m.category,m.filesize
            FROM ",_db_name,".trash_media AS m JOIN mytree AS t ON m.parent_id = t.id
          )
         SELECT id, nid, parent_id,category ,filesize FROM mytree;");

        PREPARE stmt FROM @st;
        EXECUTE stmt ;
        DEALLOCATE PREPARE stmt; 

        UPDATE _mytree 
        SET hub_id =_hub_id ,home_dir =_home_dir 
        WHERE  nid =_nid;


        SET @st = CONCAT("UPDATE yp.disk_usage SET size = size - 
            (SELECT SUM(filesize) FROM _mytree WHERE nid =",  QUOTE(_nid) ," ) 
            WHERE hub_id =",QUOTE( _hub_id),"");
        PREPARE stmt FROM @st;
        EXECUTE stmt ;
        DEALLOCATE PREPARE stmt; 

        SET @st = CONCAT ("DELETE FROM " ,_db_name,".trash_media 
          WHERE id IN (SELECT id FROM _mytree WHERE nid =",  QUOTE(_nid) ,")");
        PREPARE stmt FROM @st;
        EXECUTE stmt ;
        DEALLOCATE PREPARE stmt;



    SELECT _idx + 1 INTO _idx;
  END WHILE; 
  COMMIT;
  SELECT 
    id, category, parent_id,CONCAT(home_dir, "/__storage__/") home_dir
  FROM _mytree
  WHERE category NOT IN ('hub') ;

END$




DELIMITER ;

--   CALL mfs_delete_trash( '[{"nid":"10ec30fd10ec3109","hub_id":"46fb4fc946fb4fce"}]')



