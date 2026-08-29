-- Subscribe a user to change-notifications for one column of this workspace.
-- Workspace-scoped: a column belongs to the WORKSPACE now, not to a folder
-- (see alter_task_column_workspace_scope), so its watch does too. _nid is
-- kept in the signature — callers still pass one and dropping it would break
-- every CALL — but it no longer selects a scope: '0' is the single workspace
-- row key, the same sentinel this table already used for the root.
-- Idempotent: re-subscribing is a no-op (INSERT IGNORE on the composite key).
DELIMITER $
DROP PROCEDURE IF EXISTS `task_column_watch_set`$
CREATE PROCEDURE `task_column_watch_set`(
  IN _uid VARCHAR(16),
  IN _nid VARCHAR(16),
  IN _column_key VARCHAR(32)
)
BEGIN
  IF _uid IS NOT NULL AND _uid <> '' AND _column_key IS NOT NULL AND _column_key <> '' THEN
    INSERT IGNORE INTO task_column_watch (uid, nid, column_key, ctime)
    VALUES (_uid, '0', _column_key, UNIX_TIMESTAMP());
  END IF;
END$
DELIMITER ;
