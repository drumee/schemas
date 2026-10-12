DELIMITER $

DROP PROCEDURE IF EXISTS `notification_rollup_list`$
CREATE PROCEDURE `notification_rollup_list`(
  IN _user_id VARCHAR(16),
  IN _page INT
)
BEGIN
  -- The stored rollups, newest first. The caller merges these with the LIVE
  -- rollups from notification_center_next and decides read state by whether a
  -- (category, key_id) is still live -- that comparison stays in the service
  -- layer, next to the existing merge, rather than being duplicated here in
  -- SQL where it would need a second copy of every unread predicate.
  --
  -- Deleted rows are excluded here rather than filtered by the caller so that
  -- a trashed notification cannot reappear through a caller that forgets the
  -- check. The trash button is the only thing that sets the flag.
  DECLARE _offset BIGINT;
  DECLARE _range BIGINT;

  CALL pageToLimits(_page, _offset, _range);

  -- hub_label is the viewer's CURRENT label for the workspace (the hub node on
  -- this desk). The payload is a snapshot, so a workspace-root row keeps the
  -- name it had when captured; the caller uses this to name the workspace the
  -- way the desk does now.
  SELECT
    r.category,
    r.key_id,
    r.hub_id,
    r.payload,
    r.last_id,
    r.ctime,
    r.mtime,
    NULLIF(wm.user_filename, '') hub_label
  FROM notification_rollup r
  LEFT JOIN media wm ON wm.id = r.hub_id AND wm.category = 'hub'
  WHERE r.user_id = _user_id
    AND r.deleted = 0
  ORDER BY r.ctime DESC, r.key_id DESC
  LIMIT _offset, _range;
END$

DELIMITER ;
