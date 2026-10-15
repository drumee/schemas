DELIMITER $

-- =========================================================
-- notification_mute_peer_state
-- The caller's person-mute rows.
-- =========================================================
DROP PROCEDURE IF EXISTS `notification_mute_peer_state`$
CREATE PROCEDURE `notification_mute_peer_state`(
  IN _uid VARCHAR(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci
)
BEGIN
  SELECT peer_id, ctime FROM notification_mute_peer WHERE uid = _uid ORDER BY ctime ASC, peer_id ASC;
END$

DELIMITER ;
