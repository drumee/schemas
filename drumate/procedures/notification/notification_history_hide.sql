DELIMITER $

DROP PROCEDURE IF EXISTS `notification_history_hide`$
CREATE PROCEDURE `notification_history_hide`(
  IN _history_id BIGINT UNSIGNED
)
BEGIN
  UPDATE notification_activity_history
  SET hidden_at = UNIX_TIMESTAMP()
  WHERE history_id = _history_id
    AND hidden_at IS NULL;

  SELECT 'ok' AS status, _history_id AS history_id;
END$

DELIMITER ;
