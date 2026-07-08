DELIMITER $

DROP PROCEDURE IF EXISTS `get_org_user_storage`$
CREATE PROCEDURE `get_org_user_storage`(
  IN _domain_id INT(11) UNSIGNED,
  IN _sort_by VARCHAR(32),
  IN _page TINYINT(4)
)
BEGIN
  DECLARE _range BIGINT;
  DECLARE _offset BIGINT;
  DECLARE _finished INT DEFAULT 0;
  DECLARE _db_name VARCHAR(255) CHARACTER SET ascii;

  DECLARE hub_cursor CURSOR FOR
    SELECT e.db_name
    FROM yp.entity e
    WHERE e.dom_id = _domain_id
      AND e.type = 'hub'
      AND e.status = 'active'
      AND e.db_name IS NOT NULL
      AND e.db_name != '';

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET _finished = 1;

  CALL pageToLimits(_page, _offset, _range);

  SET _sort_by = IFNULL(_sort_by, 'usage_high');

  -- Per-user bytes attributed by file owner_id across org workspaces only.
  -- Matches get_org_storage_stats (sum of yp.disk_usage per hub) when every
  -- file in those hubs is owned by a domain member. The previous source
  -- (disk_usage(uid)) counted entire owned hubs + personal space, which
  -- diverged from the org workspace total shown in the Storage tab.
  DROP TEMPORARY TABLE IF EXISTS _org_user_usage;
  CREATE TEMPORARY TABLE _org_user_usage (
    uid VARCHAR(16) NOT NULL PRIMARY KEY,
    used_bytes BIGINT UNSIGNED NOT NULL DEFAULT 0
  );

  INSERT INTO _org_user_usage (uid, used_bytes)
  SELECT d.id, 0
  FROM yp.drumate d
  INNER JOIN yp.privilege p ON p.uid = d.id
  WHERE d.domain_id = _domain_id;

  SET _finished = 0;
  OPEN hub_cursor;
  hub_loop: LOOP
    FETCH hub_cursor INTO _db_name;
    IF _finished = 1 THEN
      LEAVE hub_loop;
    END IF;

    DROP TEMPORARY TABLE IF EXISTS _hub_slice;
    CREATE TEMPORARY TABLE _hub_slice (
      uid VARCHAR(16) NOT NULL PRIMARY KEY,
      used_bytes BIGINT UNSIGNED NOT NULL DEFAULT 0
    );

    SET @sql = CONCAT(
      'INSERT INTO _hub_slice (uid, used_bytes) ',
      'SELECT m.owner_id, SUM(m.filesize) ',
      'FROM `', _db_name, '`.media m ',
      'INNER JOIN yp.drumate d ON d.id = m.owner_id AND d.domain_id = ', _domain_id, ' ',
      'WHERE m.status NOT IN (''hidden'', ''deleted'') ',
      'AND m.category NOT IN (''folder'', ''hub'', ''root'') ',
      'GROUP BY m.owner_id'
    );
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    UPDATE _org_user_usage u
    INNER JOIN _hub_slice s ON s.uid = u.uid
    SET u.used_bytes = u.used_bytes + s.used_bytes;

    DROP TEMPORARY TABLE IF EXISTS _hub_slice;
  END LOOP hub_loop;
  CLOSE hub_cursor;

  SELECT
    d.id AS uid,
    d.firstname,
    d.lastname,
    d.fullname,
    d.email,
    p.privilege AS domain_privilege,
    COALESCE(u.used_bytes, 0) AS used_bytes,
    ROUND(COALESCE(u.used_bytes, 0) / 1048576, 2) AS used_mb
  FROM yp.drumate d
  INNER JOIN yp.privilege p ON p.uid = d.id
  LEFT JOIN _org_user_usage u ON u.uid = d.id
  WHERE d.domain_id = _domain_id
  ORDER BY
    CASE WHEN _sort_by = 'usage_high' THEN COALESCE(u.used_bytes, 0) END DESC,
    CASE WHEN _sort_by = 'usage_low' THEN COALESCE(u.used_bytes, 0) END ASC,
    d.lastname ASC
  LIMIT _offset, _range;

  DROP TEMPORARY TABLE IF EXISTS _org_user_usage;
END$

DELIMITER ;
