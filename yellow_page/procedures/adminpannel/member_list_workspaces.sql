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
    SELECT NULL AS hub_id, NULL AS hub_name, NULL AS area, NULL AS permission LIMIT 0;
  ELSE
    -- hub display name: yp.entity.ident is often NULL on freshly-created
    -- hubs. Fall back through yp.hub.name, then yp.hub.hubname, before
    -- letting the FE see a hex id. Using IFNULL chains here instead of
    -- COALESCE+NULLIF because the prepared-statement layer mishandles
    -- the embedded empty-string literal (caused a 1064 'near ""' error
    -- in MariaDB 10.x).
    SET @sql = CONCAT(
      'SELECT e.id AS hub_id, ',
      '       IFNULL(IFNULL(e.ident, h.name), h.hubname) AS hub_name, ',
      '       e.area AS area, ',
      '       e.mtime AS mtime, ',
      '       du.size AS storage_size, ',
      '       p.permission ',
      'FROM `', _db_name, '`.permission p ',
      'INNER JOIN yp.entity e ON e.id = p.resource_id ',
      'LEFT JOIN yp.hub h ON h.id = e.id ',
      'LEFT JOIN yp.disk_usage du ON du.hub_id = e.id ',
      'WHERE p.entity_id = ', QUOTE(_uid),
      ' AND p.resource_id != \'*\' ',
      ' AND (p.expiry_time = 0 OR p.expiry_time > UNIX_TIMESTAMP()) ',
      ' AND e.type = \'hub\' ',
      ' AND e.dom_id = ', _dom_id,
      ' AND e.status = \'active\' ',
      ' ORDER BY e.ident ASC, e.id ASC'
    );
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;
END$

DELIMITER ;