DELIMITER $

-- =========================================================
-- task_comment_unlink_file
-- =========================================================
DROP PROCEDURE IF EXISTS `task_comment_unlink_file`$
CREATE PROCEDURE `task_comment_unlink_file`(
  IN _comment_id VARCHAR(16),
  IN _file_nid VARCHAR(16),
  IN _author_uid VARCHAR(16)
)
BEGIN
  -- Author-only, unlike task_unlink_file: a task attachment is shared by the
  -- whole board, but a comment's attachment belongs to that comment's author
  -- the same way its body does (cf. task_comment_update / _delete). A caller
  -- who is not the author affects 0 rows.
  DELETE cf FROM task_comment_file cf
    JOIN task_comment c ON c.id = cf.comment_id
   WHERE cf.comment_id = _comment_id
     AND cf.file_nid = _file_nid
     AND c.author_uid = _author_uid;

  SELECT ROW_COUNT() AS affected;
END $

DELIMITER ;
