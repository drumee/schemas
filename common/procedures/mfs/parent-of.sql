DELIMITER $
DROP FUNCTION IF EXISTS `is_parent_of`$
CREATE FUNCTION `is_parent_of`(
  _parent_id VARCHAR(16),
  _node_id VARCHAR(16)
)
RETURNS TINYINT(2) DETERMINISTIC
BEGIN

  DECLARE _pid VARCHAR(16);
  DECLARE _res VARCHAR(16);
  DECLARE _depth SMALLINT DEFAULT 0;

  IF _node_id IS NULL OR _parent_id IS NULL THEN 
    RETURN 0;
  END IF;

  IF _node_id NOT IN ('', 0, '0', "*") AND _parent_id = _node_id THEN
    RETURN 1;
  END IF; 
  SELECT IF(parent_id=_parent_id, 1, 0), parent_id 
    FROM media WHERE id=_node_id INTO _res, _pid;
  WHILE _depth  < 120 AND _pid != '0' AND _res = 0 DO
    SELECT IF(parent_id=_parent_id, 1, 0), parent_id 
      FROM media WHERE id=_pid INTO _res, _pid;
    SELECT _depth + 1 INTO _depth;
  END WHILE;
  RETURN _res;
END $


DELIMITER ;
