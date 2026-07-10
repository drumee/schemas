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
    -- media has no mtime column: "last modified" = publish_time, falling
    -- back to upload_time. Zero timestamps sort last (unknown age).
    SET @sql = CONCAT(
      'SELECT m.id, m.user_filename AS filename, m.extension AS ext, ',
      'm.category, m.filesize, ',
      'COALESCE(NULLIF(m.publish_time, 0), m.upload_time) AS mtime, ',
      'COUNT(*) OVER () AS total ',
      'FROM `', _db_name, '`.media m ',
      'WHERE m.status NOT IN (''hidden'', ''deleted'') ',
      'AND m.category NOT IN (''folder'', ''hub'', ''root'') ',
      'ORDER BY (COALESCE(NULLIF(m.publish_time, 0), m.upload_time) = 0), ',
      'COALESCE(NULLIF(m.publish_time, 0), m.upload_time) ASC ',
      'LIMIT ', _limit, ' OFFSET ', _offset
    );
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;
END$

DELIMITER ;
