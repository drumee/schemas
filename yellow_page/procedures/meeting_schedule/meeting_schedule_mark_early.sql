DELIMITER $

DROP PROCEDURE IF EXISTS `meeting_schedule_mark_early`$
-- Flag the heads-up push as sent for this occurrence. Cleared again by
-- meeting_schedule_upsert (meeting moved) and meeting_schedule_mark_fired
-- (recurring series rolled to its next occurrence).
CREATE PROCEDURE `meeting_schedule_mark_early`(
  IN _id VARCHAR(16)
)
BEGIN
  UPDATE meeting_schedule
    SET early_fired=1, mtime=UNIX_TIMESTAMP()
    WHERE id=_id;
END$

DELIMITER ;

-- #####################
