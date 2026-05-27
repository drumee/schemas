DELIMITER $

DROP PROCEDURE IF EXISTS `secure_share_info`$
CREATE PROCEDURE `secure_share_info`(
  IN _token VARCHAR(80)
)
BEGIN
  DECLARE _hub_id            VARCHAR(16) CHARACTER SET ascii;
  DECLARE _node_id           VARCHAR(16) CHARACTER SET ascii;
  DECLARE _creator_id        VARCHAR(16) CHARACTER SET ascii;
  DECLARE _revoked_at        INT(11)     DEFAULT NULL;
  DECLARE _expiry_time       INT         DEFAULT 0;
  DECLARE _db_name           VARCHAR(50);
  DECLARE _fullname          VARCHAR(150);
  DECLARE _hub_name          VARCHAR(150);

  SELECT
    s.hub_id,
    s.node_id,
    s.creator_id,
    s.revoked_at,
    s.expiry_time
  INTO
    _hub_id, _node_id, _creator_id, _revoked_at, _expiry_time
  FROM `secure_share_token` s
  WHERE s.id = _token
  LIMIT 1;

  IF _hub_id IS NULL THEN
    SELECT 1 AS failed, 'TICKET_INVALID' AS validity;
  ELSE
    SELECT db_name FROM entity WHERE id = _hub_id INTO _db_name;

    SELECT CONCAT(firstname, ' ', IFNULL(lastname, ''))
    FROM   drumate
    WHERE  id = _creator_id
    INTO   _fullname;

    SELECT name FROM hub WHERE id = _hub_id INTO _hub_name;

    SELECT
      s.sys_id,
      s.id                AS token,
      s.hub_id,
      s.node_id,
      s.node_id           AS nid,
      s.creator_id,
      s.creator_id        AS sender_id,
      s.recipient_email,
      s.domain_restriction,
      s.expiry_time,
      s.access_count,
      s.last_accessed,
      s.ctime,
      _db_name            AS db_name,
      _fullname           AS `name`,
      _fullname           AS `sender`,
      _hub_name           AS title,
      0                   AS require_password,
      0                   AS is_public,
      1                   AS is_secure,
      CASE
        WHEN _revoked_at IS NOT NULL                            THEN 'TICKET_REVOKED'
        WHEN _expiry_time > 0 AND UNIX_TIMESTAMP() > _expiry_time THEN 'TICKET_EXPIRED'
        ELSE 'TICKET_OK'
      END                 AS validity
    FROM `secure_share_token` s
    WHERE s.id = _token;
  END IF;
END$

DELIMITER ;
