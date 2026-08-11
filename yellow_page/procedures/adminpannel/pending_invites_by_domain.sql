DELIMITER $

DROP PROCEDURE IF EXISTS `pending_invites_by_domain`$
CREATE PROCEDURE `pending_invites_by_domain`(
  IN _dom_id INT,
  IN _hub_id VARCHAR(16)
)
BEGIN
  -- Backing list for the admin-console "Pending Invites" stat-card popup and
  -- the ACTIVE DIRECTORY pending rows. Two sources, kept in sync with the
  -- counter in member_list_stats (they are documented as required to match):
  --
  -- 1) pending_invitation rows — emails invited to a workspace who have not
  --    joined yet. Entity type is 'hub' for real workspaces AND 'drumate' for
  --    invites raised on a folder of someone's HOME hub (the folder-window
  --    invite flow writes hub_id = the home/drumate entity id). The previous
  --    e.type = 'hub' filter silently dropped every home-folder invite.
  --
  -- 2) secure_share_token named-email invites — the home-menu "share" flow
  --    (window_secure_share -> secure_share.create) records its recipients
  --    ONLY in secure_share_token.allowed_emails / recipient_email and never
  --    writes pending_invitation, so those invites were structurally
  --    invisible here. Pending = link alive (not revoked / not expired) and
  --    that email has not opened it yet (no secure_share_access_event row).
  --
  -- 3) token rows (method 'hub_invite:%') — hub.invite branch A (share-link
  --    workspace + email with no account) writes ONLY token_hub_invite_add,
  --    never pending_invitation. Branch C (restricted workspace) writes BOTH
  --    a token and a pending_invitation fallback, so the token source
  --    excludes emails already present in pending_invitation for the same
  --    workspace to avoid double-counting one invite.
  --
  -- Scoped to the caller's domain (workspace entity domain for source 1, the
  -- share creator's / inviter's domain for sources 2-3 — same scoping as
  -- external_guests), optionally narrowed to a single workspace (_hub_id;
  -- '' or NULL = whole org), excluding expired invites.
  -- ONE ROW PER PERSON, not per invitation.
  --
  -- The stat card above this list counts distinct people (member_list_stats),
  -- because a seat belongs to a person and somebody invited into three
  -- folders is still one person. Left ungrouped, the card said 9 while the
  -- popup behind it listed 15 rows for the same nine humans -- reported as
  -- part of the seat-count fix, 2026-08-11.
  --
  -- The per-invitation detail is kept, not dropped: workspace_name carries
  -- every workspace they were invited to. hub_id/permission stay single
  -- valued (the most recent invitation's) -- callers that act on a row use
  -- them for one target, and the FE only prints workspace_name.
  --
  -- expiry_time: 0 means "never expires", so a person holding ANY
  -- non-expiring invitation is reported as non-expiring; otherwise the
  -- SOONEST expiry, which is the one an admin needs to act on first.
  SELECT
    x.email,
    MAX(x.hub_id)          AS hub_id,
    MAX(x.permission)      AS permission,
    IF(SUM(x.expiry_time = 0) > 0, 0, MIN(NULLIF(x.expiry_time, 0))) AS expiry_time,
    MAX(x.created_at)      AS created_at,
    GROUP_CONCAT(DISTINCT x.workspace_name ORDER BY x.workspace_name SEPARATOR ', ') AS workspace_name
  FROM (
  SELECT
    LOWER(TRIM(pi.email)) AS email,
    pi.hub_id,
    pi.permission,
    pi.expiry_time,
    pi.created_at,
    -- For drumate entities hub.* is NULL; fall back to the home owner's
    -- ident/fullname — the closest reachable label for "whose home" from yp.
    COALESCE(NULLIF(e.ident, ''), h.name, h.hubname, od.fullname) AS workspace_name
  FROM pending_invitation pi
  INNER JOIN entity e ON e.id = pi.hub_id
  LEFT JOIN hub h ON h.id = pi.hub_id
  LEFT JOIN drumate od ON od.id = pi.hub_id
  WHERE e.dom_id = _dom_id
    AND e.type IN ('hub', 'drumate')
    AND e.status = 'active'
    AND (_hub_id IS NULL OR _hub_id = '' OR pi.hub_id = _hub_id)
    AND (pi.expiry_time = 0 OR pi.expiry_time > UNIX_TIMESTAMP())

  UNION ALL

  SELECT
    LOWER(TRIM(je.email)) AS email,
    st.hub_id,
    -- Map the share level onto the cumulative privilege scale used by
    -- pending_invitation rows (matches LEVEL_TO_PRIVILEGE in secure_share.js).
    CASE st.permission_level
      WHEN 'can_edit' THEN 15
      WHEN 'can_chat' THEN 7
      ELSE 3
    END AS permission,
    st.expiry_time,
    st.ctime AS created_at,
    COALESCE(NULLIF(e.ident, ''), h.name, h.hubname, cd.fullname) AS workspace_name
  FROM secure_share_token st
  INNER JOIN drumate cd ON cd.id = st.creator_id AND cd.domain_id = _dom_id
  LEFT JOIN entity e ON e.id = st.hub_id
  LEFT JOIN hub h ON h.id = st.hub_id
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
    AND (_hub_id IS NULL OR _hub_id = '' OR st.hub_id = _hub_id)
    AND NOT EXISTS (
      SELECT 1 FROM secure_share_access_event ev
      WHERE ev.token_id = st.id
        AND LOWER(ev.recipient_email) = LOWER(je.email)
    )

  UNION ALL

  SELECT
    LOWER(TRIM(t.email)) AS email,
    CAST(JSON_UNQUOTE(JSON_VALUE(t.metadata, '$.hub_id')) AS CHAR(16)) AS hub_id,
    CAST(IFNULL(JSON_VALUE(t.metadata, '$.permission'), 3) AS UNSIGNED) AS permission,
    t.expiry AS expiry_time,
    t.ctime AS created_at,
    COALESCE(NULLIF(te.ident, ''), th.name, th.hubname, ti.fullname) AS workspace_name
  FROM token t
  INNER JOIN drumate ti ON ti.id = t.inviter_id AND ti.domain_id = _dom_id
  LEFT JOIN entity te ON te.id = JSON_UNQUOTE(JSON_VALUE(t.metadata, '$.hub_id'))
  LEFT JOIN hub th ON th.id = JSON_UNQUOTE(JSON_VALUE(t.metadata, '$.hub_id'))
  WHERE t.method LIKE 'hub_invite:%'
    AND t.status = 'active'
    AND (t.expiry = 0 OR t.expiry > UNIX_TIMESTAMP())
    AND (_hub_id IS NULL OR _hub_id = ''
         OR JSON_UNQUOTE(JSON_VALUE(t.metadata, '$.hub_id')) = _hub_id)
    AND NOT EXISTS (
      SELECT 1 FROM pending_invitation pi2
      WHERE pi2.hub_id = JSON_UNQUOTE(JSON_VALUE(t.metadata, '$.hub_id'))
        AND pi2.email = t.email
        AND (pi2.expiry_time = 0 OR pi2.expiry_time > UNIX_TIMESTAMP())
    )

  ) x
  WHERE x.email IS NOT NULL AND x.email <> ''
  GROUP BY x.email
  ORDER BY created_at DESC;
END $

DELIMITER ;
