DELIMITER $

-- =========================================================
-- org_department_members
-- =========================================================
-- Who belongs to each DEPARTMENTED workspace of an organisation, in one call:
-- rows {hub_id, uid}. Feeds the Org Structure chart's department columns.
--
-- WHY ONE PROC AND NOT member_list_workspaces PER MEMBER. That per-member
-- read ran one CALL per person, all serialized on admin-api's single yp
-- connection (500 members ≈ seconds on every tab open), and a member whose
-- drumate DB had been dropped made the dynamic SQL fail mid-fan-out, which
-- leaves the shared connection mid-transaction for its siblings. Here the
-- cost follows the number of departmented workspaces (usually few), and a
-- workspace whose database no longer exists is skipped up front via
-- information_schema.SCHEMATA instead of failing the whole statement.
--
-- Membership is the hub-side truth (permission rows with resource_id '*',
-- permission > 0) — the same source as hub_member_list on the Member tab.
-- The workspace set matches org_workspaces / org_departments: collaborative
-- areas only, not deleted/archived/frozen.
DROP PROCEDURE IF EXISTS `org_department_members`$
CREATE PROCEDURE `org_department_members`(
  IN _domain_id INT
)
BEGIN
  DECLARE _done INT DEFAULT 0;
  DECLARE _hub_id VARCHAR(16);
  DECLARE _db VARCHAR(255);
  DECLARE _sql LONGTEXT DEFAULT '';
  DECLARE _cur CURSOR FOR
    SELECT h.id, e.db_name
      FROM hub h
     INNER JOIN entity e
        ON e.id = h.id
       AND e.`type` = 'hub'
       AND e.area IN ('private', 'share', 'restricted')
       AND IFNULL(e.status, 'active') NOT IN ('deleted', 'archived', 'frozen')
     INNER JOIN information_schema.SCHEMATA s
        ON s.SCHEMA_NAME = e.db_name
     WHERE h.domain_id = _domain_id
       AND h.department_id IS NOT NULL;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET _done = 1;

  OPEN _cur;
  read_loop: LOOP
    FETCH _cur INTO _hub_id, _db;
    IF _done THEN
      LEAVE read_loop;
    END IF;
    SET _sql = CONCAT(
      _sql,
      IF(_sql = '', '', ' UNION ALL '),
      'SELECT ', QUOTE(_hub_id), ' AS hub_id, entity_id AS uid FROM `', _db,
      '`.permission WHERE resource_id = ''*'' AND permission > 0'
    );
  END LOOP;
  CLOSE _cur;

  IF _sql = '' THEN
    SELECT NULL AS hub_id, NULL AS uid LIMIT 0;
  ELSE
    SET @org_department_members_sql = _sql;
    PREPARE _stmt FROM @org_department_members_sql;
    EXECUTE _stmt;
    DEALLOCATE PREPARE _stmt;
  END IF;
END$

DELIMITER ;
