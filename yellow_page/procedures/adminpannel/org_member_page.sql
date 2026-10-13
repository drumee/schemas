DELIMITER $

-- =========================================================
-- org_member_page
-- =========================================================
-- One page of an organisation's members for the admin console's Active
-- directory (admin.org_member_list), with the full match count on every row
-- (`total`, a window count taken before LIMIT) so the pager needs no second
-- call. Same member set as member_list's 'member' option: yp.privilege on the
-- org domain, minus frozen/deleted/archived entities and system profiles.
-- Members in no workspace are listed too (no join on membership here; see
-- org_member_workspaces).
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

  SET _size = LEAST(GREATEST(IFNULL(_page_size, 10), 1), 100);
  SET _offset = (GREATEST(IFNULL(_page, 1), 1) - 1) * _size;
  SET _pattern = CONCAT('%', TRIM(IFNULL(_key, '')), '%');

  SELECT
    d.id AS uid,
    d.firstname,
    d.lastname,
    d.fullname,
    d.email,
    p.privilege,
    -- Same sources as hub_member_list (what the directory showed before):
    -- socket.ctime / socket.state exist on every install, socket.mtime does
    -- not (local yp drifted without it).
    (SELECT MAX(s.ctime) FROM socket s WHERE s.uid = d.id) AS last_active,
    CASE WHEN EXISTS (
      SELECT 1 FROM socket s WHERE s.uid = d.id AND s.state = 'active'
    ) THEN 1 ELSE 0 END AS is_online,
    COUNT(*) OVER () AS total
  FROM privilege p
  INNER JOIN drumate d ON d.id = p.uid
  INNER JOIN entity e  ON e.id = p.uid
  WHERE p.domain_id = _domain_id
    AND e.status NOT IN ('frozen', 'deleted', 'archived')
    AND IFNULL(JSON_VALUE(d.profile, '$.category'), '') <> 'system'
    AND (CONCAT(IFNULL(d.firstname, ''), ' ', IFNULL(d.lastname, '')) LIKE _pattern
         OR d.email LIKE _pattern)
  ORDER BY d.fullname ASC, d.id ASC
  LIMIT _offset, _size;
END$

DELIMITER ;
