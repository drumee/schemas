DELIMITER $

DROP PROCEDURE IF EXISTS `reminder_remove`$
CREATE PROCEDURE `reminder_remove`(
  IN _args JSON
)
BEGIN
  DELETE FROM reminder WHERE id=JSON_VALUE(_args, "$.id")  OR 
  (`uid` = JSON_VALUE(_args, "$.uid") AND 
   `nid` = JSON_VALUE(_args, "$.nid") AND 
   `hub_id` = JSON_VALUE(_args, "$.hub_id") 
  );
END$

DELIMITER ;

-- #####################
