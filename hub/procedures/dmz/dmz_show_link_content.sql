DELIMITER $


-- =======================================================================
--  call dmz_show_link_content ('fd2eefd7fd2eeff4');
-- =======================================================================
DROP PROCEDURE IF EXISTS `dmz_show_link_content`$
-- CREATE PROCEDURE `dmz_show_link_content`(
--   IN _share_id VARCHAR(50),
--   IN _sid varchar(64),
--   IN _recipient_id VARCHAR(16) 
  
-- )
-- BEGIN
--   DECLARE _vhost VARCHAR(255);
--   DECLARE _hub_id VARCHAR(16);
--   DECLARE _area VARCHAR(50);
--   DECLARE _home_dir VARCHAR(512);
--   DECLARE _home_id VARCHAR(16);
--   DECLARE _src_db_name VARCHAR(50);
--   DECLARE _accessibility VARCHAR(20);
--   DECLARE _sender VARCHAR(255);
--   DECLARE _sender_id VARCHAR(16);
--   DECLARE _is_verified INT DEFAULT 0;



--   SELECT  is_verified FROM yp.cookie_share 
--     WHERE id = _sid  AND (share_id = _share_id  OR hub_id = _share_id)  
--           AND  recipient_id =  _recipient_id
--     INTO _is_verified;

--   CALL mediaEnv(_vhost, _hub_id, _area, _home_dir, _home_id, _src_db_name, _accessibility);

--   SELECT 
--     s.recipient_id public_id, 
--     m.id  AS nid,
--     s.id share_id, 
--     m.parent_id AS pid,
--     m.parent_id AS parent_id,
--     m.file_path as filepath,
--     -- g.email recipient_email,
--     p.entity_id as recipient_id,
--     _home_id  AS home_id,   
--     _hub_id AS hub_id,
--     ff.capability,
--     m.user_filename AS filename,
--     m.filesize AS filesize,
--     m.caption,
--     m.extension AS ext,
--     m.category AS ftype,
--     m.category AS filetype,
--     m.mimetype,
--     m.download_count AS view_count,
--     m.geometry,
--     m.upload_time AS ctime,
--     p.permission,
--     p.permission privilege,
--     m.publish_time AS ptime,
--     _vhost AS vhost,
--     d.fullname AS sender,
--     d.id AS sender_id,
--     d.firstname,
--     d.lastname,
--     h.name,
--     yp.duration_days(p.expiry_time) days,
--     yp.duration_hours(p.expiry_time) hours,
--     CASE 
--       WHEN s.fingerprint IS NULL THEN 0 
--       ELSE 1
--     END is_password,
--     CASE 
--       WHEN s.fingerprint IS NULL THEN 1
--       ELSE _is_verified
--     END is_verified
--   FROM media m
--     LEFT JOIN yp.filecap ff ON m.extension=ff.extension
--     INNER JOIN permission p ON m.id = p.resource_id
--     INNER JOIN yp.share s ON s.permission_id=p.sys_id
--     INNER JOIN yp.drumate d ON  s.uid=d.id 
--     INNER JOIN yp.hub h ON h.id=s.hub_id
--     -- LEFT JOIN yp.guest g on g.id =s.recipient_id
--   WHERE (s.id = _share_id  OR s.hub_id = _share_id)  AND m.status = 'active';
-- END$



DELIMITER ;




