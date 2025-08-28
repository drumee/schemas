DELIMITER $

DROP PROCEDURE IF EXISTS `socket_get`$
CREATE PROCEDURE `socket_get`(
  IN _id VARCHAR(80) CHARACTER SET ascii 
)
BEGIN
  SELECT 
    s.id AS connection_id,
    s.id AS socket_id,
    COALESCE(e.id, u.id) user_id,
    COALESCE(d.username, u.email) username,    
    s.server,
    s.location,
    s.server AS endpointAddress,
    s.location AS endpointRoute,
    COALESCE(e.home_dir, yp.get_sysconf('nobody_home_dir')) AS home_dir,
    COALESCE(d.remit, 0) as remit,
    COALESCE(d.profile, '{}') profile,
    COALESCE(e.settings, '{}') settings,
    COALESCE(e.db_name, yp.get_sysconf('nobody_db')) db_name,
    COALESCE(disk_usage(e.id), 0) disk_usage,
    COALESCE(d.quota, 0) as quota,
    COALESCE(d.fullname, u.name) as fullname
    FROM socket s 
      LEFT JOIN entity e ON e.id=s.uid
      LEFT JOIN drumate d ON d.id=s.uid
      LEFT JOIN dmz_user u ON u.id=s.uid
    WHERE s.id=_id AND s.state='active' 
    ORDER BY s.ctime DESC LIMIT 1;

END$

DELIMITER ;