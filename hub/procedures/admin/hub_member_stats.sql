DELIMITER $

DROP PROCEDURE IF EXISTS `hub_member_stats`$
CREATE PROCEDURE `hub_member_stats`(
  IN _domain_id INT(11) UNSIGNED
)
BEGIN
  SELECT
    COUNT(DISTINCT p.entity_id)
      AS total_members,
    COUNT(DISTINCT CASE WHEN p.permission >= 31 THEN p.entity_id END)
      AS admins,
    COUNT(DISTINCT CASE WHEN d.domain_id != _domain_id THEN p.entity_id END)
      AS external_guests,
    0
      AS pending_invites
  FROM permission p
  INNER JOIN yp.drumate d ON d.id = p.entity_id
  WHERE p.resource_id = '*'
    AND p.permission  > 0;
END$

DELIMITER ;