DELIMITER $

DROP PROCEDURE IF EXISTS `get_org_user_storage_count`$
CREATE PROCEDURE `get_org_user_storage_count`(
  IN _domain_id INT(11) UNSIGNED
)
BEGIN
  -- Total user count for the domain — paired with get_org_user_storage so
  -- the FE Storage tab paginator can show "Showing 1-20 of N" instead of
  -- a page-only label. WHERE clause matches the data SP exactly.
  SELECT COUNT(*) AS total
  FROM yp.drumate d
  INNER JOIN yp.privilege p ON p.uid = d.id
  WHERE d.domain_id = _domain_id;
END$

DELIMITER ;
