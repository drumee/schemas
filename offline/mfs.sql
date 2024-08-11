-- =========================================================
-- PRE PROCEDURE TO TRASHING A NODE 
-- =========================================================
DROP PROCEDURE IF EXISTS `setup_mfs`$
CREATE PROCEDURE `setup_mfs`(
)
BEGIN
  CALL mfs_make_dir("0", JSON_ARRAY('__trash__'), 1);
  UPDATE media SET status='hidden' WHERE file_path='/__trash__.folder';
  SELECT IFNULL(id, '0') from media where parent_id='0' INTO @_home_id;
  UPDATE yp.entity SET home_layout=@_home_id WHERE db_name=database();  

END$
