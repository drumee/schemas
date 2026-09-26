-- File: schemas/yellow_page/procedures/contact/contact_invite_accepted_unread.sql
-- Purpose: Return the caller's UNDISMISSED invite_accepted rows ("<X> accepted
-- your invitation") so the activity panel can count them on the Other tab and
-- list them under Unread ON.
--
-- The event has been written since contact invitations existed, but it never
-- had an *_unread proc: activity_get_feed_all (Unread OFF) showed it as unread
-- while the tab badge and the Unread ON feed never counted it, so the numbers
-- disagreed with what the user could see. Same columns, same order and the same
-- shape as contact_storage_alert_unread, so the rows merge like every other
-- contact_activity event. hidden_at mirrors activity_get_feed_all, which never
-- shows a row the user removed.

DELIMITER $

DROP PROCEDURE IF EXISTS `contact_invite_accepted_unread`$
CREATE PROCEDURE `contact_invite_accepted_unread`(
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
    AND c.event = 'invite_accepted'
    AND c.dismissed_at IS NULL
    AND c.hidden_at IS NULL
    AND c.uid <> _user_id
  ORDER BY c.timestamp DESC
  LIMIT 50;
END$

DELIMITER ;
