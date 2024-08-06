
DELIMITER $


-- =========================================================
-- new_unified_room
-- =========================================================
DROP PROCEDURE IF EXISTS `add_unified_room`$
CREATE PROCEDURE `add_unified_room`(
  IN _id VARCHAR(16) CHARACTER SET ascii,
  IN _uid VARCHAR(30) CHARACTER SET ascii,
  IN _is_mic_enabled TINYINT ,
  IN _is_video_enabled TINYINT ,
  IN _is_share_enabled TINYINT ,
  IN _is_write_enabled TINYINT ,
  IN _metadata JSON 
)
BEGIN
   
    REPLACE INTO unified_room
    (id, uid, is_mic_enabled, is_video_enabled, is_share_enabled, is_write_enabled, metadata)
    SELECT 
    _id ,_uid, _is_mic_enabled, _is_video_enabled, _is_share_enabled, _is_write_enabled, _metadata;
    -- SELECT 
    -- id, uid, is_mic_enabled, is_video_enabled, is_share_enabled, is_write_enabled, metadata 
    -- FROM unified_room WHERE id  =_id;
    SELECT 
    u.id, u.uid, is_mic_enabled, is_video_enabled, is_share_enabled, is_write_enabled, metadata,
    coalesce(guest_name, firstname) username FROM unified_room u 
      INNER JOIN socket s ON u.uid=s.id 
      INNER JOIN cookie c ON s.cookie=c.id
      LEFT JOIN drumate d on c.uid=d.id
    WHERE u.id =_id AND s.state='active';

END$

DELIMITER ;