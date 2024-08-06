DELIMITER $



DROP FUNCTION IF EXISTS `unique_role`$
CREATE FUNCTION `unique_role`(
  _name VARCHAR(500),
  _cnk_role_id INT(10),  
  _org_id VARCHAR(16) 
)
RETURNS VARCHAR(1024) DETERMINISTIC
BEGIN
  DECLARE _r VARCHAR(1024);
  DECLARE _count INT(8) DEFAULT 0;
  DECLARE _depth INT(4) DEFAULT 0;

  IF _cnk_role_id IN ('',  '0') THEN 
   SELECT NULL INTO  _cnk_role_id;
  END IF;

  SELECT count(*) FROM role WHERE name = _name  AND org_id= _org_id AND id <> IFNULL(_cnk_role_id,-99)
  INTO _count;
 
  IF _count = 0 THEN 
    SELECT _name INTO _r;
  ELSE 
      WHILE _depth  < 1000 AND _count > 0 DO 
            SELECT _depth + 1 INTO _depth;
            SELECT CONCAT(_name, " (", _depth, ")") INTO _r;
            SELECT count(*) FROM role WHERE name = _r AND org_id= _org_id  AND id <> IFNULL(_cnk_role_id,-99)
            INTO _count;

      END WHILE;  
  END IF;   
  RETURN _r;
END$

DELIMITER ;