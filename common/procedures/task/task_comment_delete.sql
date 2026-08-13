DELIMITER $
DROP PROCEDURE IF EXISTS `task_comment_delete`$
CREATE PROCEDURE `task_comment_delete`(
  IN _id VARCHAR(16),
  IN _author_uid VARCHAR(16)
)
BEGIN
  -- Author-only delete (affected = 0 when the caller is not the author).
  --
  -- Deleting a comment takes its whole thread with it: replies are stored flat
  -- with parent_id = the root's id (1-level threads), and leaving them behind
  -- produced orphans that the client re-rendered as brand-new top-level
  -- comments — answers with no question above them. So the root's replies go
  -- too, whoever wrote them, along with every reaction on the root and on
  -- those replies.
  --
  -- Ownership is resolved up front rather than through the DELETE's WHERE: the
  -- parent row is already gone by the time ROW_COUNT() could be read for the
  -- cascade, and a non-author must not have the replies removed either.
  DECLARE _owned INT DEFAULT 0;
  DECLARE _replies INT DEFAULT 0;

  SELECT COUNT(*) INTO _owned
    FROM task_comment
   WHERE id = _id AND author_uid = _author_uid;

  IF _owned = 0 THEN
    SELECT _id AS id, 0 AS affected, 0 AS removed_replies;
  ELSE
    SELECT COUNT(*) INTO _replies FROM task_comment WHERE parent_id = _id;

    -- Reactions on the root AND on each of its replies.
    DELETE r FROM task_comment_reaction r
      JOIN task_comment c ON c.id = r.comment_id
     WHERE c.id = _id OR c.parent_id = _id;

    -- Same for attached files. Only the link rows go: the media nodes live in
    -- the folder body and stay there, exactly as unlinking a task attachment
    -- leaves the file in place.
    DELETE cf FROM task_comment_file cf
      JOIN task_comment c ON c.id = cf.comment_id
     WHERE c.id = _id OR c.parent_id = _id;

    DELETE FROM task_comment WHERE parent_id = _id;
    DELETE FROM task_comment WHERE id = _id;

    SELECT _id AS id, 1 AS affected, _replies AS removed_replies;
  END IF;
END$
DELIMITER ;
