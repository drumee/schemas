DELIMITER $

DROP PROCEDURE IF EXISTS `file_move_destination_snapshot`$
CREATE PROCEDURE `file_move_destination_snapshot`(
  IN _actor_id VARCHAR(16),
  IN _parent_nid VARCHAR(16)
)
BEGIN
  SELECT
    m.id AS parent_nid,
    m.category,
    m.status AS media_status,
    user_permission(_actor_id, m.id) AS permission,
    e.id AS hub_id,
    e.db_name,
    CONCAT(e.home_dir, '/__storage__/') AS mfs_root
  FROM media m
  INNER JOIN yp.entity e ON e.db_name = DATABASE()
  WHERE m.id = _parent_nid
    AND m.category IN ('folder','root','hub')
    AND m.status NOT IN ('hidden','deleted')
  LIMIT 1;
END $

DELIMITER ;
