DELIMITER $

DROP PROCEDURE IF EXISTS `meeting_schedule_due`$
-- Meetings whose start time has arrived and that haven't been notified yet.
-- `_grace` bounds how far back we still fire, so a meeting missed while the
-- worker was down for a long stretch isn't announced hours late (0 = no floor).
CREATE PROCEDURE `meeting_schedule_due`(
  IN _now INT(11) UNSIGNED,
  IN _grace INT(11) UNSIGNED
)
BEGIN
  SELECT * FROM meeting_schedule
    WHERE fired=0
      AND stime > 0
      AND stime <= _now
      AND (_grace = 0 OR stime >= _now - _grace)
    ORDER BY stime ASC;
END$

DELIMITER ;

-- #####################
