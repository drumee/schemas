DELIMITER $

DROP PROCEDURE IF EXISTS `get_org_user_storage_count`$
CREATE PROCEDURE `get_org_user_storage_count`(
  IN _domain_id INT(11) UNSIGNED
)
BEGIN
  DECLARE _finished INT DEFAULT 0;
  DECLARE _db_name VARCHAR(255) CHARACTER SET ascii;
  DECLARE _domain_members INT UNSIGNED DEFAULT 0;
  DECLARE _external_owners INT UNSIGNED DEFAULT 0;

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

  -- Count only: collect distinct owner_ids (no SUM). Matches the row set of
  -- get_org_user_storage = domain members + external/orphan owners with files.
  DROP TEMPORARY TABLE IF EXISTS _org_owners;
  CREATE TEMPORARY TABLE _org_owners (
    uid VARCHAR(16) NOT NULL PRIMARY KEY
  );

  SET _finished = 0;
  OPEN hub_cursor;
  hub_loop: LOOP
    FETCH hub_cursor INTO _db_name;
    IF _finished = 1 THEN
      LEAVE hub_loop;
    END IF;

    SET @sql = CONCAT(
      'INSERT IGNORE INTO _org_owners (uid) ',
      'SELECT DISTINCT m.owner_id ',
      'FROM `', _db_name, '`.media m ',
      'WHERE m.owner_id IS NOT NULL ',
      'AND m.owner_id != '''' ',
      'AND m.status NOT IN (''hidden'', ''deleted'') ',
      'AND m.category NOT IN (''folder'', ''hub'', ''root'')'
    );
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END LOOP hub_loop;
  CLOSE hub_cursor;

  SELECT COUNT(*)
  INTO _domain_members
  FROM yp.drumate d
  INNER JOIN yp.privilege p ON p.uid = d.id
  WHERE d.domain_id = _domain_id;

  -- External drumates + orphan uids (not in domain roster).
  SELECT COUNT(*)
  INTO _external_owners
  FROM _org_owners o
  LEFT JOIN yp.drumate d ON d.id = o.uid
  LEFT JOIN yp.privilege p ON p.uid = d.id AND d.domain_id = _domain_id
  WHERE p.uid IS NULL;

  SELECT (_domain_members + _external_owners) AS total;

  DROP TEMPORARY TABLE IF EXISTS _org_owners;
END$

DELIMITER ;
