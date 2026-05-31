DELIMITER $

DROP PROCEDURE IF EXISTS `secure_share_create`$
CREATE PROCEDURE `secure_share_create`(
  IN _args JSON
)
BEGIN
  DECLARE _token              VARCHAR(80);
  DECLARE _hub_id             VARCHAR(16) CHARACTER SET ascii;
  DECLARE _node_id            VARCHAR(16) CHARACTER SET ascii;
  DECLARE _creator_id         VARCHAR(16) CHARACTER SET ascii;
  DECLARE _recipient_email    VARCHAR(512);
  DECLARE _domain_restriction VARCHAR(255);
  DECLARE _password_hash      VARCHAR(255);
  DECLARE _expiry_hours       INT DEFAULT 0;
  DECLARE _expiry_time        INT DEFAULT 0;

  SELECT JSON_VALUE(_args, '$.token')              INTO _token;
  SELECT JSON_VALUE(_args, '$.hub_id')             INTO _hub_id;
  SELECT JSON_VALUE(_args, '$.node_id')            INTO _node_id;
  SELECT JSON_VALUE(_args, '$.creator_id')         INTO _creator_id;
  SELECT JSON_VALUE(_args, '$.recipient_email')    INTO _recipient_email;
  SELECT JSON_VALUE(_args, '$.domain_restriction') INTO _domain_restriction;
  SELECT JSON_VALUE(_args, '$.password_hash')      INTO _password_hash;
  SELECT IFNULL(JSON_VALUE(_args, '$.expiry_hours'), 0) INTO _expiry_hours;

  IF _expiry_hours > 0 THEN
    SET _expiry_time = UNIX_TIMESTAMP() + (_expiry_hours * 3600);
  END IF;

  INSERT INTO `secure_share_token`
    (`id`, `hub_id`, `node_id`, `creator_id`, `recipient_email`,
     `domain_restriction`, `password_hash`, `expiry_time`, `ctime`)
  VALUES
    (_token, _hub_id, _node_id, _creator_id,
     LOWER(TRIM(_recipient_email)),
     NULLIF(LOWER(TRIM(IFNULL(_domain_restriction, ''))), ''),
     NULLIF(TRIM(IFNULL(_password_hash, '')), ''),
     _expiry_time, UNIX_TIMESTAMP());

  SELECT
    s.sys_id,
    s.id,
    s.hub_id,
    s.node_id,
    s.creator_id,
    s.recipient_email,
    s.domain_restriction,
    s.expiry_time,
    s.access_count,
    s.ctime
  FROM `secure_share_token` s
  WHERE s.id = _token;
END$

DELIMITER ;
