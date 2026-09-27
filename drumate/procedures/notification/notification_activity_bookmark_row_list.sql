DELIMITER $

DROP PROCEDURE IF EXISTS `notification_activity_bookmark_row_list`$
CREATE PROCEDURE `notification_activity_bookmark_row_list`(
  IN _bucket VARCHAR(16) CHARACTER SET ascii
)
BEGIN
  -- Joined with notification_activity_bookmark so only rows still saved are
  -- listed; newest notification first, like the feed. An empty bucket is the
  -- All tab. Not paginated: notification_activity_bookmark_add caps a user at
  -- 1000 bookmarks, and every one of them is pinned.
  SELECT r.bookmark_key, r.bucket, r.row_time, r.payload
  FROM notification_activity_bookmark_row r
  INNER JOIN notification_activity_bookmark b ON b.bookmark_key = r.bookmark_key
  WHERE IFNULL(_bucket, '') = '' OR r.bucket = _bucket
  ORDER BY r.row_time DESC, r.bookmark_key ASC
  LIMIT 1000;
END$

DELIMITER ;
