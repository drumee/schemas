DELIMITER $

DROP PROCEDURE IF EXISTS `notification_activity_bookmark_row_save`$
CREATE PROCEDURE `notification_activity_bookmark_row_save`(
  IN _bookmark_key CHAR(64) CHARACTER SET ascii,
  IN _bucket VARCHAR(16) CHARACTER SET ascii,
  IN _row_time INT UNSIGNED,
  IN _payload MEDIUMTEXT
)
BEGIN
  -- Snapshot of the saved row, so the Saved view can list it whatever feed
  -- page it sits on. notification_activity_bookmark stays the source of truth
  -- for WHAT is saved (mobile writes only there); this table only says what the
  -- row looked like.
  INSERT INTO notification_activity_bookmark_row (
    bookmark_key, bucket, row_time, payload, ctime
  ) VALUES (
    _bookmark_key, IFNULL(_bucket, ''), IFNULL(_row_time, 0), _payload, UNIX_TIMESTAMP()
  )
  ON DUPLICATE KEY UPDATE
    bucket = VALUES(bucket),
    row_time = VALUES(row_time),
    payload = VALUES(payload),
    ctime = VALUES(ctime);

  -- Snapshots whose bookmark is gone (removed from mobile, or evicted by the
  -- 1000-row cap in notification_activity_bookmark_add). Both tables are
  -- capped per user, so this stays small.
  DELETE r FROM notification_activity_bookmark_row r
  LEFT JOIN notification_activity_bookmark b ON b.bookmark_key = r.bookmark_key
  WHERE b.bookmark_key IS NULL;

  SELECT _bookmark_key AS bookmark_key;
END$

DELIMITER ;
