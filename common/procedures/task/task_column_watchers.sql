-- Resolve the uids subscribed to a given column of this workspace. The server
-- uses this to fan a task-change notification out to that column's watchers.
-- Workspace-scoped: a column belongs to the WORKSPACE now, not to a folder
-- (see alter_task_column_workspace_scope), so its watch does too. _nid is
-- kept in the signature — callers still pass one and dropping it would break
-- every CALL — but it no longer selects a scope: '0' is the single workspace
-- row key, the same sentinel this table already used for the root.
DELIMITER $
DROP PROCEDURE IF EXISTS `task_column_watchers`$
CREATE PROCEDURE `task_column_watchers`(
  IN _nid VARCHAR(16),
  IN _column_key VARCHAR(32)
)
BEGIN
  SELECT w.uid
    FROM task_column_watch w
    INNER JOIN permission p
      ON p.entity_id = w.uid
     AND p.resource_id = '*'
     AND p.permission > 0
     AND (p.expiry_time = 0 OR p.expiry_time > UNIX_TIMESTAMP())
   WHERE w.nid = '0'
     AND w.column_key = _column_key;
END$
DELIMITER ;
