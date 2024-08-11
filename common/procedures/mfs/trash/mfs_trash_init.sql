DELIMITER $

-- =========================================================
-- PRE PROCEDURE TO TRASHING A NODE 
-- =========================================================
DROP PROCEDURE IF EXISTS `mfs_trash_init`$
CREATE PROCEDURE `mfs_trash_init`(
)
BEGIN
  DECLARE _file_path VARCHAR(400) DEFAULT NULL;
  DECLARE _home_id VARCHAR(400) DEFAULT NULL;
  SELECT id FROM media WHERE parent_id='0' INTO _home_id;
  UPDATE media SET file_path='/', category='root' WHERE id=_home_id;
  
  SELECT file_path from media WHERE file_path='/__trash__' INTO _file_path;
  IF _file_path IS NULL THEN 
    CALL mfs_make_dir(_home_id, JSON_ARRAY('__trash__'), 1);
    UPDATE media SET status='hidden' WHERE file_path='/__trash__';
  END IF;
  
END$

DELIMITER ;
