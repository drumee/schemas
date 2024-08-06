DELIMITER $
DROP PROCEDURE IF EXISTS `org_ident_exists`$
CREATE PROCEDURE `org_ident_exists`(
  IN _key VARCHAR(128)
)
BEGIN
  SELECT * FROM 
  (SELECT d.id, d.username ident,'active' status FROM drumate d INNER JOIN privilege p ON p.uid =d.id AND p.domain_id =1  WHERE username=_key  LIMIT 1) a 
  UNION
  SELECT id ,ident, 'active' status FROM  organisation WHERE ident=_key LIMIT 1;
END$
DELIMITER ;