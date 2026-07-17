DELIMITER $
DROP PROCEDURE IF EXISTS `task_column_create`$
CREATE PROCEDURE `task_column_create`(
  IN _id VARCHAR(16),
  IN _nid VARCHAR(16),
  IN _name VARCHAR(100),
  IN _theme VARCHAR(20)
)
BEGIN
  DECLARE _pos INT DEFAULT 0;
  DECLARE _now INT DEFAULT UNIX_TIMESTAMP();

  -- Append to the right end of this folder's custom columns.
  SELECT IFNULL(MAX(position), 0) + 1 INTO _pos
    FROM task_column
   WHERE nid <=> _nid;

  INSERT INTO task_column (id, nid, name, theme, position, ctime, mtime)
  VALUES (_id, _nid, _name, IFNULL(_theme, 'default'), _pos, _now, _now);

  SELECT id, nid, name, theme, position, ctime, mtime
    FROM task_column
   WHERE id = _id;
END$
DELIMITER ;
