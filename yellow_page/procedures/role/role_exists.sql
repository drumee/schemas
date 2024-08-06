DELIMITER $

DROP PROCEDURE IF EXISTS `role_exists`$
CREATE PROCEDURE `role_exists`(
  IN _key VARCHAR(1000),
  IN _org_id VARCHAR(16)
)
BEGIN
    SELECT *  FROM role WHERE (name = _key  OR id = _key) AND org_id = _org_id; 
END $


DELIMITER ;