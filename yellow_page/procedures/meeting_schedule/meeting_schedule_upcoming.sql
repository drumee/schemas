DELIMITER $

DROP PROCEDURE IF EXISTS `meeting_schedule_upcoming`$
-- Meetings starting within the next `_lead` seconds that haven't had their
-- heads-up push yet. The counterpart of meeting_schedule_due, which handles the
-- "starting now" announcement.
--
-- `fired=0` is part of the filter so a meeting already announced as started can
-- never also produce a heads-up (possible for a recurring occurrence rolled
-- forward inside the lead window, or after a clock adjustment).
CREATE PROCEDURE `meeting_schedule_upcoming`(
  IN _now INT(11) UNSIGNED,
  IN _lead INT(11) UNSIGNED
)
BEGIN
  SELECT * FROM meeting_schedule
    WHERE early_fired=0
      AND fired=0
      AND stime > _now
      AND stime <= _now + _lead
    ORDER BY stime ASC;
END$

DELIMITER ;

-- #####################
