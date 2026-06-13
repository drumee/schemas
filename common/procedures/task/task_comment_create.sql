DELIMITER $
DROP PROCEDURE IF EXISTS `task_comment_create`$
CREATE PROCEDURE `task_comment_create`(
  IN _id VARCHAR(16),
  IN _task_id VARCHAR(16),
  IN _author_uid VARCHAR(16),
  IN _parent_id VARCHAR(16),
  IN _body TEXT
)
BEGIN
  DECLARE _now INT DEFAULT UNIX_TIMESTAMP();
  INSERT INTO task_comment (id, task_id, author_uid, parent_id, body, edited, ctime, mtime)
  VALUES (_id, _task_id, _author_uid, _parent_id, _body, 0, _now, _now);

  SELECT id, task_id, author_uid, parent_id, body, edited, ctime, mtime
    FROM task_comment
   WHERE id = _id;
END$
DELIMITER ;
