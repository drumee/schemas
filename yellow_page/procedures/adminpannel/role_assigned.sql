DELIMITER $
DROP PROCEDURE IF EXISTS `role_assigned`$
CREATE PROCEDURE `role_assigned`(
  IN _uid  VARCHAR(16),
  IN _org_id VARCHAR(16)
)
BEGIN
  SELECT
    r.id role_id,
    r.name role_name 
  FROM 
  map_role mr 
  INNER JOIN role r ON r.id = mr.role_id 
  WHERE  
  r.org_id =  _org_id  AND 
  mr.uid =_uid;

END $
DELIMITER ;