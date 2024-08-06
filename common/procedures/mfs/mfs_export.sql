DELIMITER $



-- =========================================================
-- 
-- =========================================================

DROP PROCEDURE IF EXISTS `mfs_export`$
CREATE PROCEDURE `mfs_export`(
  IN _nodes JSON,
  IN _uid VARCHAR(16) CHARACTER SET ascii
)
BEGIN
  DECLARE _idx INT(4) DEFAULT 0; 
  DECLARE _shub_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _shub_db VARCHAR(40);
  DECLARE _shome_dir VARCHAR(512) DEFAULT null;
  DECLARE _nid VARCHAR(16) CHARACTER SET ascii;
  DECLARE _hubid VARCHAR(16) CHARACTER SET ascii;

 DROP TABLE IF EXISTS _mytree; 
    CREATE  TEMPORARY TABLE _mytree (
          id varchar(16)  CHARACTER SET ascii DEFAULT NULL,
          parent_id varchar(16)  CHARACTER SET ascii DEFAULT NULL,
         `is_root` boolean default 0 ,
          user_filename varchar(128),
          parent_path  varchar(4000),
          file_path varchar(4000),
          extension varchar(100),    
          mimetype varchar(100),
          category varchar(16),
          src_mfs_root VARCHAR(1024) DEFAULT null
        );


  WHILE _idx < JSON_LENGTH(_nodes) DO 
    SELECT get_json_array(_nodes, _idx) INTO @_node;
    SELECT get_json_object(@_node, "nid") INTO _nid;
    SELECT get_json_object(@_node, "hub_id") INTO _shub_id;


    SELECT db_name,home_dir FROM yp.entity WHERE id = _shub_id 
    INTO _shub_db,_shome_dir; 

      
 
      SET @st = CONCAT("SELECT parent_id, user_filename,extension FROM  ", _shub_db, ".media WHERE  id =? INTO  @parent_id , @user_filename,@extension ");
      PREPARE stmt3 FROM @st;
      EXECUTE stmt3 USING   _nid;
      DEALLOCATE PREPARE stmt3;

      SELECT CONCAT('/',name) ,'' FROM  yp.hub  WHERE @parent_id = '0' AND id =  _shub_id  INTO @user_filename ,@extension ; 
 
      SET @st = CONCAT("
        INSERT INTO _mytree
        WITH RECURSIVE mytree AS 
        (
              SELECT  id, 
              parent_id,1 is_root,
              @user_filename user_filename,
              CONCAT(IFNULL(@parent_path,''), IFNULL(@parent_name,''),'') parent_path,
              CASE WHEN  category ='folder' or extension = '' or parent_id = '0' 
                  THEN 
                    CONCAT(IFNULL(@parent_path,''), IFNULL(@parent_name,''),'/', IFNULL( @user_filename,'')) 
                  ELSE 
                    CONCAT(IFNULL(@parent_path,''), IFNULL(@parent_name,''),'/', IFNULL( @user_filename,''), '.',IFNULL(extension,''))  
                  END file_path,
              m.extension,m.mimetype,   
              CASE WHEN parent_id = '0' THEN 'folder' ELSE m.category END category,
              ", QUOTE(_shome_dir) , "src_mfs_root 
              FROM ",_shub_db,".media m WHERE  
              m.file_path not REGEXP '^/__(chat|trash)__' AND 
              m.status IN ('active', 'locked')   AND  id =", QUOTE(_nid) , "
              UNION ALL 
              SELECT  m.id, 
              m.parent_id , 0 is_root, 
              m.user_filename,
              CONCAT(IFNULL(t.parent_path,''), IFNULL(t.user_filename,''),'/') parent_path ,
              CASE WHEN  m.category ='folder' or m.extension = '' 
                  THEN 
                    CONCAT(IFNULL(t.parent_path,''), IFNULL(t.user_filename,''),'/', IFNULL(m.user_filename,'')) 
                  ELSE 
                    CONCAT(IFNULL(t.parent_path,''), IFNULL(t.user_filename,''),'/', IFNULL(m.user_filename,''), '.',IFNULL(m.extension,''))  
              END file_path,
              m.extension,m.mimetype,m.category,
              ", QUOTE(_shome_dir) , " src_mfs_root
              FROM ",_shub_db,".media m  JOIN mytree t on m.parent_id =t.id  WHERE  
              m.file_path not REGEXP '^/__(chat|trash)__' AND 
              m.status IN ('active', 'locked')
        )
        SELECT * FROM mytree;
        ");
      PREPARE stmt FROM @st;
      EXECUTE stmt ;
      DEALLOCATE PREPARE stmt;

    SELECT _idx + 1 INTO _idx;

  END WHILE; 

  DROP TABLE IF EXISTS _myhub; 

  CREATE  TEMPORARY TABLE _myhub (
      id varchar(16)  CHARACTER SET ascii DEFAULT NULL,
      parent_id varchar(16)  CHARACTER SET ascii DEFAULT NULL,
      `is_root` boolean default 0 ,
      user_filename varchar(128),
      parent_path  varchar(4000),
      file_path varchar(4000),
      extension varchar(100),    
      mimetype varchar(100),
      category varchar(16),
      src_mfs_root VARCHAR(1024) DEFAULT null
    );

    INSERT INTO _myhub
    SELECT * FROM _mytree WHERE category = 'hub';
    ALTER TABLE _myhub ADD `is_checked` boolean default 0 ;
 

    SELECT  id,parent_path,user_filename FROM _myhub where is_checked =0 LIMIT 1 INTO _hubid ,@parent_path,  @parent_name;


    WHILE (_hubid IS NOT NULL) do
     
      SELECT db_name,home_dir FROM yp.entity WHERE id = _hubid 
      INTO _shub_db,_shome_dir; 


      SET @st = CONCAT("SELECT id FROM  ", _shub_db, ".media WHERE  parent_id ='0'  INTO  @nid  ");
      PREPARE stmt3 FROM @st;
      EXECUTE stmt3 ;
      DEALLOCATE PREPARE stmt3;

      SELECT @nid  INTO _nid;

      
      SET @st = CONCAT("
        INSERT INTO _mytree
        WITH RECURSIVE mytree AS 
        (
              SELECT  id, 
              parent_id,0 is_root,
              user_filename,
              CONCAT(IFNULL(@parent_path,''), IFNULL(@parent_name,''),'/') parent_path,
              CASE WHEN  category ='folder' or extension = '' or parent_id = '0' 
                  THEN 
                    CONCAT(IFNULL(@parent_path,''), IFNULL(@parent_name,''),'/', IFNULL( user_filename,'')) 
                  ELSE 
                    CONCAT(IFNULL(@parent_path,''), IFNULL(@parent_name,''),'/', IFNULL( user_filename,''), '.',IFNULL(extension,''))  
                  END file_path,
              m.extension,m.mimetype,   
              CASE WHEN parent_id = '0' THEN 'folder' ELSE m.category END category,
              ", QUOTE(_shome_dir) , "src_mfs_root 
              FROM ",_shub_db,".media m WHERE  
              m.file_path not REGEXP '^/__(chat|trash)__' AND 
              m.status IN ('active', 'locked')   AND  parent_id =", QUOTE(_nid) , "
              UNION ALL 
              SELECT  m.id, 
              m.parent_id , 0 is_root, 
              m.user_filename,
              CONCAT(IFNULL(t.parent_path,''), IFNULL(t.user_filename,''),'/') parent_path ,
              CASE WHEN  m.category ='folder' or m.extension = '' 
                  THEN 
                    CONCAT(IFNULL(t.parent_path,''), IFNULL(t.user_filename,''),'/', IFNULL(m.user_filename,'')) 
                  ELSE 
                    CONCAT(IFNULL(t.parent_path,''), IFNULL(t.user_filename,''),'/', IFNULL(m.user_filename,''), '.',IFNULL(m.extension,''))  
              END file_path,
              m.extension,m.mimetype,m.category,
              ", QUOTE(_shome_dir) , " src_mfs_root
              FROM ",_shub_db,".media m  JOIN mytree t on m.parent_id =t.id  WHERE  
              m.file_path not REGEXP '^/__(chat|trash)__' AND 
              m.status IN ('active', 'locked')
        )
        SELECT * FROM mytree;
        ");
      PREPARE stmt FROM @st;
      EXECUTE stmt ;
      DEALLOCATE PREPARE stmt;

      
      UPDATE _myhub SET is_checked = 1 WHERE id = _hubid ;
      SELECT NULL INTO _hubid ;
      SELECT  id,parent_path,user_filename FROM _myhub where is_checked =0 LIMIT 1 INTO _hubid ,@parent_path,  @parent_name;

    END WHILE;
  
  SELECT  NULL ,NULL INTO @parent_path,  @parent_name;

  UPDATE _mytree SET  category = 'folder'  WHERE category = 'hub';

  SELECT  CASE WHEN  m.category ='folder' 
                    THEN ''
                    ELSE CONCAT( src_mfs_root,'__storage__/',id,'/orig.',extension )  
          END source  ,  
          file_path destination,
          m.category, 
          m.extension
  FROM _mytree m
  WHERE category NOT IN ( 'root');


END $

DELIMITER ;