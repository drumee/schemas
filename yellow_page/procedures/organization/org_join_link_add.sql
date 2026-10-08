DELIMITER $

-- =========================================================
-- org_join_link_add
-- =========================================================
-- Mint a department join link (setup wizard "Public link").
DROP PROCEDURE IF EXISTS `org_join_link_add`$
CREATE PROCEDURE `org_join_link_add`(
  IN _domain_id INT UNSIGNED, IN _departments LONGTEXT, IN _privilege TINYINT UNSIGNED,
  IN _expires_at INT UNSIGNED, IN _by VARCHAR(16)
)
proc: BEGIN
  DECLARE _id VARCHAR(32);
  IF _departments IS NULL OR JSON_VALID(_departments) = 0 OR JSON_LENGTH(_departments) = 0 THEN
    SELECT 'INVALID_DEPARTMENTS' AS error;
    LEAVE proc;
  END IF;
  SET _id = LOWER(REPLACE(UUID(), '-', ''));
  INSERT INTO org_join_link (id, domain_id, departments, privilege, expires_at, by_id, ctime)
    VALUES (_id, _domain_id, _departments, _privilege, IFNULL(_expires_at, 0), _by, UNIX_TIMESTAMP());
  SELECT _id AS id, _expires_at AS expires_at;
END$

DELIMITER ;
