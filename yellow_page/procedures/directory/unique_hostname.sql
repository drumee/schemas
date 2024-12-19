DELIMITER $
DROP FUNCTION IF EXISTS `unique_hostname`$
CREATE FUNCTION `unique_hostname`(
  _hostname VARCHAR(200),
  _domain_id INTEGER
) RETURNS VARCHAR(1024) DETERMINISTIC
BEGIN
  DECLARE _r VARCHAR(1024);
  DECLARE _fqdn VARCHAR(1024);
  DECLARE _domain VARCHAR(200);
  DECLARE _domain_ident VARCHAR(200);
  DECLARE _vhost VARCHAR(200);
  DECLARE _count TINYINT(8) DEFAULT 1;
  DECLARE _i TINYINT(6) DEFAULT 0;
  DECLARE _depth TINYINT(6) DEFAULT 0;
  
  SELECT main_domain() INTO _domain;
  SELECT ident FROM organisation WHERE domain_id=_domain_id INTO _domain_ident;

  IF _domain_id > 1 THEN 
    IF _domain_ident IS NOT NULL OR _domain_ident <> "" THEN
      SELECT CONCAT(_hostname, '-', _domain_ident) INTO _vhost;
    ELSE
      SELECT _hostname INTO _vhost;
    END IF;
  ELSE
    SELECT _hostname INTO _vhost;
  END IF;

  SELECT CONCAT(_vhost, '.', _domain) INTO _fqdn;

  SELECT count(*) FROM vhost WHERE fqdn = _fqdn INTO _count;
  IF _count = 0 THEN 
    RETURN _vhost;
  END IF;

  WHILE _count <> 0 DO
    IF _domain_id > 1 THEN 
      IF _domain_ident IS NOT NULL OR _domain_ident <> "" THEN
        SELECT CONCAT(_hostname, '-', _count, '-', _domain_ident) INTO _vhost;
      ELSE
        SELECT CONCAT(_hostname, '-', _count) INTO _vhost;
      END IF;
    ELSE
      SELECT CONCAT(_hostname, '-', _count) INTO _vhost;
    END IF;
    SELECT CONCAT(_vhost, '.', _domain) INTO _fqdn;
    SELECT count(*) FROM vhost WHERE fqdn = _fqdn INTO _count;

  END WHILE;

  RETURN _vhost;
END$
DELIMITER ;
