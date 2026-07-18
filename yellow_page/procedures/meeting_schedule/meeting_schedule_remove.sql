DELIMITER $

DROP PROCEDURE IF EXISTS `meeting_schedule_remove`$
CREATE PROCEDURE `meeting_schedule_remove`(
  IN _hub_id VARCHAR(16),
  IN _nid VARCHAR(16)
)
BEGIN
  DELETE FROM meeting_schedule WHERE hub_id=_hub_id AND nid=_nid;
END$

DELIMITER ;

-- #####################
