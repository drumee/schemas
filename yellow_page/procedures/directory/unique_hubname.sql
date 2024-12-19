DELIMITER $
DROP FUNCTION IF EXISTS `unique_hubname`$
CREATE FUNCTION `unique_hubname`(
  _name VARCHAR(200),
  _domain_id INTEGER
) RETURNS VARCHAR(1024) DETERMINISTIC
BEGIN
  DECLARE _r VARCHAR(1024);
  DECLARE _count TINYINT(8) DEFAULT 1;
  DECLARE _i TINYINT(6) DEFAULT 0;
  DECLARE _depth TINYINT(6) DEFAULT 0;
  
  SELECT _name INTO _r;

  SELECT count(*) FROM hub WHERE hubname = _r AND domain_id = _domain_id INTO _count;
 
  IF _name regexp '[\_\-]\([0-9]+\)$' THEN 
    SELECT SUBSTRING_INDEX(_name, '-', -1) INTO _depth;
    SELECT SUBSTRING_INDEX(_name, '-', 1) INTO @base;
    WHILE _depth  < 1000 AND _count <> 0 DO 
      SELECT _depth + 1 INTO _depth;
      SELECT CONCAT(@base, "-", _depth) INTO _r;
      SELECT count(*) FROM hub WHERE hubname = _r AND domain_id = _domain_id INTO _count;
    END WHILE;
  ELSE 
    WHILE _count <> 0 DO
      SELECT count(*) FROM hub WHERE hubname = _r AND domain_id = _domain_id INTO _count;
      IF _count >0 THEN 
        SELECT _i + 1 INTO _i;
        SELECT CONCAT(_name, _i) INTO _r;
      END IF;
    END WHILE;
  END IF;
  IF _r IS NULL THEN 
    SELECT uniqueId() INTO _r;
  END IF;
  RETURN _r;
END$
DELIMITER ;
