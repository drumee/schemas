DELIMITER $

DROP PROCEDURE IF EXISTS `member_list_workspaces`$
CREATE PROCEDURE `member_list_workspaces`(
  IN _uid VARCHAR(16),
  IN _org_id VARCHAR(16)
)
BEGIN
  DECLARE _dom_id INT;
  DECLARE _db_name VARCHAR(255) CHARACTER SET ascii;

  SELECT domain_id FROM organisation WHERE id = _org_id INTO _dom_id;
  SELECT db_name FROM entity WHERE id = _uid INTO _db_name;

  IF _db_name IS NULL THEN
    SELECT NULL AS hub_id, NULL AS hub_name LIMIT 0;
  ELSE
    SET @sql = CONCAT(
      'SELECT h.id AS hub_id, h.name AS hub_name ',
      'FROM `', _db_name, '`.permission p ',
      'INNER JOIN yp.hub h ON h.id = p.resource_id ',
      'INNER JOIN yp.entity e ON e.id = p.resource_id ',
      'WHERE p.entity_id = ', QUOTE(_uid),
      ' AND (p.expiry_time = 0 OR p.expiry_time > UNIX_TIMESTAMP()) ',
      ' AND h.domain_id = ', _dom_id,
      ' AND e.status = ''active'' ',
      ' ORDER BY h.name ASC'
    );
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;
END $

DELIMITER ;