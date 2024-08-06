
DELIMITER $


-- =========================================================
-- update_unified_room
-- =========================================================
DROP PROCEDURE IF EXISTS `remove_unified_room`$
CREATE PROCEDURE `remove_unified_room`(
  IN _id VARCHAR(64)
)
BEGIN

    SELECT 
    u.id, u.uid, is_mic_enabled, is_video_enabled, is_share_enabled, is_write_enabled, metadata,
    coalesce(guest_name, firstname) username FROM unified_room u 
      INNER JOIN socket s ON u.uid=s.id 
      INNER JOIN cookie c ON s.cookie=c.id
      LEFT JOIN drumate d on c.uid=d.id
    WHERE u.uid =_id AND s.state='active';
    DELETE FROM  unified_room  WHERE `uid`  =_id;
 
END$


DELIMITER ;