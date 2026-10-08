DELIMITER $

-- =========================================================
-- department_member_remove
-- =========================================================
-- Take a person out of a department (their workspace access granted by it is
-- taken back by the caller's reconcile, not here).
DROP PROCEDURE IF EXISTS `department_member_remove`$
CREATE PROCEDURE `department_member_remove`(
  IN _domain_id INT UNSIGNED, IN _department_id VARCHAR(16), IN _uid VARCHAR(16)
)
BEGIN
  DELETE FROM department_member
   WHERE domain_id = _domain_id AND department_id = _department_id AND uid = _uid;
  SELECT ROW_COUNT() AS removed;
END$

DELIMITER ;
