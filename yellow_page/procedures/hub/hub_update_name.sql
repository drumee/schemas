DELIMITER $

DROP PROCEDURE IF EXISTS `hub_update_name`$
CREATE PROCEDURE `hub_update_name`(
  IN _hub_id    VARCHAR(16),
  IN _name      VARCHAR(80)
)
BEGIN
  UPDATE hub SET 
    hubname=_name, 
    `profile`=JSON_SET(`profile`, "$.name", _name) 
  WHERE id=_hub_id;
  SELECT 
    e.id, 
    h.hubname as ident, 
    e.mtime, 
    e.status, 
    e.type, 
    e.area,
    e.vhost, 
    e.headline, 
    e.layout as fallback, 
    e.home_layout as home,
    e.layout, 
    e.db_name, 
    e.db_host, 
    e.fs_host, 
    e.home_dir,
    e.settings, 
    h.hubname, 
    h.permission,
    h.dmail,  
    h.profile
    FROM entity e 
      INNER JOIN hub h ON e.id=h.id
      INNER JOIN vhost v ON e.id=v.id
    WHERE e.id = _id;
END $
DELIMITER ;
