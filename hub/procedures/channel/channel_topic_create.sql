DELIMITER $

-- =========================================================
-- channel_topic_create
-- New topic in a folder's team chat. Names are unique per folder among
-- active topics (case-insensitive: general_ci). Answers the row, or one row
-- error='TOPIC_EXISTS'.
-- =========================================================
DROP PROCEDURE IF EXISTS `channel_topic_create`$
CREATE PROCEDURE `channel_topic_create`(
  IN _uid VARCHAR(16) CHARACTER SET ascii,
  IN _folder_nid VARCHAR(16) CHARACTER SET ascii,
  IN _name VARCHAR(128),
  IN _emoji VARCHAR(16)
)
BEGIN
  DECLARE _id VARCHAR(16) CHARACTER SET ascii;
  SET _name = TRIM(_name);
  IF EXISTS (SELECT 1 FROM channel_topic WHERE folder_nid = _folder_nid
      AND status = 'active' AND name = _name) THEN
    SELECT 'TOPIC_EXISTS' AS error;
  ELSE
    SET _id = uniqueId();
    INSERT INTO channel_topic (id, folder_nid, name, emoji, created_by, ctime, mtime)
      VALUES (_id, _folder_nid, _name, _emoji, _uid, UNIX_TIMESTAMP(), UNIX_TIMESTAMP());
    SELECT id, folder_nid, name, emoji, created_by, ctime FROM channel_topic WHERE id = _id;
  END IF;
END$

DELIMITER ;
