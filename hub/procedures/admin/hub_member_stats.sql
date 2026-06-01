DELIMITER $

DROP PROCEDURE IF EXISTS `hub_member_stats`$
CREATE PROCEDURE `hub_member_stats`(
  IN _domain_id INT(11) UNSIGNED
)
BEGIN
  SELECT
    COUNT(DISTINCT p.entity_id)
      AS total_members,
    COUNT(DISTINCT CASE WHEN p.permission & 16 THEN p.entity_id END)
      AS admins,
    COUNT(DISTINCT CASE WHEN d.domain_id != _domain_id THEN p.entity_id END)
      AS external_guests,
    0
      AS pending_invites,
    -- Most recent content activity in the hub. media.publish_time is the
    -- canonical "last modified" timestamp on a file/folder; entity.mtime
    -- only moves on metadata edits (rename etc.) and is 0 for most hubs.
    (SELECT IFNULL(MAX(publish_time), 0) FROM media WHERE publish_time > 0)
      AS last_activity
  FROM permission p
  INNER JOIN yp.drumate d ON d.id = p.entity_id
  WHERE p.resource_id = '*'
    AND p.permission  > 0;
END$

DELIMITER ;