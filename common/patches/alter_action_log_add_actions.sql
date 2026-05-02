-- Patch: Add new action types for Admin Console Audit Logs tab
-- Apply to: all hub DBs (common/patches/)
-- Must update starter-kit manifest after applying

ALTER TABLE `action_log`
  MODIFY `action` enum(
    'added',
    'deleted',
    'changed',
    'left',
    'removed',
    'backup',
    'connection',
    'grant_access',
    'change_policy',
    'share_link',
    'create_workspace'
  ) DEFAULT NULL;