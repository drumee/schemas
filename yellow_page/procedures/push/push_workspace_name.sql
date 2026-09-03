DELIMITER $

-- =========================================================
-- push_workspace_name
--
-- Workspace name for a hub-scoped mobile push, for use in the notification
-- body. Reads `hub.name` — the name members set and see, and the one the hub's
-- hostname is derived from. `entity.headline` is a separate optional title
-- that is normally unset, so it is deliberately not consulted here. A hub that
-- cannot be found returns an empty string and the caller phrases the
-- notification without a workspace.
-- =========================================================
DROP PROCEDURE IF EXISTS `push_workspace_name`$
CREATE PROCEDURE `push_workspace_name`(
  IN _hub_id VARCHAR(16)
)
BEGIN
  SELECT IFNULL(TRIM(name), '') AS workspace_name
  FROM hub
  WHERE id = _hub_id
  LIMIT 1;
END$

DELIMITER ;
