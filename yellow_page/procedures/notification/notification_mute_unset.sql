-- File: schemas/yellow_page/procedures/notification/notification_mute_unset.sql
-- Purpose: switch the real-time notification popups back ON for one workspace,
--          or everywhere. Round 3 / Sprint 1 row 6.
--
-- POPUP CHANNEL ONLY -- see notification_mute.sql.
--
-- THE TWO SCOPES ARE NOT SYMMETRIC WITH notification_mute_set, on purpose:
--
--   _hub_id = ''      unmute EVERYTHING. Deletes the global row and any
--                     per-workspace rows in one go, so "turn my popups back on"
--                     is a single call that cannot leave a workspace silently
--                     muted behind a lifted global mute.
--   _hub_id = <hub>   unmute that workspace only.
--
-- ⚠️ Unmuting a single workspace does NOT lift an active global mute -- it
-- deletes a per-workspace row that a global mute does not have. That is why the
-- client must read the state (or the rows this returns) rather than assume: with
-- a global mute in force the only thing that restores one workspace is unmuting
-- everything. Surfacing that is a UI decision, and the state proc gives the UI
-- what it needs to make it.
--
-- DELETING NOTHING IS SUCCESS. Unmuting something that was never muted is the
-- state the caller asked for, so it returns the same empty state rather than an
-- error -- the panel toggle can be driven straight from it without a "was it
-- muted?" read first.
--
-- RETURNS THE FULL RESULTING STATE, same shape as notification_mute_state.

DELIMITER $

DROP PROCEDURE IF EXISTS `notification_mute_unset`$

CREATE PROCEDURE `notification_mute_unset`(
  IN _uid VARCHAR(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
  IN _hub_id VARCHAR(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci
)
BEGIN
  -- Normalised on the PARAMETER rather than into a local -- see the note in
  -- notification_mute_set: an IN parameter carries the explicit collation
  -- declared above, a DECLAREd local would inherit the schema default.
  SET _hub_id = IFNULL(_hub_id, '');

  IF _uid IS NOT NULL AND _uid <> '' THEN
    IF _hub_id = '' THEN
      DELETE FROM notification_mute WHERE uid = _uid;
    ELSE
      DELETE FROM notification_mute WHERE uid = _uid AND hub_id = _hub_id;
    END IF;
  END IF;

  SELECT hub_id, ctime
    FROM notification_mute
    WHERE uid = _uid
    ORDER BY (hub_id = '') DESC, ctime ASC;
END$

DELIMITER ;
