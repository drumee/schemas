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
      -- Personal spaces count too: a domain member's "My Drumee" uploads
      -- are billed against the org quota (yp.quota_usage tracks them), so
      -- the member breakdown must attribute them as well -- hub-only made
      -- personal uploads invisible here ("uploaded 30MB, number never
      -- moved"). media.owner_id attribution works identically in drumate
      -- and organization DBs.
      AND e.type IN ('hub', 'drumate', 'organization')
      AND e.status = 'active'
      AND e.db_name IS NOT NULL
      AND e.db_name != '';

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET _finished = 1;

  CALL pageToLimits(_page, _offset, _range);
  SET _sort_by = IFNULL(_sort_by, 'usage_high');

  -- Attribute file bytes by owner_id across org workspaces:
  -- domain members (always listed) + external collaborators + orphan owners.
  DROP TEMPORARY TABLE IF EXISTS _org_user_usage;
  CREATE TEMPORARY TABLE _org_user_usage (
    uid VARCHAR(16) NOT NULL PRIMARY KEY,
    used_bytes BIGINT UNSIGNED NOT NULL DEFAULT 0
  );

  SET _finished = 0;
  OPEN hub_cursor;
  hub_loop: LOOP
    FETCH hub_cursor INTO _db_name;
    IF _finished = 1 THEN
      LEAVE hub_loop;
    END IF;

    SET @sql = CONCAT(
      'INSERT INTO _org_user_usage (uid, used_bytes) ',
      'SELECT m.owner_id, SUM(m.filesize) ',
      'FROM `', _db_name, '`.media m ',
      'WHERE m.owner_id IS NOT NULL ',
      'AND m.owner_id != '''' ',
      'AND m.status NOT IN (''hidden'', ''deleted'') ',
      'AND m.category NOT IN (''folder'', ''hub'', ''root'') ',
      'GROUP BY m.owner_id ',
      'ON DUPLICATE KEY UPDATE ',
      'used_bytes = used_bytes + VALUES(used_bytes)'
    );
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END LOOP hub_loop;
  CLOSE hub_cursor;

  DROP TEMPORARY TABLE IF EXISTS _org_user_rows;
  CREATE TEMPORARY TABLE _org_user_rows (
    uid VARCHAR(16) NOT NULL PRIMARY KEY,
    firstname VARCHAR(128),
    lastname VARCHAR(128),
    fullname VARCHAR(256),
    email VARCHAR(256),
    domain_privilege INT UNSIGNED,
    is_external TINYINT UNSIGNED NOT NULL DEFAULT 0,
    used_bytes BIGINT UNSIGNED NOT NULL DEFAULT 0
  );

  -- Domain members (0 B rows included for the full roster).
  INSERT INTO _org_user_rows (
    uid, firstname, lastname, fullname, email, domain_privilege, is_external, used_bytes
  )
  SELECT
    d.id,
    d.firstname,
    d.lastname,
    d.fullname,
    d.email,
    IFNULL(p.privilege, 0),
    0,
    COALESCE(u.used_bytes, 0)
  FROM yp.drumate d
  -- LEFT JOIN: a domain member without a yp.privilege row must still be
  -- listed — their files count in TOTAL HUB CAPACITY (get_org_storage_stats
  -- has no owner filter), so dropping the row here made the distribution sum
  -- fall short of the total. Also aligns with get_org_user_storage_count.
  LEFT JOIN yp.privilege p ON p.uid = d.id
  LEFT JOIN _org_user_usage u ON u.uid = d.id
  WHERE d.domain_id = _domain_id;

  -- External collaborators (other domains) with files in org hubs.
  INSERT INTO _org_user_rows (
    uid, firstname, lastname, fullname, email, domain_privilege, is_external, used_bytes
  )
  SELECT
    d.id,
    d.firstname,
    d.lastname,
    d.fullname,
    d.email,
    0,
    1,
    u.used_bytes
  FROM _org_user_usage u
  INNER JOIN yp.drumate d ON d.id = u.uid
  WHERE u.used_bytes > 0
    AND d.domain_id != _domain_id;

  -- Orphan owners (uid no longer in yp.drumate).
  INSERT INTO _org_user_rows (
    uid, firstname, lastname, fullname, email, domain_privilege, is_external, used_bytes
  )
  SELECT
    u.uid,
    NULL,
    NULL,
    u.uid,
    NULL,
    0,
    1,
    u.used_bytes
  FROM _org_user_usage u
  LEFT JOIN yp.drumate d ON d.id = u.uid
  WHERE u.used_bytes > 0
    AND d.id IS NULL;

  SELECT
    uid,
    firstname,
    lastname,
    fullname,
    email,
    domain_privilege,
    is_external,
    used_bytes,
    ROUND(used_bytes / 1048576, 2) AS used_mb
  FROM _org_user_rows
  ORDER BY
    CASE WHEN _sort_by = 'usage_high' THEN used_bytes END DESC,
    CASE WHEN _sort_by = 'usage_low' THEN used_bytes END ASC,
    lastname ASC
  LIMIT _offset, _range;

  DROP TEMPORARY TABLE IF EXISTS _org_user_rows;
  DROP TEMPORARY TABLE IF EXISTS _org_user_usage;
END$

DELIMITER ;
