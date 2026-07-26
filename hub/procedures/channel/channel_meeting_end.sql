-- File: schemas/hub/procedures/channel/channel_meeting_end.sql
-- =========================================================
-- channel_meeting_end  (HUB class — team chat + folder window)
-- Flip a posted "meeting started" system card to its "ended" state IN PLACE so
-- a single chat card transitions from "Join meeting" to "Meeting ended" instead
-- of a second card being posted. The message body keeps its
-- `[[MEETING:start:...]]` sentinel untouched; only `metadata.meeting_status` is
-- set to 'ended'. Every other metadata key (_seen_, _reactions_, _scope_nid) is
-- preserved — same targeted-JSON-write discipline as message_reaction_toggle.
-- Idempotent (re-ending an already-ended card is a no-op write).
--
-- Returns one row: found (0 if the message is absent).
--
-- Apply (DEV/STAGE ONLY — every hub instance on the server):
--   bin/patch-from-file hub/procedures/channel/channel_meeting_end.sql hub
-- =========================================================
DELIMITER $

DROP PROCEDURE IF EXISTS `channel_meeting_end`$
CREATE PROCEDURE `channel_meeting_end`(
  IN _message_id VARCHAR(16) CHARACTER SET ascii
)
BEGIN
  DECLARE _exists INT DEFAULT 0;

  SELECT COUNT(1) INTO _exists FROM `channel` WHERE message_id = _message_id;

  IF _exists > 0 THEN
    UPDATE `channel`
       SET metadata = JSON_SET(
             COALESCE(NULLIF(metadata, ''), '{}'),
             '$.meeting_status', 'ended'
           )
     WHERE message_id = _message_id;
  END IF;

  SELECT _exists AS found;
END $

DELIMITER ;
