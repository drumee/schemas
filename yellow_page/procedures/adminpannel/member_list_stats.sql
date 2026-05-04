DELIMITER $

DROP PROCEDURE IF EXISTS `member_list_stats`$
CREATE PROCEDURE `member_list_stats`(
  IN _org_id VARCHAR(16)
)
BEGIN
  DECLARE _dom_id INT;

  SELECT domain_id FROM organisation WHERE id = _org_id INTO _dom_id;

  SELECT
    COUNT(DISTINCT p.uid) AS total_members,
    SUM(CASE WHEN p.privilege > 1 THEN 1 ELSE 0 END) AS admins,
    SUM(CASE WHEN d.connected = '0' AND e.status = 'active' THEN 1 ELSE 0 END) AS pending_invites,
    (
      SELECT COUNT(DISTINCT dt.guest_id)
      FROM dmz_token dt
      INNER JOIN hub h ON h.id = dt.hub_id
      WHERE h.domain_id = _dom_id
    ) AS external_guests
  FROM privilege p
  INNER JOIN organisation o ON p.domain_id = o.domain_id
  INNER JOIN drumate d ON p.uid = d.id
  INNER JOIN entity e ON d.id = e.id
  WHERE
    o.id = _org_id AND
    p.domain_id = _dom_id AND
    JSON_VALUE(d.profile, '$.category') != 'system' AND
    e.status != 'archived';
END $

DELIMITER ;