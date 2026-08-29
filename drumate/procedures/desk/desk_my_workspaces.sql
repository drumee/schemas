DELIMITER $

DROP PROCEDURE IF EXISTS `desk_my_workspaces`$
CREATE PROCEDURE `desk_my_workspaces`()
BEGIN
  -- Every workspace this desk belongs to -- owned AND joined -- as
  -- (hub_id, db_name), so a caller can fan a per-workspace query out across
  -- them. Added for the once-a-day "Today you have ..." card, whose three
  -- numbers have no single-workspace source.
  --
  -- The desk's OWN media table is the right register: a hub node is written
  -- there for every workspace the user belongs to, however they joined. The
  -- obvious alternative -- yp.hub.owner_id, which desk.search uses for its
  -- cross-hub message search -- lists only workspaces the user OWNS and would
  -- silently drop every workspace they were invited to.
  --
  -- The predicate is lifted verbatim from notification_center_next's _my_hubs
  -- temporary table, which has enumerated workspaces in production for a long
  -- time: category 'hub', excluding the 'dmz' pseudo-hub. Deliberately NOT
  -- "improved" with extra status filters -- deviating from the proven set is
  -- how a workspace goes missing from a count with nothing to show for it.
  --
  -- No paging on purpose: the caller needs the whole set to sum over, and
  -- mfs_show_node_by would hand back 45 at a time (pageToLimits), turning a
  -- 46-workspace user's total into a silent undercount.
  SELECT
    he.id      AS hub_id,
    he.db_name AS db_name,
    he.area    AS area
  FROM media m
  INNER JOIN yp.entity he ON m.id = he.id
  INNER JOIN yp.hub h ON m.id = h.id
  WHERE m.category = 'hub'
    AND m.extension <> 'dmz'
  ORDER BY he.id;
END$

DELIMITER ;
