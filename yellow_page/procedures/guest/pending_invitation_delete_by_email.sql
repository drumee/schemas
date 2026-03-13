DELIMITER $
DROP PROCEDURE IF EXISTS `pending_invitation_delete_by_email`$
CREATE PROCEDURE `pending_invitation_delete_by_email`(
  IN _email VARCHAR(512)
)
BEGIN
  DELETE FROM pending_invitation WHERE email = _email;
END$
DELIMITER ;
