DELIMITER $

DROP PROCEDURE IF EXISTS `hub_member_stats`$
CREATE PROCEDURE `hub_member_stats`(
  IN _domain_id INT(11) UNSIGNED,
  IN _hub_id    VARCHAR(16)
)
BEGIN
  SELECT
    COUNT(DISTINCT p.entity_id)
      AS total_members,
    COUNT(DISTINCT CASE WHEN p.permission & 16 THEN p.entity_id END)
      AS admins,
    -- External guests = distinct external people who opened a secure share of
    -- THIS workspace. Email-gated shares ("require external guest email") record
    -- the guest's email in secure_share_access_event.recipient_email; COUNT(DISTINCT)
    -- drops NULLs so anonymous/public opens don't inflate the headcount. Excludes
    -- the org's own members (mirrors secure_share_guest_events_by_domain). This
    -- replaces the previous "cross-domain member" definition, which counted
    -- registered users from other orgs, not secure-share link guests.
    (
      SELECT COUNT(DISTINCT ae.recipient_email)
      FROM yp.secure_share_access_event ae
      INNER JOIN yp.secure_share_token st ON st.id = ae.token_id
      LEFT JOIN yp.drumate viewer ON viewer.id = ae.actor_id
      WHERE st.hub_id = _hub_id
        AND (ae.actor_id IS NULL
             OR viewer.domain_id IS NULL
             OR viewer.domain_id != _domain_id)
    )
      AS external_guests,
    -- Pending invites = people invited to THIS workspace by email who have not
    -- joined yet (still parked in yp.pending_invitation, keyed on hub_id+email),
    -- excluding expired invites. Was hardcoded 0.
    (
      SELECT COUNT(*)
      FROM yp.pending_invitation pi
      WHERE pi.hub_id = _hub_id
        AND (pi.expiry_time = 0 OR pi.expiry_time > UNIX_TIMESTAMP())
    )
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
