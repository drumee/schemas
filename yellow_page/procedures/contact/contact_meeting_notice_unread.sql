-- File: schemas/yellow_page/procedures/contact/contact_meeting_notice_unread.sql
-- Purpose: Return the caller's UNDISMISSED `meeting_notice` activity rows so the
-- activity panel can merge them into the Unread feed and count them on the
-- Meeting tab badge.
--
-- `meeting_notice` is the scheduled-meeting lifecycle event written by
-- service/private/room.js (`data.kind` = invite | moved | cancelled). Round 3 /
-- Sprint 1: before it existed, an invitation was a socket-only push that did not
-- survive a reload, a rescheduled meeting announced nothing, and a cancelled one
-- silently took its own media rollup row with it (permission_revoke DELETEs a
-- `schedule` media row), so there was nothing left to notify from.
--
-- ADDITIVE ONLY: a new read procedure, no table change and no existing routine
-- touched. Without it the notices still reach the user with the Unread toggle
-- OFF, because activity_get_feed_all's contact branch has no event whitelist —
-- this procedure is what makes them visible with the toggle ON (the panel's
-- default) and countable per tab.
--
-- Mirrors contact_task_mention_unread exactly, column for column, so a merged
-- row is indistinguishable from the same row under Unread OFF. Do not add
-- columns here without adding them there too.

DELIMITER $

DROP PROCEDURE IF EXISTS `contact_meeting_notice_unread`$

CREATE PROCEDURE `contact_meeting_notice_unread`(
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
    AND c.event = 'meeting_notice'
    AND c.dismissed_at IS NULL
    AND c.uid <> _user_id
  ORDER BY c.timestamp DESC
  LIMIT 50;
END$

DELIMITER ;
