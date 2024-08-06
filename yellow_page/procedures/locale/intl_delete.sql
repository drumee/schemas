DELIMITER $
DROP PROCEDURE IF EXISTS `intl_delete_next`$
CREATE PROCEDURE `intl_delete_next`(
  IN _key VARCHAR(128),
  IN _cat VARCHAR(128)
)
BEGIN
  DELETE FROM languages WHERE key_code=_key AND category=_cat;
END $
DELIMITER ;
