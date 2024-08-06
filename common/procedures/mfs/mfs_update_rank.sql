DELIMITER $

-- =======================================================================
-- mfs_update_rank
-- =======================================================================
DROP PROCEDURE IF EXISTS `mfs_update_rank`$
CREATE PROCEDURE `mfs_update_rank`(
  IN _node_id VARBINARY(16),
  IN _rank TINYINT(4)
)
BEGIN
  UPDATE media SET rank=_rank WHERE id=_node_id;
END $

DELIMITER ;