DELIMITER $
DROP PROCEDURE IF EXISTS `task_comment_react`$
CREATE PROCEDURE `task_comment_react`(
  IN _comment_id VARCHAR(16),
  IN _uid VARCHAR(16),
  IN _emoji VARCHAR(32)
)
BEGIN
  -- Toggle: remove the caller's reaction if present, otherwise add it.
  IF EXISTS (
    SELECT 1 FROM task_comment_reaction
     WHERE comment_id = _comment_id AND uid = _uid AND emoji = _emoji
  ) THEN
    DELETE FROM task_comment_reaction
     WHERE comment_id = _comment_id AND uid = _uid AND emoji = _emoji;
  ELSE
    INSERT INTO task_comment_reaction (comment_id, uid, emoji, ctime)
    VALUES (_comment_id, _uid, _emoji, UNIX_TIMESTAMP());
  END IF;

  SELECT
    _comment_id AS comment_id,
    _emoji AS emoji,
    (SELECT COUNT(*) FROM task_comment_reaction
       WHERE comment_id = _comment_id AND emoji = _emoji) AS count;
END$
DELIMITER ;
