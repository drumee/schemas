DELIMITER $

DROP FUNCTION IF EXISTS `ensure_vhsot`$
DROP FUNCTION IF EXISTS `ensure_vhost`$
CREATE FUNCTION `ensure_vhost`(
  _args JSON
)
RETURNS VARCHAR(128) DETERMINISTIC
BEGIN
  DECLARE _domain_id INTEGER;
  DECLARE _domain VARCHAR(512);
  DECLARE _hostname VARCHAR(128);
  DECLARE _res VARCHAR(128);
  DECLARE _count INTEGER DEFAULT 0;
  DECLARE _i INTEGER DEFAULT 1;

  SELECT JSON_VALUE(_args, "$.domain") INTO _domain;
  SELECT JSON_VALUE(_args, "$.hostname") INTO _hostname;

  SELECT id FROM domain WHERE name=_domain INTO _domain_id;

  IF _domain_id IS NULL OR _domain IS NULL THEN 
    SELECT get_sysconf('domain_name' ) INTO _domain;
    SELECT 1 INTO _domain_id;
  END IF;
  
  IF _domain_id > 1 THEN 
    SELECT CONCAT(_hostname, '-', _domain) INTO _res;
  ELSE
    SELECT CONCAT(_hostname, '.', _domain) INTO _res;
  END IF;

  SELECT count(*) FROM vhost WHERE fqdn=_res INTO _count;
  WHILE _count > 0 DO
    IF _domain_id > 1 THEN 
      SELECT CONCAT(_hostname, _i, '-', _domain) INTO _res;
    ELSE
      SELECT CONCAT(_hostname, _i, '.', _domain) INTO _res;
    END IF;
    SELECT _i + 1 INTO _i;
    SELECT count(*) FROM vhost WHERE fqdn=_res INTO _count;
  END WHILE;
  RETURN _res;
END$
DELIMITER ;
