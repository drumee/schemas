DELIMITER $

-- =========================================================
-- my_departments
-- =========================================================
-- The departmented workspaces ONE PERSON belongs to, with the department each
-- sits in: rows {hub_id, home_id, filename, area, filetype, department_id,
-- department_name, department_rank, members}. Feeds the topbar's
-- "Department-name v" crumb and its "Switch Departments" list for a caller
-- below dom_admin_security, who gets no inventory from org_departments /
-- org_workspaces (see organization.overview for why).
--
-- MEMBERSHIP COMES FROM THE CALLER'S OWN DATABASE, not from every hub's. The
-- member-side permission row (resource_id = hub id) is written beside the
-- hub-side '*' row by add_member / member_save_workspace_roles, so one read of
-- one database answers "which workspaces am I in" -- the same source
-- member_list_workspaces uses. Visiting each hub's permission table instead is
-- the cost org_department_members pays for an admin-only chart, and a topbar
-- crumb shown to everyone cannot pay it.
--
-- ONLY WORKSPACES THAT HAVE A DEPARTMENT. An ungrouped workspace has no crumb
-- to draw, and a department the caller has no workspace in is not theirs to
-- list: its name is the organisation's inventory, which stays admin-only.
--
-- Columns mirror org_workspaces (and through it a desk.home row) so the client
-- opens a workspace from either list through the same helper.
DROP PROCEDURE IF EXISTS `my_departments`$
CREATE PROCEDURE `my_departments`(
  IN _uid VARCHAR(16),
  IN _domain_id INT UNSIGNED
)
BEGIN
  DECLARE _db_name VARCHAR(255) CHARACTER SET ascii;

  SELECT db_name FROM entity WHERE id = _uid INTO _db_name;

  IF _db_name IS NULL OR _domain_id <= 1 THEN
    SELECT NULL AS hub_id, NULL AS department_id LIMIT 0;
  ELSE
    SET @my_departments_sql = CONCAT(
      'SELECT DISTINCT ',
      '  h.id AS hub_id, h.id AS id, e.home_id AS home_id, ',
      '  h.name AS filename, h.name AS name, h.hubname AS hubname, ',
      '  e.area AS area, ''hub'' AS filetype, ',
      '  h.department_id AS department_id, d.name AS department_name, ',
      '  d.`rank` AS department_rank, d.ctime AS department_ctime, ',
      '  IFNULL(w.members, 0) AS members ',
      'FROM `', _db_name, '`.permission p ',
      'INNER JOIN yp.entity e ON e.id = p.resource_id ',
      '  AND e.`type` = ''hub'' ',
      '  AND e.area IN (''private'', ''share'', ''restricted'') ',
      '  AND IFNULL(e.status, ''active'') NOT IN (''deleted'', ''archived'', ''frozen'') ',
      'INNER JOIN yp.hub h ON h.id = e.id ',
      'INNER JOIN yp.department d ON d.id = h.department_id AND d.domain_id = h.domain_id ',
      'LEFT JOIN yp.workspace_members w ON w.hub_id = h.id ',
      'WHERE p.entity_id = ', QUOTE(_uid),
      '  AND p.resource_id != ''*'' ',
      '  AND p.permission > 0 ',
      '  AND (p.expiry_time = 0 OR p.expiry_time > UNIX_TIMESTAMP()) ',
      '  AND h.domain_id = ', _domain_id,
      ' ORDER BY d.`rank`, d.ctime, h.name'
    );
    PREPARE _stmt FROM @my_departments_sql;
    EXECUTE _stmt;
    DEALLOCATE PREPARE _stmt;
  END IF;
END$

DELIMITER ;
