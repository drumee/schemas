DELIMITER $

-- =========================================================
-- department_desired_grants
-- =========================================================
-- What department membership SHOULD grant, before titles are applied: one row
-- per (member, workspace of one of their departments) with the member's title
-- and the workspace's database. The service turns title + access rules into a
-- privilege and compares with department_grant.
DROP PROCEDURE IF EXISTS `department_desired_grants`$
CREATE PROCEDURE `department_desired_grants`(IN _domain_id INT UNSIGNED)
BEGIN
  SELECT m.uid, h.id AS hub_id, e.db_name AS hub_db, m.department_id, t.title
    FROM department_member m
   INNER JOIN department d ON d.id = m.department_id AND d.domain_id = m.domain_id
   INNER JOIN hub h ON h.department_id = m.department_id AND h.domain_id = m.domain_id
   INNER JOIN entity e ON e.id = h.id AND e.`type` = 'hub'
     AND e.area IN ('private', 'share', 'restricted')
     AND IFNULL(e.status, 'active') NOT IN ('deleted', 'archived', 'frozen')
    LEFT JOIN member_title t ON t.domain_id = m.domain_id AND t.uid = m.uid
   WHERE m.domain_id = _domain_id;
END$

DELIMITER ;
