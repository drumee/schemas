-- File: schemas/yellow_page/procedures/contact/contact_unread_ids.sql
-- Purpose: Which of the given contact_activity ids the panel counts as unread.
-- The full feed (Unread OFF) shows a contact row as unread only when the badge
-- counts it; checking the page's own ids replaces a lookup against the 50-row
-- contact_*_unread lists, which made every row past the 50th read as READ
-- although it was still unread. _ids is a JSON array of ids (one feed page).

DELIMITER $

DROP PROCEDURE IF EXISTS `contact_unread_ids`$
CREATE PROCEDURE `contact_unread_ids`(
  IN _user_id VARCHAR(16),
  IN _ids JSON
)
BEGIN
  SELECT c.id
  FROM yp.contact_activity c
  INNER JOIN JSON_TABLE(
    _ids, '$[*]' COLUMNS (id INT(11) UNSIGNED PATH '$')
  ) j ON j.id = c.id
  WHERE c.target_uid = _user_id
    AND c.dismissed_at IS NULL
    AND contact_unread_counted(c.event, c.uid, c.hidden_at, _user_id) = 1;
END$

DELIMITER ;
