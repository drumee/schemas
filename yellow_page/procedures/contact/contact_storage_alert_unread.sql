-- File: schemas/yellow_page/procedures/contact/contact_storage_alert_unread.sql
-- Purpose: Return the caller's UNDISMISSED storage_alert activity rows so the
-- activity panel can merge them into the Unread feed. Storage alerts are raised
-- by the admin console (admin.send_storage_alert -> yp.contact_activity), but
-- the Unread feed is built from mfs_get_activity_feed, which only reads
-- yp.mfs_changelog — so without this the alert was stored and visible under
-- Unread OFF while never appearing in the panel's DEFAULT (Unread ON) view:
-- the recipient got the email but saw no in-app notification.
-- Columns mirror activity_get_feed_all's contact branch exactly, so a merged
-- row is indistinguishable from the same row under Unread OFF.

DELIMITER $

DROP PROCEDURE IF EXISTS `contact_storage_alert_unread`$

CREATE PROCEDURE `contact_storage_alert_unread`(
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
    AND c.event = 'storage_alert'
    AND c.dismissed_at IS NULL
    AND c.uid <> _user_id
  ORDER BY c.timestamp DESC
  LIMIT 50;
END$

DELIMITER ;
