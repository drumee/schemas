DELIMITER $

DROP FUNCTION IF EXISTS `node_id_from_path`$
CREATE FUNCTION `node_id_from_path`(
  _path VARCHAR(1024)
)
RETURNS VARCHAR(16) DETERMINISTIC
BEGIN
  DECLARE _r VARCHAR(16) CHARACTER SET ascii;
  DECLARE _node_id VARCHAR(16) CHARACTER SET ascii;
  IF _path regexp  '^\/.+' THEN 
    SELECT id FROM media 
      WHERE REPLACE(file_path, '/', '') = 
      REPLACE(IF(category ='hub', CONCAT(_path, '.', extension), _path), '/','')
      INTO _node_id;
  ELSE 
    SELECT id FROM media WHERE file_path = '/' INTO _node_id;
  END IF;
  SELECT id FROM media WHERE id = _node_id INTO _r;
  RETURN _r;
END$


DELIMITER ;
