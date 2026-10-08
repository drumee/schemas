DELIMITER $

-- =========================================================
-- org_join_link_use
-- =========================================================
-- Count one redemption of a join link.
DROP PROCEDURE IF EXISTS `org_join_link_use`$
CREATE PROCEDURE `org_join_link_use`(IN _id VARCHAR(32))
BEGIN
  UPDATE org_join_link SET uses = uses + 1 WHERE id = _id;
  SELECT ROW_COUNT() AS updated;
END$

DELIMITER ;
