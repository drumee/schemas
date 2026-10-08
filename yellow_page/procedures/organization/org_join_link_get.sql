DELIMITER $

-- =========================================================
-- org_join_link_get
-- =========================================================
-- One join link by token, with whether it is still usable.
DROP PROCEDURE IF EXISTS `org_join_link_get`$
CREATE PROCEDURE `org_join_link_get`(IN _id VARCHAR(32))
BEGIN
  SELECT id, domain_id, departments, privilege, expires_at, revoked, uses,
         IF(revoked = 0 AND (expires_at = 0 OR expires_at > UNIX_TIMESTAMP()), 1, 0) AS usable
    FROM org_join_link WHERE id = _id;
END$

DELIMITER ;
