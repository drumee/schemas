DELIMITER $

DROP PROCEDURE IF EXISTS `mfs_delete_node`$
CREATE PROCEDURE `mfs_delete_node`(
  IN _id VARCHAR(16)
)
BEGIN
  DECLARE _node_path VARCHAR(255);
  DECLARE _category VARCHAR(40);
  
  SELECT category from media WHERE id=_id into _category;
  
  IF _category='folder' THEN
    SELECT CONCAT(parent_path(id),user_filename) from media WHERE id=_id into _node_path;
    DELETE FROM media  WHERE CONCAT(parent_path(id),user_filename ) LIKE concat(_node_path, '/%');
  END IF;
  DELETE FROM media WHERE id=_id;

END $


DELIMITER ;
