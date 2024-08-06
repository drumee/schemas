DELIMITER $
DROP FUNCTION IF EXISTS `filepath`$
CREATE FUNCTION `filepath`(
  _id VARCHAR(1024)
)
RETURNS VARCHAR(1500) DETERMINISTIC
BEGIN
  DECLARE _r TEXT;

  SELECT CONCAT(
    parent_path(id), 
    REGEXP_REPLACE(user_filename, '^ +| +$|/+', ''),
    IF(extension REGEXP "^ *$" OR category IN('root', 'folder', 'hub') , 
    '', CONCAT('.', extension))
  ) FROM media WHERE id=_id INTO _r;
  SELECT REGEXP_REPLACE(_r, '^ +| $', '') INTO _r;
  SELECT REGEXP_REPLACE(_r, '/+', '/') INTO _r;
  SELECT REGEXP_REPLACE(_r, '\\\.+', '.') INTO _r;
  SELECT REGEXP_REPLACE(_r, '\<.*\>', '') INTO _r;
  RETURN _r;
END$
DELIMITER ;
