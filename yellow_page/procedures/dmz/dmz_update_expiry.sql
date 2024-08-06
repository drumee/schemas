DELIMITER $

DROP PROCEDURE IF EXISTS `dmz_update_expiry_new`$
CREATE PROCEDURE `dmz_update_expiry_new`(
  IN _hub_id    VARCHAR(16),
  IN _node_id   VARCHAR(16),
  IN _mode      ENUM('limited' , 'infinity'),
  IN _expiry    INTEGER
)
BEGIN
  
  DECLARE _ts INT(11) DEFAULT 0;
  DECLARE _tx INT(11) DEFAULT 0;
  DECLARE _db_name VARCHAR(30);
  DECLARE _owner_id VARCHAR(30);

  SELECT UNIX_TIMESTAMP() INTO _ts;  

  SELECT db_name FROM entity WHERE id=_hub_id 
    INTO _db_name;

  SELECT owner_id FROM hub WHERE id=_hub_id 
    INTO _owner_id;

  SELECT IF(_mode ='infinity', 0,
      UNIX_TIMESTAMP(TIMESTAMPADD(HOUR,_expiry, FROM_UNIXTIME(_ts)))) INTO _tx;

  SET @s = CONCAT("UPDATE ", 
    _db_name,".permission SET ",
    " expiry_time=? ",
    "WHERE entity_id <> ? AND resource_id=? ");
  PREPARE stmt FROM @s;
  EXECUTE stmt USING _tx, _owner_id, _node_id;
  DEALLOCATE PREPARE stmt; 


  SET @s = CONCAT("UPDATE ", 
    _db_name,".permission p",
    " INNER JOIN ",_db_name ,".media m ON m.id = p.entity_id 
     INNER JOIN yp.dmz_media d ON m.id=d.id 
    SET p.expiry_time= ?
    WHERE d.hub_id =?");
  PREPARE stmt FROM @s;
  EXECUTE stmt USING _tx,   _hub_id;
  DEALLOCATE PREPARE stmt;

END$

DELIMITER ;

-- call yp.dmz_update_expiry_new( 'f7659df5f7659e0b', 'f85ccc5ef85ccc77', 'limited', 0);
