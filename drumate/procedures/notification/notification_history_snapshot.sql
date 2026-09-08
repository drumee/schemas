DELIMITER $

DROP PROCEDURE IF EXISTS `notification_history_snapshot`$
CREATE PROCEDURE `notification_history_snapshot`(
  IN _category VARCHAR(16),
  IN _key_id VARCHAR(255),
  IN _hub_id VARCHAR(16),
  IN _last_id BIGINT,
  IN _ctime INT UNSIGNED
)
BEGIN
  DECLARE _now INT UNSIGNED DEFAULT UNIX_TIMESTAMP();

  IF _category IN ('chat', 'teamchat', 'ticket')
     AND _key_id IS NOT NULL AND _key_id <> '' THEN
    INSERT INTO notification_activity_history (
      category, notification_key, hub_id, last_id, ctime, read_at
    ) VALUES (
      _category,
      _key_id,
      IFNULL(_hub_id, ''),
      GREATEST(IFNULL(_last_id, 0), 0),
      IF(IFNULL(_ctime, 0) > 0, _ctime, _now),
      _now
    )
    ON DUPLICATE KEY UPDATE
      ctime = GREATEST(ctime, VALUES(ctime)),
      read_at = GREATEST(read_at, VALUES(read_at));
  END IF;
END$

DELIMITER ;
