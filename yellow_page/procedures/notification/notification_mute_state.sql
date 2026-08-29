-- File: schemas/yellow_page/procedures/notification/notification_mute_state.sql
-- Purpose: the caller's current popup-mute state, as one row per muted scope.
--          Round 3 / Sprint 1 row 6.
--
-- POPUP CHANNEL ONLY -- see notification_mute.sql. This is read once when the
-- desk boots and again after every mute/unmute (both of which return this same
-- shape, so the refresh is usually free). It is NEVER consulted per message: a
-- per-notification lookup would put a query on the chat push path and, worse,
-- would make the popup's behaviour depend on a round trip that can fail
-- silently -- the exact trap that cost two days on the folder chip in Phase 2.
--
-- READS NOTHING BUT THIS TABLE. It deliberately does not join hub to return
-- workspace names: the client already has the workspace list it renders the
-- scope picker from, and joining here would make an unmutable deleted workspace
-- disappear from the state instead of showing up as a row the user can clear.
--
-- ROW SHAPE. `hub_id = ''` is the global mute and is ordered FIRST so a client
-- reading only the first row still learns the most important fact. An empty
-- result means nothing is muted, which is the default for every user -- there is
-- no "unmuted" row and no per-user initialisation.
--
-- A GLOBAL ROW EXCLUDES PER-WORKSPACE ROWS by construction (notification_mute_set
-- clears them), so a result carrying both cannot arise from these procedures. A
-- client should still treat a global row as decisive rather than asserting on it.

DELIMITER $

DROP PROCEDURE IF EXISTS `notification_mute_state`$

CREATE PROCEDURE `notification_mute_state`(
  IN _uid VARCHAR(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci
)
BEGIN
  SELECT hub_id, ctime
    FROM notification_mute
    WHERE uid = _uid
    ORDER BY (hub_id = '') DESC, ctime ASC;
END$

DELIMITER ;
