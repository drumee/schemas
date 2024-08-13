DELIMITER $


-- DROP PROCEDURE IF EXISTS `dmz_notify_list_next`$
DROP PROCEDURE IF EXISTS `dmz_notify_list`$
CREATE PROCEDURE `dmz_notify_list`(
  IN _flag   VARCHAR(50)
)
BEGIN
  DECLARE _ts INT(11);
  DECLARE _hub_id VARCHAR(16);
  
  SELECT UNIX_TIMESTAMP()INTO _ts;
  SELECT UNIX_TIMESTAMP()-43200 INTO _ts WHERE _flag = 'new' ;
  SELECT id FROM yp.entity WHERE db_name=DATABASE() INTO _hub_id;

  SELECT 
    t.id token,
    t.hub_id,
    u.id recipient_id,
    u.email,
    t.notify_at
  FROM 
    permission p 
    INNER JOIN yp.dmz_token t ON p.entity_id = t.guest_id
    INNER JOIN yp.dmz_user u ON p.entity_id = u.id
    WHERE t.notify_at <= _ts AND t.hub_id=_hub_id;
END$

DELIMITER ;




