DELIMITER $

DROP PROCEDURE IF EXISTS `get_hub_user_storage`$
CREATE PROCEDURE `get_hub_user_storage`(
  IN _hub_id VARCHAR(16),
  IN _sort_by VARCHAR(32),
  IN _page TINYINT(4)
)
BEGIN
  DECLARE _range BIGINT;
  DECLARE _offset BIGINT;

  CALL pageToLimits(_page, _offset, _range);
  SET _sort_by = IFNULL(_sort_by, 'usage_high');

  -- Attribute every file to owner_id so member totals reconcile with
  -- get_hub_storage_stats.hub_used_bytes. Hub members with 0 B still appear;
  -- non-member owners with files are included so bytes are not dropped.
  DROP TEMPORARY TABLE IF EXISTS _hub_owner_usage;
  CREATE TEMPORARY TABLE _hub_owner_usage (
    uid VARCHAR(16) NOT NULL PRIMARY KEY,
    used_bytes BIGINT UNSIGNED NOT NULL DEFAULT 0
  );

  INSERT INTO _hub_owner_usage (uid, used_bytes)
  SELECT
    m.owner_id,
    SUM(m.filesize)
  FROM media m
  WHERE m.owner_id IS NOT NULL
    AND m.owner_id != ''
    AND m.status NOT IN ('hidden', 'deleted')
    AND m.category NOT IN ('folder', 'hub', 'root')
  GROUP BY m.owner_id;

  DROP TEMPORARY TABLE IF EXISTS _hub_user_rows;
  CREATE TEMPORARY TABLE _hub_user_rows (
    uid VARCHAR(16) NOT NULL PRIMARY KEY,
    firstname VARCHAR(128),
    lastname VARCHAR(128),
    fullname VARCHAR(256),
    email VARCHAR(256),
    hub_permission INT UNSIGNED,
    used_bytes BIGINT UNSIGNED NOT NULL DEFAULT 0
  );

  INSERT INTO _hub_user_rows (uid, firstname, lastname, fullname, email, hub_permission, used_bytes)
  SELECT
    p.entity_id,
    d.firstname,
    d.lastname,
    d.fullname,
    d.email,
    p.permission,
    COALESCE(o.used_bytes, 0)
  FROM permission p
  INNER JOIN yp.drumate d ON d.id = p.entity_id
  LEFT JOIN _hub_owner_usage o ON o.uid = p.entity_id
  WHERE p.resource_id = '*'
    AND p.permission > 0;

  INSERT INTO _hub_user_rows (uid, firstname, lastname, fullname, email, hub_permission, used_bytes)
  SELECT
    o.uid,
    d.firstname,
    d.lastname,
    d.fullname,
    d.email,
    0,
    o.used_bytes
  FROM _hub_owner_usage o
  LEFT JOIN yp.drumate d ON d.id = o.uid
  LEFT JOIN permission p
    ON p.entity_id = o.uid
   AND p.resource_id = '*'
   AND p.permission > 0
  WHERE o.used_bytes > 0
    AND p.entity_id IS NULL;

  SELECT
    uid,
    firstname,
    lastname,
    fullname,
    email,
    hub_permission,
    used_bytes,
    ROUND(used_bytes / 1048576, 2) AS used_mb
  FROM _hub_user_rows
  ORDER BY
    CASE WHEN _sort_by = 'usage_high' THEN used_bytes END DESC,
    CASE WHEN _sort_by = 'usage_low' THEN used_bytes END ASC,
    lastname ASC
  LIMIT _offset, _range;

  DROP TEMPORARY TABLE IF EXISTS _hub_user_rows;
  DROP TEMPORARY TABLE IF EXISTS _hub_owner_usage;
END$

DELIMITER ;
