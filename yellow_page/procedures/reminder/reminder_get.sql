DELIMITER $

DROP PROCEDURE IF EXISTS `reminder_get`$
CREATE PROCEDURE `reminder_get`(
  IN _args JSON
)
BEGIN
  SELECT *, id reminder_id FROM reminder WHERE id=JSON_VALUE(_args, "$.id")  OR 
  (`uid` = JSON_VALUE(_args, "$.uid") AND 
   `nid` = JSON_VALUE(_args, "$.nid") AND 
   `hub_id` = JSON_VALUE(_args, "$.hub_id") 
  ) LIMIT 1;
END$

DELIMITER ;

-- #####################
