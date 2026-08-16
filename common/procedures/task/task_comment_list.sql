DELIMITER $
DROP PROCEDURE IF EXISTS `task_comment_list`$
CREATE PROCEDURE `task_comment_list`(
  IN _task_id VARCHAR(16)
)
BEGIN
  -- Flat, chronological feed; the client nests replies by parent_id and groups
  -- reactions by emoji. Author display (name/avatar) is resolved client-side
  -- from the hub member list, so no cross-DB join here.
  SELECT
    c.id, c.task_id, c.author_uid, c.parent_id, c.body, c.edited, c.ctime, c.mtime,
    COALESCE((
      SELECT JSON_ARRAYAGG(JSON_OBJECT('emoji', r.emoji, 'uid', r.uid))
        FROM task_comment_reaction r
       WHERE r.comment_id = c.id
    ), JSON_ARRAY()) AS reactions,
    -- Files attached to this comment (task_comment_file), not to the task.
    -- Same shape as task_get_linked_files' rows so the client can render a
    -- comment's attachments with the task attachment card.
    COALESCE((
      SELECT JSON_ARRAYAGG(JSON_OBJECT(
               'file_nid', cf.file_nid,
               'filename', m.user_filename,
               'extension', m.extension,
               'category', m.category,
               'filesize', m.filesize))
        FROM task_comment_file cf
        LEFT JOIN media m ON m.id = cf.file_nid
       WHERE cf.comment_id = c.id
    ), JSON_ARRAY()) AS attachments
  FROM task_comment c
  WHERE c.task_id = _task_id
  ORDER BY c.ctime ASC;
END$
DELIMITER ;
