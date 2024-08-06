
DELIMITER $


-- =========================================================
-- get_unified_room
-- =========================================================
DROP PROCEDURE IF EXISTS `get_unified_room`$
CREATE PROCEDURE `get_unified_room`(
  IN _id VARCHAR(16) CHARACTER SET ascii,
  IN _uid VARCHAR(30) CHARACTER SET ascii
)
BEGIN

  IF _uid IN ('') THEN 
   SELECT NULL INTO  _uid;
  END IF;

   SELECT u.id, u.uid, is_mic_enabled, is_video_enabled, is_share_enabled, is_write_enabled, metadata,
   coalesce(guest_name, firstname) username FROM unified_room u 
      INNER JOIN socket s ON u.uid=s.id 
      INNER JOIN cookie c ON s.cookie=c.id
      LEFT JOIN drumate d on c.uid=d.id
    WHERE u.id =_id AND s.state='active' AND u.uid = IFNULL(_uid , u.uid);
  --  FROM unified_room u 
  --  INNER JOIN socket s ON u.uid=s.id WHERE u.id =_id AND s.state='active' AND u.uid = IFNULL(_uid , u.uid);
END$


DELIMITER ;