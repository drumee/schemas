DELIMITER $

-- =========================================================
-- org_join_link_revoke
-- =========================================================
-- Revoke a join link of this organisation.
DROP PROCEDURE IF EXISTS `org_join_link_revoke`$
CREATE PROCEDURE `org_join_link_revoke`(IN _domain_id INT UNSIGNED, IN _id VARCHAR(32))
BEGIN
  UPDATE org_join_link SET revoked = 1 WHERE id = _id AND domain_id = _domain_id;
  SELECT ROW_COUNT() AS revoked;
END$

DELIMITER ;
