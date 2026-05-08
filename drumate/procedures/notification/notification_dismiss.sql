-- File: schemas/drumate/procedures/notification/notification_dismiss.sql
-- Purpose: Single entry point for dismissing any notification rollup returned by
-- `notification_center_next`. Called from `activity.notification_dismiss` endpoint.
-- Routes by `_category` to the right read-pointer or status update.

DELIMITER $

DROP PROCEDURE IF EXISTS `notification_dismiss`$

CREATE PROCEDURE `notification_dismiss`(
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
      -- Advance p2p_read pointer for this peer
      INSERT INTO p2p_read (uid, peer_id, ref_ctime, ctime)
      VALUES (_uid, _key_id, _last_id, _now)
      ON DUPLICATE KEY UPDATE
        ref_ctime = GREATEST(VALUES(ref_ctime), ref_ctime),
        ctime = _now;

    WHEN 'contact' THEN
      -- Mark the contact-invite row as dismissed (audit-preserving)
      UPDATE contact
         SET dismissed_at = _now
       WHERE id = _key_id
         AND dismissed_at IS NULL;

    WHEN 'media' THEN
      -- Stamp every undismissed mfs_changelog row tied to this hub (up to _last_id)
      -- as dismissed for this user. mfs_dismissed lives in this drumate DB.
      INSERT IGNORE INTO mfs_dismissed (changelog_id, user_id, mtime)
      SELECT ch.id, _uid, _now
        FROM yp.mfs_changelog ch
       WHERE ch.hub_id = _hub_id
         AND ch.uid != _uid
         AND ch.id <= _last_id;

    WHEN 'teamchat' THEN
      -- Advance read_channel.ref_sys_id in the hub's per-hub DB
      SELECT db_name INTO _hub_db FROM yp.entity WHERE id = _hub_id;
      IF _hub_db IS NOT NULL THEN
        SET @sql = CONCAT(
          "INSERT INTO `", _hub_db, "`.read_channel (uid, ref_sys_id, ctime) ",
          "VALUES ('", _uid, "', ", _last_id, ", ", _now, ") ",
          "ON DUPLICATE KEY UPDATE ref_sys_id = GREATEST(VALUES(ref_sys_id), ref_sys_id), ctime = ", _now
        );
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
      END IF;

    WHEN 'ticket' THEN
      -- Advance ticket read pointer in yp.read_ticket_channel
      INSERT INTO yp.read_ticket_channel (uid, ticket_id, ref_sys_id, ctime)
      VALUES (_uid, _key_id, _last_id, _now)
      ON DUPLICATE KEY UPDATE
        ref_sys_id = GREATEST(VALUES(ref_sys_id), ref_sys_id),
        ctime = _now;

    ELSE
      -- Unknown category — no-op, return the input for diagnostics.
      SELECT 'noop' AS status, _category AS category, _key_id AS key_id;
  END CASE;

  SELECT 'ok' AS status, _category AS category, _key_id AS key_id, _hub_id AS hub_id, _last_id AS last_id, _now AS dismissed_at;
END$

DELIMITER ;
