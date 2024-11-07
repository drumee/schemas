DELIMITER $
DROP FUNCTION IF EXISTS `parent_path`$
CREATE FUNCTION `parent_path`(
  _id VARCHAR(16) CHARACTER SET ascii
)
RETURNS TEXT DETERMINISTIC
BEGIN
  DECLARE _home_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _pid VARCHAR(16) CHARACTER SET ascii DEFAULT NULL;
  DECLARE _nodename VARCHAR(600) ;
  DECLARE _path VARCHAR(1000) CHARACTER SET utf8mb4;
  DECLARE _r TEXT;
  DECLARE _type VARCHAR(1000);
  DECLARE _max INTEGER DEFAULT 0;
  SET @res = '/';

  SELECT id FROM media WHERE parent_id='0' INTO _home_id;
  IF _home_id = _id THEN
    RETURN '';
  END IF;

  SELECT id FROM media WHERE id=_id AND parent_id = _id INTO _pid;
  IF (_pid IS NOT NULL) THEN
    RETURN '/';
  END IF;

  SET @pid = NULL;
  SELECT parent_id FROM media WHERE id=_id INTO _pid;
  SELECT user_filename, parent_id, category FROM media WHERE id=_pid 
    INTO _nodename, @pid, _type;

  IF (@pid IS NULL) THEN
    RETURN '/';
  ELSEIF _type = 'root' THEN 
    RETURN '/';
  ELSE
    SELECT _nodename INTO @res;
    
    WHILE _pid != '0' 
      AND _pid IS NOT NULL 
      AND _nodename IS NOT NULL 
      AND @pid IS NOT NULL 
      AND _max < 100 DO 
        SELECT _max + 1 INTO _max;
        SELECT parent_id FROM media WHERE id = _pid INTO _pid;
        SELECT user_filename, parent_id, category FROM media WHERE id=_pid 
          INTO _nodename, @pid, _type;
        IF _type = 'root' OR @pid='0' OR _nodename IN('', '/') THEN
          SELECT '0', NULL, NULL INTO _pid, _nodename, @pid;
        ELSE
          SELECT CONCAT(_nodename, '/', IFNULL(@res, '')) INTO @res;
        END IF;
    END WHILE;
  END IF;
  IF (@res IS NULL) THEN
    RETURN '/';
  END IF;
  SELECT REGEXP_REPLACE(@res, '^[/ ]+|\<.*\>|[/ ]+$', '') INTO @res;
  SELECT CONCAT('/', REGEXP_REPLACE(@res, '( *)(/+)( *)', '/'), '/') INTO @res;
  SELECT REGEXP_REPLACE(@res, '/+', '/') INTO @res;
  SELECT REGEXP_REPLACE(@res, '^ +| +$', '') INTO _path;
  RETURN _path;
END$
DELIMITER ;
