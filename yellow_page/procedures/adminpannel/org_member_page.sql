DELIMITER $

-- =========================================================
-- org_member_page
-- =========================================================
-- One page of an organisation's people for the admin console's Active
-- directory (admin.org_member_list), with the full match count on every row
-- (`total`, a window count taken before LIMIT) so the pager needs no second
-- call; admin.member_stats reads the same total for its Total Members card.
--
-- The people are:
--   * domain members: yp.privilege on the org domain (collaborator = 0), and
--   * workspace collaborators: anyone with a hub-side grant (resource_id '*',
--     permission > 0) in one of the org's collaborative workspaces whose
--     account lives in another domain (collaborator = 1). yp.privilege is
--     UNIQUE per uid, so they never show up domain-side.
-- dmz/public hubs are share buckets, not workspaces: their recipients are not
-- counted. A workspace whose database no longer exists is skipped up front via
-- information_schema.SCHEMATA. Entities frozen/deleted/archived and system
-- profiles are left out (same as member_list's 'member' option). Members in no
-- workspace are listed too.
-- last_active / is_online use the same socket columns as hub_member_list
-- (socket.mtime is missing on some installs).
DROP PROCEDURE IF EXISTS `org_member_page`$
CREATE PROCEDURE `org_member_page`(
  IN _domain_id INT,
  IN _key VARCHAR(200),
  IN _page INT,
  IN _page_size INT
)
BEGIN
  DECLARE _offset INT;
  DECLARE _size INT;
  DECLARE _pattern VARCHAR(210);
  DECLARE _done INT DEFAULT 0;
  DECLARE _db VARCHAR(255);
  DECLARE _cur CURSOR FOR
    SELECT e.db_name
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

  SET _size = LEAST(GREATEST(IFNULL(_page_size, 10), 1), 100);
  SET _offset = (GREATEST(IFNULL(_page, 1), 1) - 1) * _size;
  SET _pattern = CONCAT('%', TRIM(IFNULL(_key, '')), '%');

  DROP TEMPORARY TABLE IF EXISTS _org_member_page_people;
  CREATE TEMPORARY TABLE _org_member_page_people (
    uid VARCHAR(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci PRIMARY KEY
  );
  INSERT IGNORE INTO _org_member_page_people
    SELECT uid FROM privilege WHERE domain_id = _domain_id;

  OPEN _cur;
  read_loop: LOOP
    FETCH _cur INTO _db;
    IF _done THEN
      LEAVE read_loop;
    END IF;
    -- INSERT (an assignment) converts entity_id into the temp table's
    -- collation, so a utf8mb4_unicode_ci hub can't fail the read.
    SET @org_member_page_sql = CONCAT(
      'INSERT IGNORE INTO _org_member_page_people SELECT entity_id FROM `', _db,
      '`.permission WHERE resource_id = ''*'' AND permission > 0'
    );
    PREPARE _stmt FROM @org_member_page_sql;
    EXECUTE _stmt;
    DEALLOCATE PREPARE _stmt;
  END LOOP;
  CLOSE _cur;

  SELECT
    d.id AS uid,
    d.firstname,
    d.lastname,
    d.fullname,
    d.email,
    IFNULL(pr.privilege, 0) AS privilege,
    (SELECT MAX(s.ctime) FROM socket s WHERE s.uid = d.id) AS last_active,
    CASE WHEN EXISTS (
      SELECT 1 FROM socket s WHERE s.uid = d.id AND s.state = 'active'
    ) THEN 1 ELSE 0 END AS is_online,
    IF(pr.uid IS NULL, 1, 0) AS collaborator,
    COUNT(*) OVER () AS total
  FROM _org_member_page_people op
  INNER JOIN drumate d ON d.id = op.uid
  INNER JOIN entity e  ON e.id = op.uid
  LEFT JOIN privilege pr ON pr.uid = op.uid AND pr.domain_id = _domain_id
  WHERE e.status NOT IN ('frozen', 'deleted', 'archived')
    AND IFNULL(JSON_VALUE(d.profile, '$.category'), '') <> 'system'
    AND (CONCAT(IFNULL(d.firstname, ''), ' ', IFNULL(d.lastname, '')) LIKE _pattern
         OR d.email LIKE _pattern)
  ORDER BY d.fullname ASC, d.id ASC
  LIMIT _offset, _size;

  DROP TEMPORARY TABLE IF EXISTS _org_member_page_people;
END$

DELIMITER ;
