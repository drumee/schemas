DELIMITER $



DROP PROCEDURE IF EXISTS `domain_grant`$
CREATE PROCEDURE `domain_grant`(
  IN _domain_id INT,
  IN _privilege TINYINT(4),
  IN _uid VARCHAR(16),
  IN _show_results    BOOLEAN

)
BEGIN
   
  INSERT IGNORE INTO privilege (uid,privilege,domain_id)
  VALUES( _uid,_privilege, _domain_id)
  ON DUPLICATE KEY UPDATE privilege=_privilege , domain_id = _domain_id ;
  
  IF IFNULL(_show_results, 0) != 0  THEN
     SELECT p.* FROM privilege p WHERE p.uid =_uid AND domain_id = _domain_id;
  END IF ;
END $


DELIMITER ;