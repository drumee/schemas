DELIMITER $
DROP PROCEDURE IF EXISTS `notification_activity_bookmark_add`$
CREATE PROCEDURE `notification_activity_bookmark_add`(
  IN _bookmark_key CHAR(64) CHARACTER SET ascii
)
BEGIN
  DECLARE _bookmark_count INT UNSIGNED DEFAULT 0;
  DECLARE _lock_acquired TINYINT DEFAULT 0;
  DECLARE _lock_name VARCHAR(128) DEFAULT CONCAT(
    'notification_activity_bookmark:', DATABASE()
  );
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    IF _lock_acquired = 1 THEN
      DO RELEASE_LOCK(_lock_name);
    END IF;
    RESIGNAL;
  END;

  SELECT GET_LOCK(_lock_name, 5) INTO _lock_acquired;
  IF IFNULL(_lock_acquired, 0) <> 1 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'BOOKMARK_LOCK_TIMEOUT';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM notification_activity_bookmark
    WHERE bookmark_key = _bookmark_key
  ) THEN
    SELECT COUNT(*) INTO _bookmark_count
    FROM notification_activity_bookmark;
    IF _bookmark_count >= 1000 THEN
      DELETE FROM notification_activity_bookmark
      ORDER BY ctime ASC, bookmark_key ASC
      LIMIT 1;
    END IF;
  END IF;

  INSERT INTO notification_activity_bookmark (bookmark_key, ctime)
  VALUES (_bookmark_key, UNIX_TIMESTAMP())
  ON DUPLICATE KEY UPDATE ctime = VALUES(ctime);

  DO RELEASE_LOCK(_lock_name);
  SET _lock_acquired = 0;

  SELECT _bookmark_key AS bookmark_key, 1 AS is_saved;
END$
DELIMITER ;
