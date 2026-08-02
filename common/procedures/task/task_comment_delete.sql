DELIMITER $
DROP PROCEDURE IF EXISTS `task_comment_delete`$
CREATE PROCEDURE `task_comment_delete`(
  IN _id VARCHAR(16),
  IN _author_uid VARCHAR(16)
)
BEGIN
  -- Author-only delete (affected = 0 when the caller is not the author).
  -- Drop the comment's reactions first (guarded on author ownership via join),
  -- then the comment itself. Replies keep their now-dangling parent_id — the
  -- client renders orphaned replies at the top level.
  DELETE r FROM task_comment_reaction r
    JOIN task_comment c ON c.id = r.comment_id
   WHERE r.comment_id = _id AND c.author_uid = _author_uid;

  DELETE FROM task_comment
   WHERE id = _id AND author_uid = _author_uid;

  SELECT _id AS id, ROW_COUNT() AS affected;
END$
DELIMITER ;
