DELIMITER $
DROP PROCEDURE IF EXISTS `task_delete`$
CREATE PROCEDURE `task_delete`(
  IN _id VARCHAR(16)
)
BEGIN
  -- Deleting a task also deletes its subtasks — there is no orphan state and no
  -- promote-to-standalone path. Nesting is one level (enforced in task.create),
  -- so collecting the direct children is the complete set; no recursion needed.
  DECLARE _subs TEXT DEFAULT NULL;
  DECLARE _affected INT DEFAULT 0;

  -- Snapshot the children BEFORE any delete: the task rows are the source for
  -- the dependent-row subqueries below, and the caller needs the ids to prune
  -- them from its local list without a full reload.
  SELECT GROUP_CONCAT(id) INTO _subs FROM task WHERE parent_task_id = _id;

  -- Explicitly delete dependent rows first (no FK cascade). Each condition
  -- covers the task itself AND its subtasks. The subqueries read `task`, which
  -- is a different table from every delete target here, so they are legal —
  -- only the final DELETE FROM task could not be written that way, and it
  -- doesn't need to be.
  DELETE FROM task_file
   WHERE task_id = _id
      OR task_id IN (SELECT id FROM task WHERE parent_task_id = _id);
  DELETE FROM task_label
   WHERE task_id = _id
      OR task_id IN (SELECT id FROM task WHERE parent_task_id = _id);
  DELETE FROM task_assignee
   WHERE task_id = _id
      OR task_id IN (SELECT id FROM task WHERE parent_task_id = _id);
  DELETE r FROM task_comment_reaction r
    JOIN task_comment c ON c.id = r.comment_id
   WHERE c.task_id = _id
      OR c.task_id IN (SELECT id FROM task WHERE parent_task_id = _id);
  DELETE cf FROM task_comment_file cf
    JOIN task_comment c ON c.id = cf.comment_id
   WHERE c.task_id = _id
      OR c.task_id IN (SELECT id FROM task WHERE parent_task_id = _id);
  DELETE FROM task_comment
   WHERE task_id = _id
      OR task_id IN (SELECT id FROM task WHERE parent_task_id = _id);

  -- Parent and children in one statement, so a subtask can never survive its
  -- parent even if this proc is interrupted between statements.
  DELETE FROM task WHERE id = _id OR parent_task_id = _id;
  SET _affected = ROW_COUNT();

  -- affected counts every task row removed (parent + subtasks). subtask_ids is
  -- NULL when the task had none.
  SELECT _affected AS affected, _subs AS subtask_ids;
END$
DELIMITER ;
