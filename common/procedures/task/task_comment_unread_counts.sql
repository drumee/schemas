DELIMITER $

-- =========================================================
-- task_comment_unread_counts
-- Unread comment count for each subtask of _parent_id, as seen by _uid.
-- Returns {task_id, unread} only for children with unread > 0.
--
-- Unread = written by someone else, with ctime after the user's read mark on
-- that task (task_comment_mark_read). With no mark, the baseline is the
-- feature epoch row ('*','*') — so pre-rollout comments count as read — or 0
-- on an instance that has none. Replies count like top-level comments; an
-- edit keeps ctime, so it never makes a comment unread again.
-- =========================================================
DROP PROCEDURE IF EXISTS `task_comment_unread_counts`$
CREATE PROCEDURE `task_comment_unread_counts`(
  IN _parent_id VARCHAR(16),
  IN _uid VARCHAR(16)
)
BEGIN
  -- ascii to match the ascii id columns (else ER_CANT_AGGREGATE_2COLLATIONS).
  DECLARE _p     VARCHAR(16) CHARACTER SET ascii DEFAULT _parent_id;
  DECLARE _u     VARCHAR(16) CHARACTER SET ascii DEFAULT _uid;
  DECLARE _epoch INT DEFAULT 0;

  SELECT IFNULL(MAX(read_ts), 0) INTO _epoch
    FROM task_comment_read
   WHERE task_id = '*'
     AND uid = '*';

  SELECT s.id AS task_id, COUNT(c.id) AS unread
    FROM task s
    JOIN task_comment c
      ON c.task_id = s.id
     AND c.author_uid <> _u
    LEFT JOIN task_comment_read r
      ON r.task_id = s.id
     AND r.uid = _u
   WHERE s.parent_task_id = _p
     AND c.ctime > COALESCE(r.read_ts, _epoch)
   GROUP BY s.id;
END $

DELIMITER ;
