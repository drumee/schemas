-- File: schemas/yellow_page/procedures/contact/contact_unread_rows.sql
-- Purpose: One page of the caller's unread rows of ONE contact_activity event,
-- so the Unread feed can list every row the badge counts instead of the 50
-- newest the contact_*_unread procedures return. Same columns as those
-- procedures (and as activity_get_feed_all's contact branch); ordered with an
-- id tie-break so consecutive pages never overlap or skip a row.

DELIMITER $

DROP PROCEDURE IF EXISTS `contact_unread_rows`$
CREATE PROCEDURE `contact_unread_rows`(
  IN _user_id VARCHAR(16),
  IN _event VARCHAR(100),
  IN _offset INT(11) UNSIGNED,
  IN _limit INT(11) UNSIGNED
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
    AND c.event = _event
    AND c.dismissed_at IS NULL
    AND contact_unread_counted(c.event, c.uid, c.hidden_at, _user_id) = 1
  ORDER BY c.timestamp DESC, c.id DESC
  LIMIT _offset, _limit;
END$

DELIMITER ;
