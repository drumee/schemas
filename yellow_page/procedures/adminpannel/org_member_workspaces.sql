DELIMITER $

-- =========================================================
-- org_member_workspaces
-- =========================================================
-- The workspaces (and permission) of a given set of org members, in one
-- call: rows {hub_id, uid, permission}. Feeds the Active directory's
-- Workspace column for one page (admin.org_member_list), replacing one
-- member_list_workspaces CALL per row on admin-api's single yp connection.
-- Built like org_department_members: one UNION ALL over every collaborative
-- workspace of the org, hub-side truth (resource_id '*', permission > 0), and
-- a workspace whose database no longer exists is skipped up front via
-- information_schema.SCHEMATA instead of failing the whole statement.
-- _uids is a JSON array of member ids; it reaches the dynamic SQL only
-- through QUOTE().
DROP PROCEDURE IF EXISTS `org_member_workspaces`$
CREATE PROCEDURE `org_member_workspaces`(
  IN _domain_id INT,
  IN _uids LONGTEXT
)
BEGIN
  DECLARE _done INT DEFAULT 0;
  DECLARE _hub_id VARCHAR(16);
  DECLARE _db VARCHAR(255);
  DECLARE _sql LONGTEXT DEFAULT '';
  DECLARE _in LONGTEXT;
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
     WHERE h.domain_id = _domain_id;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET _done = 1;

  IF _uids IS NULL OR JSON_VALID(_uids) = 0 OR JSON_LENGTH(_uids) = 0 THEN
    SELECT NULL AS hub_id, NULL AS uid, NULL AS permission LIMIT 0;
  ELSE
    SET _in = CONCAT(
      ' AND entity_id IN (SELECT j.uid FROM JSON_TABLE(', QUOTE(_uids),
      ', ''$[*]'' COLUMNS(uid VARCHAR(16) PATH ''$'')) j)'
    );
    OPEN _cur;
    read_loop: LOOP
      FETCH _cur INTO _hub_id, _db;
      IF _done THEN
        LEAVE read_loop;
      END IF;
      SET _sql = CONCAT(
        _sql,
        IF(_sql = '', '', ' UNION ALL '),
        'SELECT ', QUOTE(_hub_id), ' AS hub_id, entity_id AS uid, permission FROM `', _db,
        '`.permission WHERE resource_id = ''*'' AND permission > 0', _in
      );
    END LOOP;
    CLOSE _cur;

    IF _sql = '' THEN
      SELECT NULL AS hub_id, NULL AS uid, NULL AS permission LIMIT 0;
    ELSE
      SET @org_member_workspaces_sql = _sql;
      PREPARE _stmt FROM @org_member_workspaces_sql;
      EXECUTE _stmt;
      DEALLOCATE PREPARE _stmt;
    END IF;
  END IF;
END$

DELIMITER ;
