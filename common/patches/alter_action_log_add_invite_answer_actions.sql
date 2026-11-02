-- Patch: add invite_declined / invite_cancelled to action_log.action.
-- Apply to: all hub AND drumate DBs (common), then restart the factory.
--
-- hub.decline_invite has written 'invite_declined' and hub.cancel_invite
-- writes 'invite_cancelled', but neither value was in the enum: under
-- STRICT_TRANS_TABLES the audit insert raised and no row was ever written.
-- Values are appended at the end, so existing rows and their stored indexes
-- are unchanged (an in-place, metadata-only change).

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
    'invite_accepted',
    'invite_declined',
    'invite_cancelled'
  ) DEFAULT NULL;
