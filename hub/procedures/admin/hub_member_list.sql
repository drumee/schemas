DELIMITER $

DROP PROCEDURE IF EXISTS `hub_member_list`$
CREATE PROCEDURE `hub_member_list`(
  IN _domain_id INT(11) UNSIGNED,
  IN _role VARCHAR(16),
  IN _key VARCHAR(200),
  IN _page TINYINT(4)
)
BEGIN
  DECLARE _range BIGINT;
  DECLARE _offset BIGINT;

  CALL pageToLimits(_page, _offset, _range);

  SET _role = IFNULL(_role, 'all');
  SET @pattern = CONCAT('%', TRIM(IFNULL(_key, '')), '%');

  SELECT
    p.entity_id AS uid,
    d.firstname,
    d.lastname,
    d.fullname,
    d.email,
    p.permission AS hub_permission,
    CASE
      WHEN pr.privilege & 16 THEN 'HUB_ADMIN'
      WHEN p.permission & 16 THEN 'WORKSPACE_ADMIN'
      ELSE 'MEMBER'
    END AS role_label,
    CASE
      WHEN s_active.uid IS NOT NULL THEN 'ONLINE'
      ELSE 'AWAY'
    END AS status,
    ls.last_ctime AS last_active
  FROM permission p
  INNER JOIN yp.drumate d    ON d.id  = p.entity_id
  INNER JOIN yp.entity e     ON e.id  = p.entity_id
  LEFT JOIN yp.privilege pr  ON pr.uid = p.entity_id
                             AND pr.domain_id = _domain_id
  LEFT JOIN (
    SELECT uid
    FROM yp.socket
    WHERE state = 'active'
    GROUP BY uid
  ) s_active ON s_active.uid = p.entity_id
  LEFT JOIN (
    SELECT uid, MAX(ctime) AS last_ctime
    FROM yp.socket
    GROUP BY uid
  ) ls ON ls.uid = p.entity_id
  WHERE p.resource_id = '*'
    AND p.permission  > 0
    AND e.status NOT IN ('archived', 'frozen', 'deleted')
    AND (
      _role = 'all'
      OR (_role = 'admin' AND (pr.privilege & 16 OR p.permission & 16))
      OR (_role = 'member' AND (NOT (COALESCE(pr.privilege, 0) & 16) AND NOT (p.permission & 16)))
    )
    AND (
      TRIM(IFNULL(_key, '')) = ''
      OR d.fullname LIKE @pattern
      OR d.email LIKE @pattern
      OR CONCAT(d.firstname, ' ', d.lastname) LIKE @pattern
    )
  ORDER BY d.lastname, d.firstname
  LIMIT _offset, _range;
END$

DELIMITER ;
