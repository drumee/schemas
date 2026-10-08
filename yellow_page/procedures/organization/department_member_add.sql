DELIMITER $

-- =========================================================
-- department_member_add
-- =========================================================
-- Put a person in a department. The department must be this organisation's
-- (DEPARTMENT_NOT_FOUND otherwise — an id from another tenant is refused).
-- Idempotent: adding someone already there is not an error.
DROP PROCEDURE IF EXISTS `department_member_add`$
CREATE PROCEDURE `department_member_add`(
  IN _domain_id INT UNSIGNED, IN _department_id VARCHAR(16),
  IN _uid VARCHAR(16), IN _by VARCHAR(16)
)
proc: BEGIN
  IF NOT EXISTS (SELECT 1 FROM department WHERE id = _department_id AND domain_id = _domain_id) THEN
    SELECT 'DEPARTMENT_NOT_FOUND' AS error;
    LEAVE proc;
  END IF;
  INSERT IGNORE INTO department_member (domain_id, department_id, uid, by_id, ctime)
    VALUES (_domain_id, _department_id, _uid, _by, UNIX_TIMESTAMP());
  SELECT _department_id AS department_id, _uid AS uid;
END$

DELIMITER ;
