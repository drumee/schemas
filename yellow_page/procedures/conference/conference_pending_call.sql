
DELIMITER $


-- =========================================================
-- update_conference
-- =========================================================
DROP PROCEDURE IF EXISTS `conference_pending_call`$
CREATE PROCEDURE `conference_pending_call`(
  IN _arg JSON
)
BEGIN
  DECLARE _caller_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _callee_id VARCHAR(128) DEFAULT NULL;  
  DECLARE _hub_id VARCHAR(128) DEFAULT NULL;  
  DECLARE _username VARCHAR(128) DEFAULT NULL;  
  DECLARE _firstname VARCHAR(128) DEFAULT NULL;  
  DECLARE _callee_db VARCHAR(128) DEFAULT NULL;  

  SELECT JSON_VALUE(_arg, "$.callee_id") INTO _callee_id;
  SELECT JSON_VALUE(_arg, "$.caller_id") INTO _caller_id;

  SELECT 
    ctime, 
    UNIX_TIMESTAMP() `timestamp`, 
    JSON_VALUE(args, "$.guest_id") calle_id, 
    hub_id, 
    `uid`,
    1 cross_call
    FROM services_log WHERE `name`='conference.invite' AND (ctime + 5) > UNIX_TIMESTAMP() 
    AND JSON_VALUE(args, "$.guest_id")=_caller_id ORDER BY ctime DESC LIMIT 1;

END$


DELIMITER ;