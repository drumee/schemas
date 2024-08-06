
DELIMITER $



-- =========================================================
-- update_unified_room
-- =========================================================
DROP PROCEDURE IF EXISTS `update_unified_room`$
CREATE PROCEDURE `update_unified_room`(
  IN _id VARCHAR(16) CHARACTER SET ascii,
  IN _uid VARCHAR(30) CHARACTER SET ascii,
  IN _is_mic_enabled TINYINT ,
  IN _is_video_enabled TINYINT  ,
  IN _is_share_enabled TINYINT  ,
  IN _is_write_enabled TINYINT,
  IN _metadata json 
)
BEGIN
   
    UPDATE unified_room SET  
      is_mic_enabled =_is_mic_enabled,
      is_video_enabled =_is_video_enabled,
      is_share_enabled =_is_share_enabled,
      is_write_enabled =_is_write_enabled
    WHERE id  =_id AND uid =_uid;
    SELECT u.id, metadata, coalesce(guest_name, firstname) username FROM unified_room u 
      INNER JOIN socket s ON u.uid=s.id 
      INNER JOIN cookie c ON s.cookie=c.id
      LEFT JOIN drumate d on c.uid=d.id
    WHERE u.id =_id AND s.state='active'; 
    -- FROM unified_room WHERE id = _id;

END$


DELIMITER ;