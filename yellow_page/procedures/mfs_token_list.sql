-- File: schemas/yellow_page/procedures/mfs_token_list.sql
-- Purpose: List all MFS export tokens created by a user

DELIMITER $

DROP PROCEDURE IF EXISTS `mfs_token_list`$

CREATE PROCEDURE `mfs_token_list`(
  IN _user_id VARCHAR(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci
)
BEGIN
  DECLARE _ctime INT UNSIGNED;
  
  SELECT UNIX_TIMESTAMP() INTO _ctime;
  
  SELECT 
    t.token,
    t.hub_id,
    t.node_id,
    t.pseudo_entity_uid,
    t.expiry_time,
    t.ctime,
    CASE 
      WHEN t.expiry_time = 0 THEN 'never'
      WHEN t.expiry_time > _ctime THEN 'active'
      ELSE 'expired'
    END AS status,
    CASE 
      WHEN t.expiry_time = 0 THEN 'Never'
      WHEN t.expiry_time > _ctime THEN FROM_UNIXTIME(t.expiry_time)
      ELSE CONCAT('Expired at ', FROM_UNIXTIME(t.expiry_time))
    END AS expiry_display,
    FROM_UNIXTIME(t.ctime) AS created_at,
    e.db_name AS hub_db_name
  FROM yp.mfs_token t
  INNER JOIN yp.entity e ON t.hub_id = e.id
  WHERE t.user_id = _user_id
  ORDER BY t.ctime DESC;

END$

DELIMITER ;