DELIMITER $

DROP PROCEDURE IF EXISTS `mfs_cleanup_autorized_node`$
CREATE PROCEDURE `mfs_cleanup_autorized_node`(
)
BEGIN
  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
  BEGIN
    GET DIAGNOSTICS CONDITION 1 
      @sqlstate = RETURNED_SQLSTATE, 
      @errno = MYSQL_ERRNO, 
      @message = MESSAGE_TEXT;
  END;
  DELETE FROM mfs_authorized_node WHERE expiry< unix_timestamp();
END$

DELIMITER ;