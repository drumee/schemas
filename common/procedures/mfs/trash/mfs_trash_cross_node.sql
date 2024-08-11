DELIMITER $





--   NEED TO DELETE - GOPINATH 
-- =========================================================
-- TRASHING A NODE FROM A SHARED HUB
-- =========================================================
DROP PROCEDURE IF EXISTS `mfs_trash_cross_node`$
CREATE PROCEDURE `mfs_trash_cross_node`(
  IN _nid VARCHAR(16),
  IN _uid VARCHAR(16),
  IN _modify_perm TINYINT(4),
  OUT _output VARCHAR(1000)
)
BEGIN
  DECLARE _actual_perm TINYINT(4);
  DECLARE _ts INT(11) DEFAULT 0;
  -- DECLARE _filename VARCHAR(3000);

  -- SELECT UNIX_TIMESTAMP() INTO _ts;

  -- SELECT permission FROM permission WHERE resource_id ='*' AND entity_id = _uid INTO _actual_perm;



  -- IF CAST(_actual_perm AS UNSIGNED) < CAST(_modify_perm AS UNSIGNED) THEN
    
  --   INSERT IGNORE INTO permission
  --   SELECT null, _nid, _uid, null, -1, _ts, _ts, permission,'system' FROM 
  --   permission WHERE resource_id ='*' AND entity_id = _uid 
  --   ON DUPLICATE KEY UPDATE expiry_time = -1 ;
    
  --   SELECT user_filename FROM media where id= _nid INTO _output;
  -- ELSE 
  --   INSERT IGNORE INTO permission
  --   SELECT null, _nid, entity_id, null, -1, _ts, _ts, permission,'system' FROM 
  --   permission WHERE resource_id ='*' AND entity_id <> _uid 
  --   ON DUPLICATE KEY UPDATE expiry_time = -1 ;
     CALL mfs_trash_node (_nid);


     SET @st = CONCAT("SELECT  
      user_filename,category, extension 
      FROM  media WHERE id = ?
      INTO  @hub_file_name,@hub_category,@hub_extension" ) ; 
      PREPARE stmt3 FROM @st;
      EXECUTE stmt3 using _nid;
      DEALLOCATE PREPARE stmt3;  


      SET @st = CONCAT("CALL  hub_add_action_log (?,?,?,?,?,?)");
      PREPARE stamt FROM @st;
      EXECUTE stamt USING _uid,'deleted','media','all',null,CONCAT('The ',@hub_file_name, ' ',@hub_category,' has been deleted');
      DEALLOCATE PREPARE stamt;


    
  -- END IF ;


END $



DELIMITER ;
