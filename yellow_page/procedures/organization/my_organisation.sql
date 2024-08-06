DELIMITER $
DROP PROCEDURE IF EXISTS `my_organisation`$
CREATE PROCEDURE `my_organisation`(
   IN _uid VARCHAR(16) CHARACTER SET ascii
)
BEGIN
  SELECT
    r.*,
    r.link `url`,
    p.privilege
  FROM 
    privilege p
  INNER JOIN organisation r ON r.domain_id = p.domain_id 
  WHERE (p.domain_id <> 1 OR JSON_VALUE(r.metadata, "$.isOrganization")=1) AND p.uid = _uid; 
END$

DELIMITER ;
