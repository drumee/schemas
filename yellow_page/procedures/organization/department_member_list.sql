DELIMITER $

-- =========================================================
-- department_member_list
-- =========================================================
-- Who belongs to which department of an organisation: rows {department_id,
-- uid}. Joined to department so rows of a deleted department never surface.
DROP PROCEDURE IF EXISTS `department_member_list`$
CREATE PROCEDURE `department_member_list`(IN _domain_id INT UNSIGNED)
BEGIN
  SELECT m.department_id, m.uid
    FROM department_member m
   INNER JOIN department d ON d.id = m.department_id AND d.domain_id = m.domain_id
   WHERE m.domain_id = _domain_id;
END$

DELIMITER ;
