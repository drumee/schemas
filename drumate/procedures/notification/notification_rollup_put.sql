DELIMITER $

DROP PROCEDURE IF EXISTS `notification_rollup_put`$
CREATE PROCEDURE `notification_rollup_put`(
  IN _user_id VARCHAR(16),
  IN _rows LONGTEXT
)
BEGIN
  -- Capture the current live rollups so they can still be rendered once they
  -- have been read. See drumate/tables/notification_rollup.sql for why this is
  -- the only way a rollup can survive being read.
  --
  -- Takes the whole set as ONE json array rather than one call per rollup.
  -- This runs on every bell-badge refresh, which a chat websocket push can
  -- trigger once a second, so a per-row round trip would multiply the busiest
  -- notification path by the number of active conversations.
  DECLARE _i INT DEFAULT 0;
  DECLARE _n INT DEFAULT 0;
  DECLARE _row LONGTEXT;

  IF _rows IS NULL OR JSON_VALID(_rows) = 0 THEN
    SELECT 'noop' AS status, 0 AS stored;
  ELSE
    SET _n = IFNULL(JSON_LENGTH(_rows), 0);

    WHILE _i < _n DO
      SET _row = JSON_EXTRACT(_rows, CONCAT('$[', _i, ']'));

      -- A rollup with no category or key cannot be addressed later, so it is
      -- skipped rather than stored under an empty key where it would collide
      -- with every other malformed row.
      IF JSON_UNQUOTE(JSON_EXTRACT(_row, '$.category')) IS NOT NULL
         AND JSON_UNQUOTE(JSON_EXTRACT(_row, '$.key_id')) IS NOT NULL THEN

        INSERT INTO notification_rollup
          (user_id, category, key_id, hub_id, payload, last_id, ctime, mtime, deleted)
        VALUES (
          _user_id,
          JSON_UNQUOTE(JSON_EXTRACT(_row, '$.category')),
          JSON_UNQUOTE(JSON_EXTRACT(_row, '$.key_id')),
          JSON_UNQUOTE(JSON_EXTRACT(_row, '$.hub_id')),
          _row,
          JSON_EXTRACT(_row, '$.last_id'),
          IFNULL(JSON_EXTRACT(_row, '$.ctime'), UNIX_TIMESTAMP()),
          UNIX_TIMESTAMP(),
          0
        )
        ON DUPLICATE KEY UPDATE
          -- Order matters and is load bearing: MariaDB evaluates these
          -- assignments left to right and each one sees the results of the
          -- previous, so every comparison against ctime must happen BEFORE
          -- ctime itself is advanced. Moving the ctime line up would make all
          -- three tests above compare the incoming value against itself.
          payload = IF(VALUES(ctime) >= ctime, VALUES(payload), payload),
          hub_id  = IF(VALUES(ctime) >= ctime, VALUES(hub_id), hub_id),
          -- Only genuinely NEWER activity clears a deletion. Without the
          -- strict >, a refresh racing the trash button would re-store the
          -- same unchanged rollup and bring the row the user just deleted
          -- straight back. A new message is a new notification and should
          -- reappear; the same old message must not.
          deleted = IF(VALUES(ctime) > ctime, 0, deleted),
          last_id = GREATEST(IFNULL(VALUES(last_id), 0), IFNULL(last_id, 0)),
          ctime   = GREATEST(VALUES(ctime), ctime),
          mtime   = UNIX_TIMESTAMP();
      END IF;

      SET _i = _i + 1;
    END WHILE;

    SELECT 'ok' AS status, _n AS stored;
  END IF;
END$

DELIMITER ;
