DELIMITER $
DROP PROCEDURE IF EXISTS `share_guest_delete_by_email`$
CREATE PROCEDURE `share_guest_delete_by_email`(
  IN _email VARCHAR(512)
)
BEGIN
  DELETE FROM share_guest WHERE email = _email;
END$
DELIMITER ;