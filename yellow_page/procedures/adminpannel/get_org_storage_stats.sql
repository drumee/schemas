DELIMITER $

DROP PROCEDURE IF EXISTS `get_org_storage_stats`$
CREATE PROCEDURE `get_org_storage_stats`(
  IN _domain_id INT(11) UNSIGNED
)
BEGIN
  DECLARE _finished INT DEFAULT 0;
  DECLARE _hub_id VARCHAR(16);
  DECLARE _db_name VARCHAR(255) CHARACTER SET ascii;
  DECLARE _used BIGINT UNSIGNED DEFAULT 0;

  DECLARE hub_cursor CURSOR FOR
    SELECT e.id, e.db_name
    FROM yp.entity e
    WHERE e.dom_id = _domain_id
      AND e.type = 'hub'
      AND e.status = 'active'
      AND e.db_name IS NOT NULL
      AND e.db_name != '';

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET _finished = 1;

  -- Live SUM(media.filesize) per org hub so TOTAL HUB STORAGE matches
  -- get_org_user_storage (all owners, including external collaborators).
  DROP TEMPORARY TABLE IF EXISTS _org_hub_usage;
  CREATE TEMPORARY TABLE _org_hub_usage (
    hub_id VARCHAR(16) NOT NULL PRIMARY KEY,
    hub_name VARCHAR(255),
    used_bytes BIGINT UNSIGNED NOT NULL DEFAULT 0
  );

  INSERT INTO _org_hub_usage (hub_id, hub_name, used_bytes)
  SELECT
    e.id,
    IFNULL(IFNULL(e.ident, h.name), h.hubname),
    0
  FROM yp.entity e
  LEFT JOIN yp.hub h ON h.id = e.id
  WHERE e.dom_id = _domain_id
    AND e.type = 'hub'
    AND e.status = 'active';

  SET _finished = 0;
  OPEN hub_cursor;
  hub_loop: LOOP
    FETCH hub_cursor INTO _hub_id, _db_name;
    IF _finished = 1 THEN
      LEAVE hub_loop;
    END IF;

    SET _used = 0;
    SET @sql = CONCAT(
      'SELECT COALESCE(SUM(m.filesize), 0) INTO @hub_used_bytes ',
      'FROM `', _db_name, '`.media m ',
      'WHERE m.status NOT IN (''hidden'', ''deleted'') ',
      'AND m.category NOT IN (''folder'', ''hub'', ''root'')'
    );
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    SET _used = COALESCE(@hub_used_bytes, 0);

    UPDATE _org_hub_usage
    SET used_bytes = _used
    WHERE hub_id = _hub_id;
  END LOOP hub_loop;
  CLOSE hub_cursor;

  SELECT
    hub_id,
    hub_name,
    used_bytes,
    ROUND(used_bytes / 1048576, 2) AS used_mb
  FROM _org_hub_usage
  ORDER BY used_bytes DESC;

  DROP TEMPORARY TABLE IF EXISTS _org_hub_usage;
END$

DELIMITER ;
