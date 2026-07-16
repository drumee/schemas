-- Subscribe a user to change-notifications for one column of one folder.
-- Idempotent: re-subscribing is a no-op (INSERT IGNORE on the composite key).
DELIMITER $
DROP PROCEDURE IF EXISTS `task_column_watch_set`$
CREATE PROCEDURE `task_column_watch_set`(
  IN _uid VARCHAR(16),
  IN _nid VARCHAR(16),
  IN _column_key VARCHAR(32)
)
BEGIN
  IF _uid IS NOT NULL AND _uid <> '' AND _column_key IS NOT NULL AND _column_key <> '' THEN
    INSERT IGNORE INTO task_column_watch (uid, nid, column_key, ctime)
    VALUES (_uid, IFNULL(NULLIF(_nid, ''), '0'), _column_key, UNIX_TIMESTAMP());
  END IF;
END$
DELIMITER ;
