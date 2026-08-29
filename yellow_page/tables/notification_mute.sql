-- File: schemas/yellow_page/tables/notification_mute.sql
-- Purpose: which notification POPUPS a user has switched off, per workspace or
--          globally. Round 3 / Sprint 1 row 6 (the chat toast's Mute button).
--
-- SCOPE OF THE FLAG — read this before joining it to anything. A row here mutes
-- the real-time POPUP CHANNEL ONLY. It must never be read by the notification
-- feed (`activity.list` / `activity.get_feed`) or by the unread counters: a
-- muted user still gets every row in the Notification Center and still gets the
-- bell badge, they simply stop being interrupted by a card. Muting is "stop
-- talking to me", not "stop recording". Anything that reads this table from a
-- feed path is a bug.
--
-- `hub_id = ''` IS THE GLOBAL ROW, not a missing value. It is why the column is
-- NOT NULL DEFAULT '' rather than nullable: MySQL's PRIMARY KEY cannot contain a
-- NULL, so a nullable "all workspaces" marker could be inserted twice for the
-- same user and the uniqueness the upsert depends on would be gone.
--
-- GLOBAL AND PER-WORKSPACE ROWS DO NOT LAYER. notification_mute_set('') deletes
-- the caller's per-workspace rows before inserting the global one, so the table
-- holds exactly one interpretation of what the user last chose. The UI offers
-- the two scopes as alternatives (Figma has two exclusive confirmation states,
-- muted-all-workspace and muted-selected-workspace), so storing them as layers
-- would create states the user has no way to see or unpick.
--
-- NO FOREIGN KEY, following feature_usage and funnel_milestone. A deleted
-- workspace should not fail a user's unmute, and this table is a preference, not
-- an audit trail — a stale row costs one suppressed popup for a workspace the
-- user can no longer open.
--
-- COLLATION IS utf8mb4_general_ci because yp.drumate.id, yp.hub.id and
-- yp.entity.id all are — verified live against the stage yp on 2026-08-26, not
-- assumed. (yp.contact_activity.uid is ascii_general_ci and is the odd one out;
-- do not copy it. Every read of this table compares uid against drumate, and a
-- mismatched collation cannot seek the index.)

CREATE TABLE IF NOT EXISTS `notification_mute` (
  `uid` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL
    COMMENT 'Reference to yp.drumate.id -- the user who muted',
  `hub_id` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT ''
    COMMENT 'Workspace muted. Empty string means ALL workspaces, and is a real value, not unknown.',
  `ctime` int(11) unsigned NOT NULL
    COMMENT 'When this scope was muted. Preserved when the same scope is muted again.',
  PRIMARY KEY (`uid`,`hub_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
COMMENT='Notification popup mute -- popup channel only, never the feed or the badge'
