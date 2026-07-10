DELIMITER $

DROP PROCEDURE IF EXISTS `get_hub_stale_files`$
-- File browser backing the Storage Console "Delete Files" flow: the hub's
-- regular files sorted oldest-modified first (staleness), paginated. `total`
-- rides along on every row (window COUNT) so the transport stays a single
-- result set — the mariadb wrapper drops extra chunks on multi-SELECT procs.
CREATE PROCEDURE `get_hub_stale_files`(
  IN _hub_id VARCHAR(16),
  IN _page INT UNSIGNED
)
BEGIN
  DECLARE _db_name VARCHAR(255) CHARACTER SET ascii;
  DECLARE _limit INT UNSIGNED DEFAULT 50;
  DECLARE _offset INT UNSIGNED DEFAULT 0;

  SELECT e.db_name FROM yp.entity e WHERE e.id = _hub_id LIMIT 1 INTO _db_name;
  IF _db_name IS NULL OR _db_name = '' THEN
    SELECT NULL AS id LIMIT 0;
  ELSE
    IF _page IS NULL OR _page < 1 THEN SET _page = 1; END IF;
    SET _offset = (_page - 1) * _limit;
    SET @sql = CONCAT(
      'SELECT m.id, m.filename, m.ext, m.category, m.filesize, m.mtime, ',
      'COUNT(*) OVER () AS total ',
      'FROM `', _db_name, '`.media m ',
      'WHERE m.status NOT IN (''hidden'', ''deleted'') ',
      'AND m.category NOT IN (''folder'', ''hub'', ''root'') ',
      'ORDER BY (m.mtime = 0), m.mtime ASC ',
      'LIMIT ', _limit, ' OFFSET ', _offset
    );
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;
END$

DELIMITER ;
