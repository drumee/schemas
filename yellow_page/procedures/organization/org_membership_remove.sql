DELIMITER $

-- =========================================================
-- org_membership_remove
-- =========================================================
-- Take a person out of a secondary organisation. Their primary one is not
-- touched. Returns {removed}.
DROP PROCEDURE IF EXISTS `org_membership_remove`$
CREATE PROCEDURE `org_membership_remove`(
  IN _domain_id INT UNSIGNED,
  IN _uid       VARCHAR(16)
)
BEGIN
  DELETE FROM org_membership WHERE uid = _uid AND domain_id = _domain_id;
  SELECT ROW_COUNT() AS removed;
END$

DELIMITER ;
