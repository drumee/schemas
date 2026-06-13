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
  DECLARE _permission_level   VARCHAR(20) DEFAULT 'can_view';
  DECLARE _capabilities       JSON DEFAULT NULL;
  DECLARE _recipient_email    VARCHAR(512);
  DECLARE _domain_restriction VARCHAR(255);
  DECLARE _allowed_emails     JSON DEFAULT NULL;
  DECLARE _require_email      TINYINT UNSIGNED DEFAULT 0;
  DECLARE _notify_on_open     TINYINT UNSIGNED DEFAULT 1;
  DECLARE _password_hash      VARCHAR(255);
  DECLARE _expiry_hours       INT DEFAULT 0;
  DECLARE _expiry_time        INT DEFAULT 0;

  SELECT JSON_VALUE(_args, '$.token')              INTO _token;
  SELECT JSON_VALUE(_args, '$.hub_id')             INTO _hub_id;
  SELECT JSON_VALUE(_args, '$.node_id')            INTO _node_id;
  SELECT JSON_VALUE(_args, '$.creator_id')         INTO _creator_id;
  SELECT JSON_VALUE(_args, '$.password_hash')      INTO _password_hash;
  SELECT IFNULL(JSON_VALUE(_args, '$.expiry_hours'), 0) INTO _expiry_hours;
  SELECT IFNULL(JSON_VALUE(_args, '$.require_email'), 0) INTO _require_email;
  SELECT IFNULL(JSON_VALUE(_args, '$.notify_on_open'), 1) INTO _notify_on_open;

  SELECT IFNULL(NULLIF(TRIM(JSON_VALUE(_args, '$.permission_level')), ''), 'can_view')
    INTO _permission_level;

  -- Multi-select capabilities (v2): an independent set of granted capabilities,
  -- e.g. ["can_download","can_chat","can_edit"]. When present it is the source of
  -- truth; permission_level is derived from it (highest single) only for
  -- back-compat with legacy readers. When absent (legacy single-select callers),
  -- derive the set from permission_level so the column is always populated.
  SELECT JSON_EXTRACT(_args, '$.capabilities') INTO _capabilities;

  IF _capabilities IS NOT NULL AND JSON_LENGTH(_capabilities) > 0 THEN
    IF JSON_CONTAINS(_capabilities, '"can_edit"') THEN
      SET _permission_level = 'can_edit';
    ELSEIF JSON_CONTAINS(_capabilities, '"can_chat"') THEN
      SET _permission_level = 'can_chat';
    ELSEIF JSON_CONTAINS(_capabilities, '"can_download"') THEN
      SET _permission_level = 'can_download';
    ELSE
      SET _permission_level = 'can_view';
    END IF;
  ELSE
    IF _permission_level = 'can_view' THEN
      SET _capabilities = JSON_ARRAY();
    ELSE
      SET _capabilities = JSON_ARRAY(_permission_level);
    END IF;
  END IF;

  SELECT JSON_EXTRACT(_args, '$.allowed_emails') INTO _allowed_emails;

  IF _allowed_emails IS NULL OR JSON_LENGTH(_allowed_emails) = 0 THEN
    SELECT JSON_VALUE(_args, '$.recipient_email')    INTO _recipient_email;
    SELECT JSON_VALUE(_args, '$.domain_restriction') INTO _domain_restriction;

    IF _recipient_email IS NOT NULL AND TRIM(_recipient_email) != '' THEN
      SET _allowed_emails = JSON_ARRAY(LOWER(TRIM(_recipient_email)));
      IF _domain_restriction IS NOT NULL AND TRIM(_domain_restriction) != '' THEN
        SET _allowed_emails = JSON_ARRAY_APPEND(
          _allowed_emails, '$', CONCAT('@', LOWER(TRIM(_domain_restriction)))
        );
      END IF;
    END IF;
  END IF;

  IF _expiry_hours > 0 THEN
    SET _expiry_time = UNIX_TIMESTAMP() + (_expiry_hours * 3600);
  END IF;

  INSERT INTO `secure_share_token`
    (`id`, `hub_id`, `node_id`, `creator_id`, `permission_level`, `capabilities`,
     `recipient_email`, `domain_restriction`, `allowed_emails`, `require_email`,
     `notify_on_open`, `password_hash`, `expiry_time`, `ctime`)
  VALUES
    (_token, _hub_id, _node_id, _creator_id,
     _permission_level,
     _capabilities,
     NULLIF(LOWER(TRIM(IFNULL(JSON_VALUE(_args, '$.recipient_email'), ''))), ''),
     NULLIF(LOWER(TRIM(IFNULL(JSON_VALUE(_args, '$.domain_restriction'), ''))), ''),
     _allowed_emails,
     IF(_require_email = 1 OR (_allowed_emails IS NOT NULL AND JSON_LENGTH(_allowed_emails) > 0), 1, 0),
     IF(_notify_on_open = 0, 0, 1),
     NULLIF(TRIM(IFNULL(_password_hash, '')), ''),
     _expiry_time, UNIX_TIMESTAMP());

  SELECT
    s.sys_id,
    s.id,
    s.hub_id,
    s.node_id,
    s.creator_id,
    s.permission_level,
    s.capabilities,
    s.recipient_email,
    s.domain_restriction,
    s.allowed_emails,
    s.expiry_time,
    s.access_count,
    s.ctime
  FROM `secure_share_token` s
  WHERE s.id = _token;
END$

DELIMITER ;
