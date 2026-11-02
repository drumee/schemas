DELIMITER $

-- =========================================================
-- notification_muted_uids
-- Which of _uids have muted a chat push, for the mobile push worker
-- (offline/workers/mobilePushWorker.js, admission only -- never the
-- request path). Same rule as the client's isPopupMuted:
--   a global mute (hub_id = '')          mutes everything;
--   a workspace push (_hub_id <> '')     follows that workspace's mute;
--   a direct message (_hub_id = '')      follows the author's person mute.
-- _uids is a JSON array of drumate ids. JSON_CONTAINS, not JSON_TABLE,
-- so no column collation enters the comparison.
-- =========================================================
DROP PROCEDURE IF EXISTS `notification_muted_uids`$
CREATE PROCEDURE `notification_muted_uids`(
  IN _uids JSON,
  IN _hub_id VARCHAR(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
  IN _author_id VARCHAR(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci
)
BEGIN
  SET _hub_id = IFNULL(_hub_id, '');
  SET _author_id = IFNULL(_author_id, '');

  SELECT m.uid
    FROM notification_mute m
    WHERE JSON_CONTAINS(_uids, JSON_QUOTE(m.uid))
      AND (m.hub_id = '' OR (_hub_id <> '' AND m.hub_id = _hub_id))
  UNION
  SELECT p.uid
    FROM notification_mute_peer p
    WHERE _hub_id = ''
      AND _author_id <> ''
      AND p.peer_id = _author_id
      AND JSON_CONTAINS(_uids, JSON_QUOTE(p.uid));
END $

DELIMITER ;
