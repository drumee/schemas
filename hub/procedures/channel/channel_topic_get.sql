DELIMITER $

-- =========================================================
-- channel_topic_get
-- One active topic (the service checks it belongs to the folder in view).
-- =========================================================
DROP PROCEDURE IF EXISTS `channel_topic_get`$
CREATE PROCEDURE `channel_topic_get`(
  IN _topic_id VARCHAR(16) CHARACTER SET ascii
)
BEGIN
  SELECT id, folder_nid, name, emoji, created_by, ctime
    FROM channel_topic WHERE id = _topic_id AND status = 'active';
END$

DELIMITER ;
