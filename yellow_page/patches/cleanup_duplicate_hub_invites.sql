-- File: schemas/patches/cleanup_duplicate_hub_invites.sql
-- Purpose: One-time clean-up for duplicate hub_invite_received rows that
-- accumulated before contact_log_activity became idempotent (2026-05-12).
--
-- Behaviour: For every (uid, target_uid, hub_id) tuple, keep ONLY the most
-- recent undismissed row and stamp `dismissed_at` on the older duplicates.
-- The audit row stays in the table — we only hide the older ones from the
-- activity panel.
--
-- Safe to re-run: once the duplicates are dismissed they won't be touched
-- again.

UPDATE yp.contact_activity AS a
  INNER JOIN (
    SELECT
      uid,
      target_uid,
      JSON_UNQUOTE(JSON_EXTRACT(data, '$.hub_id')) AS hub_id,
      MAX(id) AS keep_id
    FROM yp.contact_activity
    WHERE event = 'hub_invite_received'
      AND dismissed_at IS NULL
    GROUP BY uid, target_uid, JSON_UNQUOTE(JSON_EXTRACT(data, '$.hub_id'))
    HAVING COUNT(*) > 1
  ) dup
    ON dup.uid = a.uid
   AND dup.target_uid = a.target_uid
   AND JSON_UNQUOTE(JSON_EXTRACT(a.data, '$.hub_id')) = dup.hub_id
   AND a.id <> dup.keep_id
SET a.dismissed_at = UNIX_TIMESTAMP()
WHERE a.event = 'hub_invite_received'
  AND a.dismissed_at IS NULL;
