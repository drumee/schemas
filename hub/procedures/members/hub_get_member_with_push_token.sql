DELIMITER $
DROP PROCEDURE IF EXISTS `hub_get_member_with_push_token_next`$
CREATE PROCEDURE `hub_get_member_with_push_token_next`( 
IN  _exclude_id VARCHAR(16) CHARACTER SET ascii )
BEGIN

    IF rtrim(ltrim(_exclude_id)) IN ('',  '0') THEN 
      SELECT NULL INTO  _exclude_id;
    END IF;

  SELECT  
    d.id,
    d.email,
    dr.push_token,
    dr.device_id
    FROM permission p 
    INNER JOIN yp.drumate d on p.entity_id = d.id
    INNER JOIN yp.device_registation dr on d.id = dr.uid
    WHERE resource_id="*"  AND d.id <>_exclude_id ;

END$
DELIMITER ;