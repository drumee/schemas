DELIMITER $



DROP PROCEDURE IF EXISTS `ticket_detail`$
CREATE PROCEDURE `ticket_detail`(
  IN _ticket_id  int(11) 
  )
BEGIN
  SELECT *  FROM ticket WHERE ticket_id =_ticket_id;
END $

DELIMITER ;
