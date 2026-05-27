DELIMITER $

DROP PROCEDURE IF EXISTS `secure_share_create`$
CREATE PROCEDURE `secure_share_create`(
  IN _token              VARCHAR(80),
  IN _hub_id             VARCHAR(16) CHARACTER SET ascii,
  IN _node_id            VARCHAR(16) CHARACTER SET ascii,
  IN _creator_id         VARCHAR(16) CHARACTER SET ascii,
  IN _recipient_email    VARCHAR(512),
  IN _domain_restriction VARCHAR(255),
  IN _expiry_hours       INT
)
BEGIN
  DECLARE _expiry_time INT DEFAULT 0;

  IF _expiry_hours > 0 THEN
    SET _expiry_time = UNIX_TIMESTAMP() + (_expiry_hours * 3600);
  END IF;

  INSERT INTO `secure_share_token`
    (`id`, `hub_id`, `node_id`, `creator_id`, `recipient_email`,
     `domain_restriction`, `expiry_time`, `ctime`)
  VALUES
    (_token, _hub_id, _node_id, _creator_id,
     LOWER(TRIM(_recipient_email)),
     IF(TRIM(IFNULL(_domain_restriction, '')) = '', NULL, LOWER(TRIM(_domain_restriction))),
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
