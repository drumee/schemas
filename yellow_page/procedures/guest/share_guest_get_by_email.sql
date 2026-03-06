DELIMITER $
DROP PROCEDURE IF EXISTS `share_guest_get_by_email`$
CREATE PROCEDURE `share_guest_get_by_email`(
  IN _email VARCHAR(512)
)
BEGIN
  SELECT hub_id, email, permission, expiry_time
  FROM share_guest
  WHERE email = _email;
END$
DELIMITER ;