DELIMITER $
-- ==============================================================
-- 
-- ==============================================================
DROP PROCEDURE IF EXISTS `channel_notify_messages`$
CREATE PROCEDURE `channel_notify_messages`(
  IN _uid VARCHAR(16)
)
BEGIN
  SELECT 
    COUNT(1) read_cnt,
    SUM(CASE WHEN JSON_SEARCH(mention_ids, 'one', _uid) IS NOT NULL THEN 1 ELSE 0 END) mention_cnt,
    SUM(CASE
      WHEN is_forward = 1
        OR (attachment IS NOT NULL AND LTRIM(RTRIM(attachment)) != '' AND attachment != 'null')
      THEN 1 ELSE 0
    END) share_cnt
  FROM channel WHERE
  JSON_EXISTS(metadata, CONCAT("$._delivered_.", _uid)) AND
  NOT JSON_EXISTS(metadata, CONCAT("$._seen_.", _uid));
END$
DELIMITER ;