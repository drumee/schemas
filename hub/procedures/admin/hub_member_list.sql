DELIMITER $

DROP PROCEDURE IF EXISTS `hub_member_list`$
CREATE PROCEDURE `hub_member_list`(
  IN _domain_id INT(11) UNSIGNED,
  IN _role VARCHAR(16),
  IN _page TINYINT(4)
)
BEGIN
  DECLARE _range BIGINT;
  DECLARE _offset BIGINT;

  CALL pageToLimits(_page, _offset, _range);

  SET _role = IFNULL(_role, 'all');

  SELECT
    p.entity_id AS uid,
    d.firstname,
    d.lastname,
    d.fullname,
    d.email,
    d.ident,
    p.permission AS hub_permission,
    CASE
      WHEN p.permission >= 63 THEN 'HUB_OWNER'
      WHEN p.permission >= 31 THEN 'HUB_ADMIN'
      ELSE 'MEMBER'
    END AS role_label,
    CASE
      WHEN s_active.uid IS NOT NULL THEN 'ONLINE'
      ELSE 'AWAY'
    END AS status,
    ls.last_ctime AS last_active
  FROM permission p
  INNER JOIN yp.drumate d ON d.id = p.entity_id
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
    AND (
      _role = 'all'
      OR (_role = 'admin' AND p.permission >= 31)
      OR (_role = 'member' AND p.permission  < 31)
    )
  ORDER BY d.lastname, d.firstname
  LIMIT _offset, _range;
END$

DELIMITER ;