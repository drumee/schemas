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
    -- Admins = members carrying the admin permission bit (16), matching
    -- hub_member_stats (`permission & 16`) and the role labels. The old
    -- `privilege > 1` over-counted every write-capable member as an admin.
    SUM(CASE WHEN p.privilege & 16 THEN 1 ELSE 0 END) AS admins,
    (
      -- Pending invites = emails invited to a workspace that have not joined
      -- yet. Must match the list behind the stat card (pending_invites_by_domain)
      -- — same two sources, same filters:
      --  1) non-expired pending_invitation rows on this domain's active hubs
      --     AND home hubs (type 'drumate' — folder invites raised on someone's
      --     home write hub_id = the drumate entity id; the old type='hub'
      --     filter silently dropped them);
      --  2) named-email secure-share invites (home-menu share flow) whose link
      --     is alive and whose email has not opened it yet — that flow never
      --     writes pending_invitation;
      --  3) active hub_invite tokens (hub.invite branch A: share-link
      --     workspace + no-account email writes ONLY token_hub_invite_add),
      --     minus those that also have a live pending_invitation fallback
      --     row (branch C writes both) to avoid double-counting.
      SELECT COUNT(*)
      FROM pending_invitation pi
      INNER JOIN entity he ON he.id = pi.hub_id
      WHERE he.dom_id = _dom_id
        AND he.type IN ('hub', 'drumate')
        AND he.status = 'active'
        AND (pi.expiry_time = 0 OR pi.expiry_time > UNIX_TIMESTAMP())
    ) + (
      SELECT COUNT(*)
      FROM secure_share_token st
      INNER JOIN drumate cd ON cd.id = st.creator_id AND cd.domain_id = _dom_id
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
      WHERE st.revoked_at IS NULL
        AND (st.expiry_time = 0 OR st.expiry_time > UNIX_TIMESTAMP())
        AND NOT EXISTS (
          SELECT 1 FROM secure_share_access_event ev
          WHERE ev.token_id = st.id
            AND LOWER(ev.recipient_email) = LOWER(je.email)
        )
    ) + (
      SELECT COUNT(*)
      FROM token t
      INNER JOIN drumate ti ON ti.id = t.inviter_id AND ti.domain_id = _dom_id
      WHERE t.method LIKE 'hub_invite:%'
        AND t.status = 'active'
        AND (t.expiry = 0 OR t.expiry > UNIX_TIMESTAMP())
        AND NOT EXISTS (
          SELECT 1 FROM pending_invitation pi2
          WHERE pi2.hub_id = JSON_UNQUOTE(JSON_VALUE(t.metadata, '$.hub_id'))
            AND pi2.email = t.email
            AND (pi2.expiry_time = 0 OR pi2.expiry_time > UNIX_TIMESTAMP())
        )
    ) AS pending_invites,
    (
      -- External guests = distinct external people who opened a secure share
      -- created by a member of this org. Mirrors secure_share_guest_events_by_domain
      -- (the "External Guest Activity" audit table): scope by the share creator's
      -- domain, exclude the org's own members (anonymous + other-domain accounts
      -- are kept). Email-gated shares ("require external guest email") record the
      -- guest's email in recipient_email; COUNT(DISTINCT) drops NULLs so ungated
      -- anonymous opens don't inflate the headcount. This replaces the legacy
      -- dmz_token source, which the secure-share flow never writes to.
      SELECT COUNT(DISTINCT ae.recipient_email)
      FROM secure_share_access_event ae
      INNER JOIN secure_share_token st ON st.id = ae.token_id
      INNER JOIN drumate owner ON owner.id = st.creator_id AND owner.domain_id = _dom_id
      LEFT JOIN drumate viewer ON viewer.id = ae.actor_id
      WHERE ae.actor_id IS NULL
         OR viewer.domain_id IS NULL
         OR viewer.domain_id != _dom_id
    ) AS external_guests
  FROM privilege p
  INNER JOIN organisation o ON p.domain_id = o.domain_id
  INNER JOIN drumate d ON p.uid = d.id
  INNER JOIN entity e ON d.id = e.id
  WHERE
    o.id = _org_id AND
    p.domain_id = _dom_id AND
    COALESCE(JSON_VALUE(d.profile, '$.category'), '') <> 'system' AND
    -- 'frozen' is a DELETED account, not a dormant one: drumate_freeze marks
    -- the entity frozen, rewrites the email to '<uid>/<email>' and zeroes the
    -- privilege — but it leaves the yp.privilege row on the org's domain, so
    -- this count kept the person as a member forever. Reported 2026-08-03:
    -- an org whose only "member" was its own deleted owner still showed 1.
    -- 'deleted' is excluded for the same reason; nothing writes it today, but
    -- an enum value that means gone should never be counted as present.
    e.status NOT IN ('archived', 'frozen', 'deleted');
END $

DELIMITER ;
