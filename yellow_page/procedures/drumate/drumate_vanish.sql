DELIMITER $


DROP PROCEDURE IF EXISTS `drumate_vanish`$
CREATE PROCEDURE `drumate_vanish`(
 IN _key VARBINARY(80)
)
BEGIN
  DECLARE _domain_id INT(4);
  DECLARE _id VARCHAR(16);
  DECLARE _ident VARBINARY(80);
  DECLARE _type VARCHAR(80);
  DECLARE _db VARCHAR(80);
  DECLARE _home_dir VARCHAR(512);
  DECLARE _src_home_dir VARCHAR(512);
  DECLARE _entity_db VARCHAR(20);
  DECLARE _sys_id INT;
  DECLARE _temp_sys_id INT;
  DECLARE _drumate_id VARCHAR(16);
  DECLARE _drumate_domain_id INT(4);
  DECLARE _drumate_db VARCHAR(100);
  DECLARE _email VARCHAR(1000);
  DECLARE _rid VARCHAR(16) ;

  DECLARE _src_db_name VARCHAR(100);

  SELECT id, ident,`type`, db_name, home_dir FROM entity
  WHERE id=_key  INTO _id, _ident, _type, _db, _home_dir;

  -- -- To get source sharebox db 
  -- SELECT db_name,home_dir FROM yp.entity WHERE id=( SELECT sb.id FROM yp.hub sb 
  -- INNER JOIN yp.entity e ON e.id = sb.id WHERE sb.owner_id =_id AND  e.area='restricted' ) INTO _src_db_name,_src_home_dir;   


  SELECT email FROM drumate WHERE id = _id  INTO _email;  
  SELECT domain_id FROM privilege WHERE uid = _id INTO _domain_id;



  /* Clear refrences contact manager */

  SELECT 0 INTO _sys_id; 
  SELECT sys_id  FROM drumate WHERE sys_id > 0  ORDER BY sys_id ASC LIMIT 1 INTO _sys_id;
 
  WHILE _sys_id <> 0 DO
     
    SELECT NULL,NULL,NULL INTO _drumate_id,_drumate_domain_id,_drumate_db;
    SELECT id  FROM  drumate WHERE sys_id = _sys_id INTO _drumate_id; 
    SELECT domain_id FROM privilege WHERE uid = _drumate_id  ORDER BY domain_id DESC  LIMIT 1  INTO _drumate_domain_id;
    SELECT db_name FROM entity WHERE status <> 'deleted' AND id = _drumate_id INTO _drumate_db;


     IF ( _drumate_id IS NOT NULL AND _drumate_domain_id IS NOT NULL AND _drumate_db IS NOT NULL) THEN
      IF (_drumate_domain_id = _domain_id) THEN   -- SAME domain  user
          SET @st = CONCAT('DELETE FROM ', _drumate_db ,'.contact_email WHERE contact_id  = (SELECT id FROM ', _drumate_db ,'.contact WHERE uid =? or entity = ? or uid = ? or entity =? )');
          PREPARE stamt FROM @st;
          EXECUTE stamt USING _id,_id,_email,_email;
          DEALLOCATE PREPARE stamt;

          SET @st = CONCAT('DELETE FROM ', _drumate_db ,'.contact WHERE uid =? or entity = ? or uid = ? or entity =?');
          PREPARE stamt FROM @st;
          EXECUTE stamt USING _id,_id,_email,_email;
          DEALLOCATE PREPARE stamt; 
      END IF ;
      IF (_drumate_domain_id <> _domain_id) THEN    -- cross domain user


          SET @st = CONCAT('DELETE FROM ', _drumate_db ,'.contact WHERE (uid =? or entity = ? or uid = ? or entity =?) AND status="received"');
          PREPARE stamt FROM @st;
          EXECUTE stamt USING _id,_id,_email,_email;
          DEALLOCATE PREPARE stamt; 

          SET @st = CONCAT('UPDATE ', _drumate_db ,'.contact_email SET  is_default = 0 WHERE   is_default = 1 AND contact_id  = (SELECT id FROM ', _drumate_db ,'.contact WHERE uid =? or entity = ? or uid = ? or entity =? )');
          PREPARE stamt FROM @st;
          EXECUTE stamt USING _id,_id,_email,_email;
          DEALLOCATE PREPARE stamt;


          SET @st = CONCAT('DELETE FROM ', _drumate_db ,'.contact_email WHERE  email =? AND contact_id  = (SELECT id FROM ', _drumate_db ,'.contact WHERE uid =? or entity = ? or uid = ? or entity =? )');
          PREPARE stamt FROM @st;
          EXECUTE stamt USING _email,_id,_id,_email,_email;
          DEALLOCATE PREPARE stamt;


          SET @st = CONCAT('INSERT INTO ', _drumate_db ,'.contact_email (id,email,category,ctime,mtime ,contact_id ,is_default )
          SELECT  yp.uniqueId(),?,"priv",UNIX_TIMESTAMP(),UNIX_TIMESTAMP(),id,1 FROM ', _drumate_db ,'.contact WHERE uid =? or entity = ? or uid = ? or entity =? 
          ON DUPLICATE KEY UPDATE is_default =1');
          PREPARE stamt FROM @st;
          EXECUTE stamt USING _email,_id,_id,_email,_email;
          DEALLOCATE PREPARE stamt;


          SET @st = CONCAT('UPDATE ', _drumate_db ,'.contact SET category ="independant", metadata = JSON_OBJECT("source",? ), status="memory", uid = null, entity=? WHERE uid =? or entity =? or uid = ? or entity =?');
          PREPARE stamt FROM @st;
          EXECUTE stamt USING  _email,_email,_id,_id,_email,_email;
          DEALLOCATE PREPARE stamt; 
      END IF;  
     END IF; 

    SELECT _sys_id INTO  _temp_sys_id ;  
    SELECT 0 INTO  _sys_id ; 
    SELECT IFNULL(sys_id,0)  FROM drumate WHERE sys_id >_temp_sys_id ORDER BY sys_id ASC  LIMIT 1 INTO _sys_id;
  END WHILE;

  UPDATE drumate SET `profile` =  JSON_SET(`profile`, "$.firstname",'Deleted acccount' ) WHERE id=_id;
  UPDATE drumate SET `profile` =  JSON_SET(`profile`, "$.lastname",'Deleted account' ) WHERE id=_id;

   UPDATE drumate SET `profile` =  JSON_SET(`profile`, "$.email",_id ) WHERE id=_id;
   UPDATE entity SET status = 'deleted' WHERE id = _id;
   
   DELETE FROM entity WHERE id = _id;
   DELETE FROM drumate WHERE id = _id;
   DELETE FROM privilege WHERE uid = _id;
   DELETE FROM cookie WHERE uid=_id;
   DELETE FROM vhost  WHERE id = _id;
   DELETE FROM contact_sync  WHERE uid = _id;
   DELETE FROM contact_sync  WHERE owner_id = _id;
  IF _db IS NOT NULL OR _db!="" THEN
    SET @s = CONCAT("DROP DATABASE `", _db, "`");
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;


 IF _src_db_name IS NOT NULL OR _src_db_name!="" THEN
    SET @s = CONCAT("DROP DATABASE `", _src_db_name, "`");
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;


  SELECT _id id, _ident ident, _type type, _db db_name, _home_dir home_dir, _src_home_dir sb_home_dir;

END$

DELIMITER ;
