-- File: schemas/yellow_page/procedures/notification/notification_mute_set.sql
-- Purpose: switch OFF the real-time notification popups for one workspace, or
--          for all of them. Round 3 / Sprint 1 row 6.
--
-- POPUP CHANNEL ONLY. See notification_mute.sql -- the feed and the unread
-- badges must keep working for a muted user, so nothing in activity.list /
-- activity.get_feed may ever read what this writes.
--
-- IDEMPOTENT BY THE PRIMARY KEY. Muting an already-muted scope is an UPDATE of
-- ctime to itself, not a second row and not an error: the button is reachable
-- from two places (the chat toast and the chat detail panel) and a user who
-- clicks it twice means the same thing both times.
--
-- ctime IS DELIBERATELY NOT REFRESHED on a repeat mute -- same rule as
-- feature_mark's first-use stamp. It answers "since when has this been muted",
-- which a second click does not change.
--
-- MUTING GLOBALLY CLEARS THE PER-WORKSPACE ROWS first, so the table never holds
-- two competing answers. The UI presents the scopes as alternatives (Figma's two
-- exclusive confirmation states), and layered state the user cannot see is state
-- the user cannot unpick.
--
-- AN EMPTY _uid IS A NO-OP, NOT AN ERROR, following feature_mark: the popup path
-- is reachable by a DMZ guest, and a guest has no preference to store. Raising
-- here would turn a harmless click into a 500.
--
-- RETURNS THE FULL RESULTING STATE, identical in shape to
-- notification_mute_state, so the client can refresh its cache from the write
-- itself instead of following every mute with a second round trip.

DELIMITER $

DROP PROCEDURE IF EXISTS `notification_mute_set`$

CREATE PROCEDURE `notification_mute_set`(
  IN _uid VARCHAR(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
  IN _hub_id VARCHAR(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci
)
BEGIN
  -- Normalised on the PARAMETER rather than into a local: an IN parameter is a
  -- local copy and carries the explicit collation declared above, where a
  -- DECLAREd variable would inherit the schema default and compare against
  -- hub_id under a collation nothing here pins.
  SET _hub_id = IFNULL(_hub_id, '');

  IF _uid IS NOT NULL AND _uid <> '' THEN
    -- A global mute supersedes every per-workspace one. Done before the insert
    -- so that the global row itself is never caught by this delete.
    IF _hub_id = '' THEN
      DELETE FROM notification_mute WHERE uid = _uid AND hub_id <> '';
    END IF;

    INSERT INTO notification_mute (uid, hub_id, ctime)
      VALUES (_uid, _hub_id, UNIX_TIMESTAMP())
      ON DUPLICATE KEY UPDATE ctime = ctime;
  END IF;

  SELECT hub_id, ctime
    FROM notification_mute
    WHERE uid = _uid
    ORDER BY (hub_id = '') DESC, ctime ASC;
END$

DELIMITER ;
