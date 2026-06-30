-- File: schemas/drumate/procedures/notification/notification_read.sql
-- Purpose: Mark a rollup as READ (advance read pointer) without hiding it
-- from the feed. For chat/ticket the underlying schema only has a read
-- pointer, so read == dismiss. teamchat marks per-message `_seen_` on the
-- target folder's delivered messages (per-folder, keeps notification_center_next
-- unread consistent). For contact/media we currently have no
-- separate `read_at` column, so we no-op here and let `notification_dismiss`
-- be the only flag-setter — invoking this proc still advances the per-source
-- read counters where they exist.

DELIMITER $

DROP PROCEDURE IF EXISTS `notification_read`$

CREATE PROCEDURE `notification_read`(
  IN _category VARCHAR(16),
  IN _key_id VARCHAR(255),
  IN _hub_id VARCHAR(16),
  IN _last_id BIGINT
)
BEGIN
  DECLARE _uid VARCHAR(16) CHARACTER SET ascii;
  DECLARE _now INT(11) UNSIGNED;
  DECLARE _hub_db VARCHAR(255);

  SELECT id INTO _uid FROM yp.entity WHERE db_name = DATABASE();
  SELECT UNIX_TIMESTAMP() INTO _now;

  CASE _category
    WHEN 'chat' THEN
      INSERT INTO p2p_read (uid, peer_id, ref_ctime, ctime)
      VALUES (_uid, _key_id, _last_id, _now)
      ON DUPLICATE KEY UPDATE
        ref_ctime = GREATEST(VALUES(ref_ctime), ref_ctime),
        ctime = _now;

    WHEN 'media' THEN
      -- Advance per-user mfs_ack (= "last seen changelog id"). Does NOT
      -- create mfs_dismissed rows so the items remain visible in the feed
      -- as informational, but the badge counter goes down.
      INSERT INTO mfs_ack (user_id, last_read_id, mtime)
      VALUES (_uid, _last_id, _now)
      ON DUPLICATE KEY UPDATE
        last_read_id = GREATEST(VALUES(last_read_id), last_read_id),
        mtime = _now;

    WHEN 'teamchat' THEN
      -- Per-folder: mark the caller `_seen_` on the target folder's delivered,
      -- still-unseen messages instead of advancing the per-hub read_channel
      -- pointer. _key_id is the folder nid (or the hub id for a hub-level/legacy
      -- chat with no _scope_nid). Keeps notification_center_next's _seen_-based
      -- unread consistent, so reading one folder's mentions does not clear a
      -- sibling folder's.
      SELECT db_name INTO _hub_db FROM yp.entity WHERE id = _hub_id;
      IF _hub_db IS NOT NULL THEN
        SET @sql = CONCAT(
          "UPDATE `", _hub_db, "`.channel ",
          "SET metadata = JSON_SET(IFNULL(metadata,'{}'), '$._seen_.", _uid, "', ", _now, ") ",
          "WHERE status='active' AND author_id <> '", _uid, "' ",
          "AND JSON_EXISTS(metadata,'$._delivered_.", _uid, "')=1 ",
          "AND JSON_EXISTS(metadata,'$._seen_.", _uid, "')=0 ",
          "AND ( JSON_UNQUOTE(JSON_EXTRACT(metadata,'$._scope_nid')) = '", _key_id, "' ",
          "      OR (JSON_EXTRACT(metadata,'$._scope_nid') IS NULL AND '", _key_id, "' = '", _hub_id, "') ) ",
          "AND (", IFNULL(_last_id, 0), " <= 0 OR sys_id <= ", IFNULL(_last_id, 0), ")"
        );
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
      END IF;

    WHEN 'ticket' THEN
      INSERT INTO yp.read_ticket_channel (uid, ticket_id, ref_sys_id, ctime)
      VALUES (_uid, _key_id, _last_id, _now)
      ON DUPLICATE KEY UPDATE
        ref_sys_id = GREATEST(VALUES(ref_sys_id), ref_sys_id),
        ctime = _now;

    WHEN 'contact' THEN
      -- No read_at column; ack-only is a no-op. Use notification_dismiss
      -- if you actually want to remove the row from the feed.
      SELECT 'noop' AS status, _category AS category;

    ELSE
      SELECT 'noop' AS status, _category AS category, _key_id AS key_id;
  END CASE;

  SELECT 'ok' AS status, _category AS category, _key_id AS key_id, _hub_id AS hub_id, _last_id AS last_id, _now AS read_at;
END$

DELIMITER ;
