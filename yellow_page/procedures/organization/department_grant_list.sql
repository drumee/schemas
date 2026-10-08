DELIMITER $

-- =========================================================
-- department_grant_list
-- =========================================================
-- The workspace access department membership has granted in an organisation,
-- with the hub database each grant lives in.
DROP PROCEDURE IF EXISTS `department_grant_list`$
CREATE PROCEDURE `department_grant_list`(IN _domain_id INT UNSIGNED)
BEGIN
  SELECT g.hub_id, g.uid, g.privilege, g.prev_privilege, e.db_name AS hub_db
    FROM department_grant g
    LEFT JOIN entity e ON e.id = g.hub_id
   WHERE g.domain_id = _domain_id;
END$

DELIMITER ;
