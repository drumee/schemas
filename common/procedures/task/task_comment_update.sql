DELIMITER $
DROP PROCEDURE IF EXISTS `task_comment_update`$
CREATE PROCEDURE `task_comment_update`(
  IN _id VARCHAR(16),
  IN _author_uid VARCHAR(16),
  IN _body TEXT
)
BEGIN
  -- Author-only edit. The author_uid guard means a non-author update affects
  -- 0 rows and the SELECT returns empty (the service treats that as not-found).
  UPDATE task_comment
     SET body = _body, edited = 1, mtime = UNIX_TIMESTAMP()
   WHERE id = _id AND author_uid = _author_uid;

  SELECT id, task_id, author_uid, body, edited, ctime, mtime
    FROM task_comment
   WHERE id = _id AND author_uid = _author_uid;
END$
DELIMITER ;
