DELIMITER $


DROP PROCEDURE IF EXISTS `dmz_settings`$
CREATE PROCEDURE `dmz_settings`(
)
BEGIN
  DECLARE _ts INT(11);
  DECLARE _hub_id VARCHAR(16);
  DECLARE _home_id VARCHAR(16);
  DECLARE _public_token VARCHAR(60);
  DECLARE _permission INTEGER;
  DECLARE _days INTEGER;
  DECLARE _hours INTEGER;

  SELECT UNIX_TIMESTAMP() INTO _ts;


  SELECT id, home_id FROM yp.entity WHERE db_name=DATABASE() 
    INTO _hub_id, _home_id;

  SELECT t.id link,
    IF(t.fingerprint IS NULL, 0, 1) hasPaswword, 
    yp.duration_days(p.expiry_time) days,
    yp.duration_hours(p.expiry_time) hours,
    t.fingerprint,
    p.expiry_time,
    p.permission,
    CASE 
      WHEN IFNULL(p.expiry_time,0) = 0 THEN 'infinity' 
      WHEN (p.expiry_time - _ts) <= 0  THEN 'expired'
      ELSE 'active'
    END   dmz_expiry
  FROM  permission p 
    INNER JOIN yp.dmz_token t ON p.entity_id = t.guest_id
    INNER JOIN yp.dmz_user u ON p.entity_id = u.id
  WHERE t.hub_id=_hub_id AND t.node_id=_home_id AND 
    u.id = yp.get_sysconf('guest_id');


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
  WHERE t.hub_id=_hub_id AND t.node_id=_home_id AND 
  u.id <> yp.get_sysconf('guest_id');
END$

DELIMITER ;




