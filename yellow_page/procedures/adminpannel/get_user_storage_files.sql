DELIMITER $

DROP PROCEDURE IF EXISTS `get_user_storage_files`$
-- Storage-breakdown drill-down (admin console): every regular file OWNED by
-- one member across the org's hubs, largest first, paginated. total windows
-- along each row (single result set — the mariadb wrapper drops extra chunks).
CREATE PROCEDURE `get_user_storage_files`(
  IN _domain_id INT(11) UNSIGNED,
  IN _uid VARCHAR(16),
  IN _page INT UNSIGNED,
  IN _sort VARCHAR(16)
)
BEGIN
  DECLARE _finished INT DEFAULT 0;
  DECLARE _hub_id VARCHAR(16);
  DECLARE _hub_name VARCHAR(255);
  DECLARE _db_name VARCHAR(255) CHARACTER SET ascii;
  DECLARE _limit INT UNSIGNED DEFAULT 50;
  DECLARE _offset INT UNSIGNED DEFAULT 0;

  DECLARE hub_cursor CURSOR FOR
    SELECT e.id, IFNULL(IFNULL(e.ident, h.name), h.hubname), e.db_name
    FROM yp.entity e
    LEFT JOIN yp.hub h ON h.id = e.id
    WHERE e.dom_id = _domain_id
      AND e.type = 'hub'
      AND e.status = 'active'
      AND e.db_name IS NOT NULL
      AND e.db_name != '';

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET _finished = 1;

  IF _page IS NULL OR _page < 1 THEN SET _page = 1; END IF;
  SET _offset = (_page - 1) * _limit;

  DROP TEMPORARY TABLE IF EXISTS _user_files;
  CREATE TEMPORARY TABLE _user_files (
    id VARCHAR(16) NOT NULL,
    hub_id VARCHAR(16) NOT NULL,
    hub_name VARCHAR(255),
    filename VARCHAR(255),
    ext VARCHAR(100),
    category VARCHAR(16),
    filesize BIGINT UNSIGNED NOT NULL DEFAULT 0,
    mtime INT(11) UNSIGNED NOT NULL DEFAULT 0
  );

  OPEN hub_cursor;
  hub_loop: LOOP
    FETCH hub_cursor INTO _hub_id, _hub_name, _db_name;
    IF _finished = 1 THEN
      LEAVE hub_loop;
    END IF;
    SET @sql = CONCAT(
      'INSERT INTO _user_files ',
      'SELECT m.id, ''', _hub_id, ''', ', QUOTE(_hub_name), ', ',
      'm.user_filename, m.extension, m.category, m.filesize, ',
      'COALESCE(NULLIF(m.publish_time, 0), m.upload_time) ',
      'FROM `', _db_name, '`.media m ',
      'WHERE m.owner_id = ', QUOTE(_uid), ' ',
      'AND m.status NOT IN (''hidden'', ''deleted'') ',
      'AND m.category NOT IN (''folder'', ''hub'', ''root'')'
    );
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END LOOP hub_loop;
  CLOSE hub_cursor;

  -- _sort: 'size_asc' flips to smallest-first; anything else = largest-first.
  SELECT
    id, hub_id, hub_name, filename, ext, category, filesize, mtime,
    COUNT(*) OVER () AS total,
    SUM(filesize) OVER () AS total_bytes
  FROM _user_files
  ORDER BY
    IF(_sort = 'size_asc', filesize, NULL) ASC,
    IF(_sort = 'size_asc', NULL, filesize) DESC
  LIMIT _limit OFFSET _offset;

  DROP TEMPORARY TABLE IF EXISTS _user_files;
END$

DELIMITER ;
