-- File: schemas/yellow_page/procedures/contact/contact_unread_count.sql
-- Purpose: The REAL number of unread contact_activity rows per event for the
-- notification tab badges. The contact_*_unread procedures stop at 50 rows
-- each, so a badge built from their rows read 100 for a user with 374 unread
-- task notifications (57 assigned + 317 mentions) and never went down.

DELIMITER $

DROP PROCEDURE IF EXISTS `contact_unread_count`$
CREATE PROCEDURE `contact_unread_count`(
  IN _user_id VARCHAR(16)
)
BEGIN
  SELECT
    c.event,
    COUNT(*) AS cnt
  FROM yp.contact_activity c
  WHERE c.target_uid = _user_id
    AND c.dismissed_at IS NULL
    AND contact_unread_counted(c.event, c.uid, c.hidden_at, _user_id) = 1
  GROUP BY c.event;
END$

DELIMITER ;
