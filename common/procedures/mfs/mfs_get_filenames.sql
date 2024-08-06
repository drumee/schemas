DELIMITER $

DROP PROCEDURE IF EXISTS `mfs_get_filenames`$
CREATE PROCEDURE `mfs_get_filenames`(
  IN _pid VARCHAR(16)CHARACTER SET ascii
)
BEGIN
  select id, user_filename `filename` FROM media WHERE parent_id=_pid;
END $



DELIMITER ;