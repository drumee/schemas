DELIMITER $
DROP PROCEDURE IF EXISTS `pending_invitation_get_by_email`$
CREATE PROCEDURE `pending_invitation_get_by_email`(
  IN _email VARCHAR(512)
)
BEGIN
  -- Signup grants from these rows: a lapsed workspace invitation must not.
  CALL hub_invite_expire_sweep();
  SELECT hub_id, email, permission, expiry_time
  FROM pending_invitation
  WHERE email = _email;
END$
DELIMITER ;
