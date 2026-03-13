DELIMITER $
DROP PROCEDURE IF EXISTS `share_guest_list_by_hub`$
CREATE PROCEDURE `share_guest_list_by_hub`(
  IN _hub_id VARCHAR(16)
)
BEGIN
  SELECT hub_id, email, permission, expiry_time
  FROM share_guest
  WHERE hub_id = _hub_id
  ORDER BY email;
END$
DELIMITER ;
