DELIMITER $


DROP PROCEDURE IF EXISTS `role_get`$
CREATE PROCEDURE `role_get`(
  IN _org_id VARCHAR(16),
  IN _page INT(6)
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
    
  CALL pageToLimits(_page, _offset, _range);

  SELECT 
     _page as `page`,
     id role_id, name ,org_id  ,position 
  FROM 
    role 
  WHERE org_id =  _org_id 
  ORDER BY position ASC
  LIMIT _offset, _range;  

END $


DELIMITER ;