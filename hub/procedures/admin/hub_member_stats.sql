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
    -- joined yet: yp.pending_invitation rows (keyed hub_id+email) PLUS named
    -- emails on live secure-share links of this hub who have not opened them
    -- yet (the home-menu share flow records recipients only in
    -- secure_share_token, never in pending_invitation). Mirrors
    -- pending_invites_by_domain / member_list_stats so per-hub and org-wide
    -- figures agree. Excludes expired invites. Was hardcoded 0.
    (
      SELECT COUNT(*)
      FROM yp.pending_invitation pi
      WHERE pi.hub_id = _hub_id
        AND (pi.expiry_time = 0 OR pi.expiry_time > UNIX_TIMESTAMP())
    ) + (
      SELECT COUNT(*)
      FROM yp.secure_share_token st
      JOIN JSON_TABLE(
        CASE
          WHEN st.allowed_emails IS NOT NULL AND JSON_LENGTH(st.allowed_emails) > 0
            THEN st.allowed_emails
          WHEN st.recipient_email IS NOT NULL AND st.recipient_email != ''
            THEN JSON_ARRAY(st.recipient_email)
          ELSE JSON_ARRAY()
        END,
        '$[*]' COLUMNS (email VARCHAR(512) PATH '$')
      ) je
      WHERE st.hub_id = _hub_id
        AND st.revoked_at IS NULL
        AND (st.expiry_time = 0 OR st.expiry_time > UNIX_TIMESTAMP())
        AND NOT EXISTS (
          SELECT 1 FROM yp.secure_share_access_event ev
          WHERE ev.token_id = st.id
            AND LOWER(ev.recipient_email) = LOWER(je.email)
        )
    ) + (
      -- Active hub_invite tokens for THIS workspace (hub.invite branch A:
      -- share-link + no-account email writes ONLY token_hub_invite_add),
      -- minus those that also carry a live pending_invitation fallback row
      -- (branch C writes both) to avoid double-counting one invite.
      SELECT COUNT(*)
      FROM yp.token t
      WHERE t.method = CONCAT('hub_invite:', _hub_id)
        AND t.status = 'active'
        AND (t.expiry = 0 OR t.expiry > UNIX_TIMESTAMP())
        AND NOT EXISTS (
          SELECT 1 FROM yp.pending_invitation pi2
          WHERE pi2.hub_id = _hub_id
            AND pi2.email = t.email
            AND (pi2.expiry_time = 0 OR pi2.expiry_time > UNIX_TIMESTAMP())
        )
    )
      AS pending_invites,
    -- Most recent content activity in the hub. media.publish_time is the
    -- canonical "last modified" timestamp on a file/folder; entity.mtime
    -- only moves on metadata edits (rename etc.) and is 0 for most hubs.
    (SELECT IFNULL(MAX(publish_time), 0) FROM media WHERE publish_time > 0)
      AS last_activity
  FROM permission p
  INNER JOIN yp.drumate d ON d.id = p.entity_id
  INNER JOIN yp.entity e ON e.id = p.entity_id
  WHERE p.resource_id = '*'
    AND p.permission  > 0
    AND e.status NOT IN ('archived', 'frozen', 'deleted');
END$

DELIMITER ;
