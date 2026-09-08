-- Unsubscribe a user from a column's change-notifications.
-- Workspace-scoped: a column belongs to the WORKSPACE now, not to a folder
-- (see alter_task_column_workspace_scope), so its watch does too. _nid is
-- kept in the signature — callers still pass one and dropping it would break
-- every CALL — but it no longer selects a scope: '0' is the single workspace
-- row key, the same sentinel this table already used for the root.
DELIMITER $
DROP PROCEDURE IF EXISTS `task_column_watch_unset`$
CREATE PROCEDURE `task_column_watch_unset`(
  IN _uid VARCHAR(16),
  IN _nid VARCHAR(16),
  IN _column_key VARCHAR(32)
)
BEGIN
  DELETE FROM task_column_watch
   WHERE uid = _uid
     AND nid = '0'
     AND column_key = _column_key;
END$
DELIMITER ;
