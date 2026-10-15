DELIMITER $

-- =========================================================
-- notification_mute_peer_unset
-- Unmute one person, or every person when _peer_id is ''.
-- Returns the caller's remaining person-mute rows.
-- =========================================================
DROP PROCEDURE IF EXISTS `notification_mute_peer_unset`$
CREATE PROCEDURE `notification_mute_peer_unset`(
  IN _uid VARCHAR(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
  IN _peer_id VARCHAR(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci
)
BEGIN
  SET _peer_id = IFNULL(_peer_id, '');
  IF IFNULL(_uid, '') <> '' THEN
    DELETE FROM notification_mute_peer WHERE uid = _uid AND (_peer_id = '' OR peer_id = _peer_id);
  END IF;
  SELECT peer_id, ctime FROM notification_mute_peer WHERE uid = _uid ORDER BY ctime ASC, peer_id ASC;
END$

DELIMITER ;
