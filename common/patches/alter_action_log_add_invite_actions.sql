-- Patch: Add invite lifecycle action types for Admin Console Audit Logs
-- (invite_sent / invite_accepted). Apply to: all hub AND drumate DBs.
-- Must update starter-kit manifest after applying.

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
    'create_workspace',
    'invite_sent',
    'invite_accepted'
  ) DEFAULT NULL;
