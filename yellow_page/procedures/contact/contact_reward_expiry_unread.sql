-- File: schemas/yellow_page/procedures/contact/contact_reward_expiry_unread.sql
-- Purpose: Return the caller's UNDISMISSED reward_expiry_warning rows so the
-- activity panel merges them into the Unread feed.
--
-- Written at the same time as the event itself, because activity.js says in so
-- many words that skipping this is a known way to get it wrong: "Every new
-- contact_activity event needs its own *_unread proc here — storage_alert was
-- added without one, so recipients got the email but no in-app notification
-- (the panel opens on Unread ON)."
--
-- SUPERSEDED ROWS ARE EXCLUDED BY dismissed_at, not by a clause here.
-- rewardExpiryWorker writes a row for every stage it skips on a catch-up run,
-- so a 30-day notice can never fire later claiming 30 days remain. Those rows
-- exist only to close off a stage; they carry no message and must never surface
-- in the panel, so the worker stamps dismissed_at on them at insert. The filter
-- below is the ordinary `dismissed_at IS NULL` every other feed proc uses —
-- there is no second rule to remember.
--
-- Columns mirror activity_get_feed_all's contact branch exactly, so a merged row
-- is indistinguishable from the same row under Unread OFF.

DELIMITER $

DROP PROCEDURE IF EXISTS `contact_reward_expiry_unread`$

CREATE PROCEDURE `contact_reward_expiry_unread`(
  IN _user_id VARCHAR(16)
)
BEGIN
  SELECT
    c.id,
    c.timestamp,
    c.uid,
    c.event,
    'contact' AS event_type,
    JSON_OBJECT(
      'uid', c.uid,
      'email', d1.email,
      'fullname', d1.fullname
    ) AS src,
    JSON_OBJECT(
      'uid', c.target_uid,
      'email', d2.email,
      'fullname', d2.fullname
    ) AS dest,
    c.data,
    0 AS is_read,
    d1.firstname,
    d1.lastname,
    d1.fullname,
    NULL AS hub_id,
    NULL AS hub_db_name
  FROM yp.contact_activity c
  LEFT JOIN yp.drumate d1 ON c.uid = d1.id
  LEFT JOIN yp.drumate d2 ON c.target_uid = d2.id
  WHERE c.target_uid = _user_id
    AND c.event = 'reward_expiry_warning'
    AND c.dismissed_at IS NULL
  -- No `c.uid <> _user_id` guard, unlike contact_storage_alert_unread: these
  -- rows are raised by the system sentinel ('ffffffffffffffff'), never by a
  -- person, so self-raised is not a case that exists. d1 therefore joins to
  -- nothing and src carries NULLs, which is what "from Drumee" looks like here.
  ORDER BY c.timestamp DESC
  LIMIT 50;
END$

DELIMITER ;
