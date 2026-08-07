-- File: schemas/drumate/procedures/notification/notification_hub_invites.sql
-- Purpose: Return pending hub invites for the current user from yp.contact_activity.
-- Called by activity.list (via _callUserProc) to populate the hub_invite rollup.
-- Dedupes per (inviter, hub_id) by keeping only the most recent undismissed row,
-- mirroring the cleanup contact_log_activity now enforces on insert.
-- hub_live_name carries the workspace's display name: yp.entity.ident/headline are
-- NULL on every hub, so the two columns the caller used to read never resolved a
-- name and the notification rendered "<inviter> invited you to " with nothing after
-- it. The live name lives in yp.hub.name (yp.hub.hubname is the hex id -- never a
-- label). Additive: every pre-existing column is untouched, and yp.hub.id is UNIQUE
-- so the extra LEFT JOIN cannot multiply rows.

DELIMITER $

DROP PROCEDURE IF EXISTS `notification_hub_invites`$

CREATE PROCEDURE `notification_hub_invites`()
BEGIN
  DECLARE _uid VARCHAR(16) CHARACTER SET ascii;

  SELECT id INTO _uid FROM yp.entity WHERE db_name = DATABASE();

  -- For each (inviter, target, hub_id) keep only the most recent undismissed
  -- contact_activity row. Older duplicates (from before idempotent insert was
  -- in place) get hidden from this view but stay in the audit log.
  SELECT
    a.id,
    a.timestamp     AS ctime,
    a.uid           AS author_id,
    a.data,
    d.firstname     AS inviter_firstname,
    d.lastname      AS inviter_lastname,
    d.email         AS inviter_email,
    e.headline      AS hub_headline,
    e.ident         AS hub_ident,
    h.name          AS hub_live_name
  FROM yp.contact_activity a
  INNER JOIN (
    SELECT MAX(a2.id) AS id
      FROM yp.contact_activity a2
     WHERE a2.target_uid = _uid
       AND a2.event = 'hub_invite_received'
       AND a2.dismissed_at IS NULL
     GROUP BY a2.uid,
              JSON_UNQUOTE(JSON_EXTRACT(a2.data, '$.hub_id'))
  ) keep ON keep.id = a.id
  LEFT JOIN yp.drumate d ON d.id = a.uid
  LEFT JOIN yp.entity  e
         ON e.id = JSON_UNQUOTE(JSON_EXTRACT(a.data, '$.hub_id'))
  LEFT JOIN yp.hub     h
         ON h.id = JSON_UNQUOTE(JSON_EXTRACT(a.data, '$.hub_id'))
  ORDER BY a.timestamp DESC
  LIMIT 50;
END$

DELIMITER ;
