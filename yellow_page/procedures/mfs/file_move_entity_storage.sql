DELIMITER $

DROP PROCEDURE IF EXISTS `file_move_entity_storage`$
CREATE PROCEDURE `file_move_entity_storage`(
  IN _hub_id VARCHAR(16)
)
BEGIN
  SELECT id AS hub_id, db_name, home_dir,
    CONCAT(home_dir, '/__storage__/') AS mfs_root
  FROM entity WHERE id = _hub_id AND db_name IS NOT NULL
  LIMIT 1;
END $

DELIMITER ;
