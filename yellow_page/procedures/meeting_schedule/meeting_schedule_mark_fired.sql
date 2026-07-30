DELIMITER $

DROP PROCEDURE IF EXISTS `meeting_schedule_mark_fired`$
-- Called once a meeting's start reminder has been sent. For a one-off meeting
-- (_next_stime NULL/0) the row is flagged fired. For a recurring meeting the
-- worker passes the next occurrence, which re-arms the row (fired back to 0) so
-- the same node keeps reminding on its cadence.
CREATE PROCEDURE `meeting_schedule_mark_fired`(
  IN _id VARCHAR(16),
  IN _next_stime INT(11) UNSIGNED,
  IN _next_etime INT(11) UNSIGNED
)
BEGIN
  IF _next_stime IS NOT NULL AND _next_stime > 0 THEN
    -- Rolling to the next occurrence re-arms BOTH pushes: the heads-up has to
    -- fire again for the new start time, not stay flagged from the last one.
    UPDATE meeting_schedule
      SET stime=_next_stime, etime=_next_etime, fired=0, early_fired=0,
          mtime=UNIX_TIMESTAMP()
      WHERE id=_id;
  ELSE
    UPDATE meeting_schedule SET fired=1, mtime=UNIX_TIMESTAMP() WHERE id=_id;
  END IF;
END$

DELIMITER ;

-- #####################
