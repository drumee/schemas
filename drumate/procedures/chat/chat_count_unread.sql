DELIMITER $
/*

  Status : active 

*/
DROP FUNCTION IF EXISTS `chat_count_unread`$
CREATE FUNCTION `chat_count_unread`(
  _uid VARCHAR(16)
)
RETURNS JSON DETERMINISTIC
BEGIN 
  DECLARE _res int(11) unsigned;
  SELECT count(*) c FROM channel WHERE 
    JSON_VALUE(JSON_EXTRACT(metadata, "$._seen_"), CONCAT("$.", _uid)) IN(null) INTO _res;
  RETURN _res;
 
END$  

DELIMITER ;