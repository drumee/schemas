DELIMITER $

-- =========================================================
-- my_ungrouped_workspaces
-- =========================================================
-- The workspaces of one organisation ONE PERSON belongs to that sit in no
-- department: rows {hub_id, home_id, filename, area, filetype, department_id
-- (NULL), privilege, members}. The other half of my_departments, for the
-- organisation screen of a caller below dom_admin_security: without it a
-- workspace they made outside every department showed nowhere in their
-- organisation, since their personal home hides the organisation's
-- workspaces.
--
-- Same source as my_departments: the caller's OWN permission rows, so a
-- workspace they are not in is never named. A department_id that points at a
-- department which is gone counts as none (my_departments drops it too).
DROP PROCEDURE IF EXISTS `my_ungrouped_workspaces`$
CREATE PROCEDURE `my_ungrouped_workspaces`(
  IN _uid VARCHAR(16),
  IN _domain_id INT UNSIGNED
)
BEGIN
  DECLARE _db_name VARCHAR(255) CHARACTER SET ascii;

  SELECT db_name FROM entity WHERE id = _uid INTO _db_name;

  IF _db_name IS NULL OR _domain_id <= 1 THEN
    SELECT NULL AS hub_id, NULL AS department_id LIMIT 0;
  ELSE
    SET @my_ungrouped_sql = CONCAT(
      'SELECT DISTINCT ',
      '  h.id AS hub_id, h.id AS id, e.home_id AS home_id, ',
      '  h.name AS filename, h.name AS name, h.hubname AS hubname, ',
      '  e.area AS area, ''hub'' AS filetype, ',
      '  NULL AS department_id, p.permission AS privilege, ',
      '  IFNULL(w.members, 0) AS members ',
      'FROM `', _db_name, '`.permission p ',
      'INNER JOIN yp.entity e ON e.id = p.resource_id ',
      '  AND e.`type` = ''hub'' ',
      '  AND e.area IN (''private'', ''share'', ''restricted'') ',
      '  AND IFNULL(e.status, ''active'') NOT IN (''deleted'', ''archived'', ''frozen'') ',
      'INNER JOIN yp.hub h ON h.id = e.id ',
      'LEFT JOIN yp.department d ON d.id = h.department_id AND d.domain_id = h.domain_id ',
      'LEFT JOIN yp.workspace_members w ON w.hub_id = h.id ',
      'WHERE p.entity_id = ', QUOTE(_uid),
      '  AND p.resource_id != ''*'' ',
      '  AND p.permission > 0 ',
      '  AND (p.expiry_time = 0 OR p.expiry_time > UNIX_TIMESTAMP()) ',
      '  AND h.domain_id = ', _domain_id,
      '  AND d.id IS NULL ',
      ' ORDER BY h.name'
    );
    PREPARE _stmt FROM @my_ungrouped_sql;
    EXECUTE _stmt;
    DEALLOCATE PREPARE _stmt;
  END IF;
END$

DELIMITER ;
