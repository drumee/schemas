DELIMITER $

-- =========================================================
-- org_membership_set
-- =========================================================
-- Add a person to an organisation as a SECONDARY organisation, or change
-- their privilege there (1 member ... 63 owner). Refused for the person's
-- primary organisation (that standing lives in the privilege table) and
-- for anyone the platform does not know.
--
-- Errors: USER_NOT_FOUND, NO_ORG, ALREADY_PRIMARY_MEMBER.
DROP PROCEDURE IF EXISTS `org_membership_set`$
CREATE PROCEDURE `org_membership_set`(
  IN _domain_id INT UNSIGNED,
  IN _uid       VARCHAR(16),
  IN _privilege INT UNSIGNED,
  IN _by        VARCHAR(16)
)
proc: BEGIN
  DECLARE _primary INT DEFAULT NULL;

  SELECT domain_id INTO _primary FROM drumate WHERE id = _uid LIMIT 1;
  IF _primary IS NULL THEN
    SELECT 'USER_NOT_FOUND' AS error;
    LEAVE proc;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM organisation WHERE domain_id = _domain_id) THEN
    SELECT 'NO_ORG' AS error;
    LEAVE proc;
  END IF;
  IF _primary = _domain_id OR EXISTS (SELECT 1 FROM privilege WHERE uid = _uid AND domain_id = _domain_id) THEN
    SELECT 'ALREADY_PRIMARY_MEMBER' AS error;
    LEAVE proc;
  END IF;

  INSERT INTO org_membership (uid, domain_id, privilege, by_id, ctime)
  VALUES (_uid, _domain_id, GREATEST(1, LEAST(63, IFNULL(_privilege, 1))), _by, UNIX_TIMESTAMP())
  ON DUPLICATE KEY UPDATE privilege = VALUES(privilege);

  SELECT uid, domain_id, privilege FROM org_membership
   WHERE uid = _uid AND domain_id = _domain_id;
END$

DELIMITER ;
