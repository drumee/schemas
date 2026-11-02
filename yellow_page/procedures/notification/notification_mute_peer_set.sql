DELIMITER $

-- =========================================================
-- notification_mute_peer_set
-- Mute the DM popups from one person. Idempotent (first ctime kept).
-- Returns the caller's person-mute rows.
-- =========================================================
DROP PROCEDURE IF EXISTS `notification_mute_peer_set`$
CREATE PROCEDURE `notification_mute_peer_set`(
  IN _uid VARCHAR(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
  IN _peer_id VARCHAR(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci
)
BEGIN
  IF IFNULL(_uid, '') <> '' AND IFNULL(_peer_id, '') <> '' THEN
    INSERT INTO notification_mute_peer (uid, peer_id, ctime)
      VALUES (_uid, _peer_id, UNIX_TIMESTAMP())
      ON DUPLICATE KEY UPDATE ctime = ctime;
  END IF;
  SELECT peer_id, ctime FROM notification_mute_peer WHERE uid = _uid ORDER BY ctime ASC, peer_id ASC;
END$

DELIMITER ;
