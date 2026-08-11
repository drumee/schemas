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
      -- Pending invites = distinct PEOPLE who have been invited and not joined
      -- yet -- not invitation ROWS.
      --
      -- One person may legitimately be invited into several folders or
      -- workspaces; each invite writes its own row, and summing the rows
      -- charged that person a seat per folder. Live on stage:
      -- 20520094@gm.uit.edu.vn holds three rows across three hubs of domain 7
      -- and counted as three. Reported 2026-08-11: invite an address into one
      -- folder, then into a second, and the org is refused for exceeding its
      -- member cap -- on one human being.
      --
      -- Same three sources as before, and the same filters; they are now
      -- UNIONed on the normalised email so a person present in more than one
      -- of them still counts once:
      --  1) non-expired pending_invitation rows on this domain's active hubs
      --     AND home hubs (type 'drumate' -- folder invites raised on someone's
      --     home write hub_id = the drumate entity id);
      --  2) named-email secure-share invites (home-menu share flow) whose link
      --     is alive and whose email has not opened it yet -- that flow never
      --     writes pending_invitation;
      --  3) active hub_invite tokens (hub.invite branch A: share-link
      --     workspace + no-account email writes ONLY token_hub_invite_add).
      --     Branch C writes both a token and a pending_invitation row; the
      --     explicit NOT EXISTS that used to de-duplicate that pair is gone
      --     because the UNION now does it, and does it across all three.
      --
      -- Anyone who already holds a seat is excluded: total_members above
      -- counts them, so leaving them here billed the same person twice --
      -- which is what happens the moment an existing member is invited into
      -- one more folder.
      SELECT COUNT(*)
      FROM (
        SELECT LOWER(TRIM(pi.email)) AS email
        FROM pending_invitation pi
        INNER JOIN entity he ON he.id = pi.hub_id
        WHERE he.dom_id = _dom_id
          AND he.type IN ('hub', 'drumate')
          AND he.status = 'active'
          AND (pi.expiry_time = 0 OR pi.expiry_time > UNIX_TIMESTAMP())

        UNION

        SELECT LOWER(TRIM(je.email)) AS email
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

        UNION

        SELECT LOWER(TRIM(t.email)) AS email
        FROM token t
        INNER JOIN drumate ti ON ti.id = t.inviter_id AND ti.domain_id = _dom_id
        WHERE t.method LIKE 'hub_invite:%'
          AND t.status = 'active'
          AND (t.expiry = 0 OR t.expiry > UNIX_TIMESTAMP())
      ) inv
      WHERE inv.email IS NOT NULL AND inv.email <> ''
        AND NOT EXISTS (
          SELECT 1
          FROM privilege p2
          INNER JOIN drumate d2 ON d2.id = p2.uid
          INNER JOIN entity e2 ON e2.id = d2.id
          WHERE p2.domain_id = _dom_id
            AND LOWER(TRIM(d2.email)) = inv.email
            AND COALESCE(JSON_VALUE(d2.profile, '$.category'), '') <> 'system'
            AND e2.status NOT IN ('archived', 'frozen', 'deleted')
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
