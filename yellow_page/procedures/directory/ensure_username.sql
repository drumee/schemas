DELIMITER $

DROP FUNCTION IF EXISTS `ensure_username`$
CREATE FUNCTION `ensure_username`(
  _args JSON
)
RETURNS VARCHAR(128) DETERMINISTIC
BEGIN
  DECLARE _domain_id INTEGER;
  DECLARE _domain VARCHAR(512);
  DECLARE _username VARCHAR(128);
  DECLARE _res VARCHAR(128);
  DECLARE _count INTEGER DEFAULT 0;
  DECLARE _i INTEGER DEFAULT 1;

  SELECT JSON_VALUE(_args, "$.domain") INTO _domain;
  SELECT JSON_VALUE(_args, "$.domain_id") INTO _domain_id;
  SELECT JSON_VALUE(_args, "$.username") INTO _username;
  SELECT strip_accents(_username) INTO  _username;

  IF _domain_id IS NULL THEN 
    IF _domain IS NULL THEN 
      SELECT get_sysconf('domain_name' ) INTO _domain;
    END IF;
    SELECT id FROM domain WHERE `name`= _domain INTO _domain_id;
    IF _domain_id IS NULL THEN
      SELECT 1 INTO _domain_id;
    END IF;
  END IF;

  SELECT _username INTO _res;

  SELECT count(*) FROM drumate WHERE username=_username AND domain_id=_domain_id INTO _count;
  WHILE _count <> 0 DO
    SELECT CONCAT(_username, _i) INTO _res;
    SELECT count(*) FROM drumate WHERE username=_res AND domain_id=_domain_id INTO _count;
    SELECT _i + 1 INTO _i;
  END WHILE;
  RETURN _res;
END$
DELIMITER ;
