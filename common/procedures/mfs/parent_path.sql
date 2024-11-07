DELIMITER $
DROP FUNCTION IF EXISTS `parent_path`$
CREATE FUNCTION `parent_path`(
  _id VARCHAR(16) CHARACTER SET ascii
)
RETURNS VARCHAR(1000) CHARACTER SET utf8mb4 DETERMINISTIC
BEGIN
  DECLARE _home_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _pid VARCHAR(16) CHARACTER SET ascii DEFAULT NULL;
  DECLARE _tmp_pid VARCHAR(16) CHARACTER SET ascii DEFAULT NULL;
  DECLARE _nodename VARCHAR(600) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
  DECLARE _path VARCHAR(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
  DECLARE _res VARCHAR(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
  DECLARE _r TEXT;
  DECLARE _type VARCHAR(1000) CHARACTER SET ascii;
  DECLARE _max INTEGER DEFAULT 0;
  
  SELECT '/' INTO _res;

  SELECT id FROM media WHERE parent_id='0' INTO _home_id;
  IF _home_id = _id THEN
    RETURN '';
  END IF;

  SELECT id FROM media WHERE id=_id AND parent_id = _id INTO _pid;
  IF (_pid IS NOT NULL) THEN
    RETURN '/';
  END IF;

  SELECT '/' INTO _tmp_pid;
  SELECT parent_id FROM media WHERE id=_id INTO _pid;
  SELECT user_filename, parent_id, category FROM media WHERE id=_pid 
    INTO _nodename, _tmp_pid, _type;

  IF (_tmp_pid IS NULL) THEN
    RETURN '/';
  ELSEIF _type = 'root' THEN 
    RETURN '/';
  ELSE
    SELECT _nodename INTO _res;
    
    WHILE _pid != '0' 
      AND _pid IS NOT NULL 
      AND _nodename IS NOT NULL 
      AND _tmp_pid IS NOT NULL 
      AND _max < 100 DO 
        SELECT _max + 1 INTO _max;
        SELECT parent_id FROM media WHERE id = _pid INTO _pid;
        SELECT user_filename, parent_id, category FROM media WHERE id=_pid 
          INTO _nodename, _tmp_pid, _type;
        IF _type = 'root' OR _tmp_pid='0' OR _nodename IN('', '/') THEN
          SELECT '0', NULL, NULL INTO _pid, _nodename, _tmp_pid;
        ELSE
          SELECT CONCAT(_nodename, '/', IFNULL(_res, '')) INTO _res;
        END IF;
    END WHILE;
  END IF;
  IF (_res IS NULL) THEN
    RETURN '/';
  END IF;
  SELECT REGEXP_REPLACE(_res, '^[/ ]+|\<.*\>|[/ ]+$', '') INTO _res;
  SELECT CONCAT('/', REGEXP_REPLACE(_res, '( *)(/+)( *)', '/'), '/') INTO _res;
  SELECT REGEXP_REPLACE(_res, '/+', '/') INTO _res;
  SELECT REGEXP_REPLACE(_res, '^ +| +$', '') INTO _path;
  RETURN _path;
END$
DELIMITER ;
