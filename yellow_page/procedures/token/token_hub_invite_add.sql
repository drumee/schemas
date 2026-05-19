DELIMITER $
DROP PROCEDURE IF EXISTS `token_hub_invite_add`$
CREATE PROCEDURE `token_hub_invite_add`(
  IN _email      VARCHAR(512),
  IN _name       VARCHAR(512),
  IN _secret     VARCHAR(255),
  IN _method     VARCHAR(80),
  IN _inviter_id VARCHAR(16),
  IN _metadata   JSON,
  IN _expiry     INT(11) UNSIGNED
)
BEGIN
  -- Dọn token mời hub đã quá hạn trước khi thêm mới.
  DELETE FROM token
    WHERE method LIKE 'hub_invite:%' AND expiry > 0 AND UNIX_TIMESTAMP() > expiry;
  -- REPLACE: mời lại cùng (email, method, inviter_id) -> cấp token mới (resend).
  REPLACE INTO token (email, `name`, `secret`, method, inviter_id, `status`, ctime, expiry, metadata)
    VALUES (_email, _name, _secret, _method, _inviter_id, 'active', UNIX_TIMESTAMP(), _expiry, _metadata);
  SELECT email, `name`, `secret`, method, inviter_id, `status`, ctime, expiry, metadata
    FROM token WHERE `secret` = _secret;
END$
DELIMITER ;
