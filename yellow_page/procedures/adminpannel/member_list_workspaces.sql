DELIMITER $

DROP PROCEDURE IF EXISTS `member_list_workspaces`$
CREATE PROCEDURE `member_list_workspaces`(
  IN _uid VARCHAR(16),
  IN _dom_id INT
)
BEGIN
  DECLARE _db_name VARCHAR(255) CHARACTER SET ascii;

  SELECT db_name FROM entity WHERE id = _uid INTO _db_name;

  IF _db_name IS NULL THEN
    SELECT NULL AS hub_id, NULL AS hub_name, NULL AS permission LIMIT 0;
  ELSE
    SET @sql = CONCAT(
      'SELECT e.id AS hub_id, e.ident AS hub_name, p.permission ',
      'FROM `', _db_name, '`.permission p ',
      'INNER JOIN yp.entity e ON e.id = p.resource_id ',
      'WHERE p.entity_id = ', QUOTE(_uid),
      ' AND p.resource_id != \'*\' ',
      ' AND (p.expiry_time = 0 OR p.expiry_time > UNIX_TIMESTAMP()) ',
      ' AND e.type = \'hub\' ',
      ' AND e.dom_id = ', _dom_id,
      ' AND e.status = \'active\' ',
      ' ORDER BY e.ident ASC'
    );
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;
END$

DELIMITER ;