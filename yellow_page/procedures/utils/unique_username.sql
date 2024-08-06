DELIMITER $
DROP FUNCTION IF EXISTS `unique_username`$
CREATE FUNCTION `unique_username`(
  _username VARCHAR(200),
  _domain_name VARCHAR(500)
) RETURNS VARCHAR(1024) DETERMINISTIC
BEGIN
  DECLARE _r VARCHAR(1024);
  DECLARE _count TINYINT(8) DEFAULT 0;
  DECLARE _i TINYINT(6) DEFAULT 0;
  DECLARE _depth TINYINT(6) DEFAULT 0;
  
  SELECT _username INTO _r;
  SELECT count(*) FROM drumate u INNER JOIN(domain d) ON u.domain_id=d.id 
    WHERE username = _r AND (d.name=_domain_name OR d.id=_domain_name) INTO _count;
  IF _username regexp '[\_\-]\([0-9]+\)$' THEN 
    SELECT SUBSTRING_INDEX(_username, '-', -1) INTO _depth;
    SELECT SUBSTRING_INDEX(_username, '-', 1) INTO @base;
    WHILE _depth  < 1000 AND _count <> 0 DO 
      SELECT _depth + 1 INTO _depth;
      SELECT CONCAT(@base, "-", _depth) INTO _r;
      SELECT count(*) FROM drumate u INNER JOIN(domain d) ON u.domain_id=d.id
      WHERE username = _r AND (d.name=_domain_name OR d.id=_domain_name) INTO _count;
    END WHILE;
  ELSE 
    WHILE _count <> 0 DO
      SELECT count(*) FROM drumate u INNER JOIN(domain d) ON u.domain_id=d.id
        WHERE username = _r AND (d.name=_domain_name OR d.id=_domain_name) INTO _count;
      IF _count >0 THEN 
        SELECT _i + 1 INTO _i;
        SELECT CONCAT(_username, _i) INTO _r;
      END IF;
    END WHILE;
  END IF;
  RETURN _r;
END$

DELIMITER ;
