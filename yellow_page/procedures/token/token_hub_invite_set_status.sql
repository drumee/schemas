DELIMITER $
DROP PROCEDURE IF EXISTS `token_hub_invite_set_status`$
CREATE PROCEDURE `token_hub_invite_set_status`(
  IN _secret   VARCHAR(255),
  IN _status   VARCHAR(20),
  IN _metadata JSON
)
BEGIN
  UPDATE token
    SET `status` = _status,
        metadata = COALESCE(NULLIF(_metadata, ''), metadata)
    WHERE `secret` = _secret;
  SELECT ROW_COUNT() AS updated;
END$
DELIMITER ;
