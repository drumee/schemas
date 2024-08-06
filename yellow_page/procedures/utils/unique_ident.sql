DELIMITER $
DROP FUNCTION IF EXISTS `unique_ident`$
CREATE FUNCTION `unique_ident`(
  _ident VARCHAR(200)
) RETURNS VARCHAR(1024) DETERMINISTIC
BEGIN
  DECLARE _r VARCHAR(1024);
  DECLARE _count TINYINT(8) DEFAULT 1;
  DECLARE _i TINYINT(6) DEFAULT 0;
  DECLARE _depth TINYINT(6) DEFAULT 0;
  
  SELECT _ident INTO _r;

  SELECT count(*) FROM entity WHERE ident = _r INTO _count;
  SELECT count(*) + _count FROM organisation WHERE ident = _r INTO _count;
 
  IF _ident regexp '[\_\-]\([0-9]+\)$' THEN 
    SELECT SUBSTRING_INDEX(_ident, '-', -1) INTO _depth;
    SELECT SUBSTRING_INDEX(_ident, '-', 1) INTO @base;
    WHILE _depth  < 1000 AND _count <> 0 DO 
      SELECT _depth + 1 INTO _depth;
      SELECT CONCAT(@base, "-", _depth) INTO _r;
      SELECT count(*) FROM hub WHERE hubname = _r INTO _count;
       SELECT count(*) + _count FROM organisation WHERE ident = _r INTO _count;
    END WHILE;
  ELSE 
    WHILE _count <> 0 DO
      SELECT count(*) FROM hub WHERE hubname = _r INTO _count;
      SELECT count(*) + _count FROM organisation WHERE ident = _r INTO _count;
      IF _count >0 THEN 
        SELECT _i + 1 INTO _i;
        SELECT CONCAT(_ident, _i) INTO _r;
      END IF;
    END WHILE;
  END IF;
  RETURN _r;
END$

DELIMITER ;
