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
      -- Mark this user `_seen_` on the file metadata — matching how the rollup
      -- computes unread: notification_center_next(media) uses
      -- is_new(metadata, owner, uid) = "_seen_.<uid> not set", grouped per folder
      -- (nid = target.id = IF(category='folder', id, parent_id)). _key_id is that
      -- folder nid (sent by the client). Marking `_seen_` on the folder + its
      -- still-new children flips is_new->0 so the rollup clears.
      -- NOTE: the OLD code wrote mfs_dismissed, which the rollup display never
      -- reads (it reads is_new/metadata) -> dismiss never cleared. The separate
      -- smart-list feed (mfs_get_activity_feed) still uses mfs_dismissed via
      -- mfs_dismiss_activity and is UNAFFECTED by this change.
      SELECT db_name INTO _hub_db FROM yp.entity WHERE id = _hub_id;
      IF _hub_db IS NOT NULL THEN
        SET @sql = CONCAT(
          "UPDATE `", _hub_db, "`.media ",
          "SET metadata = JSON_SET(IFNULL(metadata,'{}'), '$._seen_.", _uid, "', ", _now, ") ",
          "WHERE owner_id <> '", _uid, "' ",
          "AND IF(category='folder', id, parent_id) = '", _key_id, "' ",
          "AND IFNULL(is_new(metadata, owner_id, '", _uid, "'), 0) = 1"
        );
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
      END IF;

    WHEN 'teamchat' THEN
      -- Per-folder: mark the caller `_seen_` on the target folder's delivered,
      -- still-unseen messages instead of advancing the per-hub read_channel
      -- pointer. _key_id is the folder nid (or the hub id for a hub-level/legacy
      -- chat with no _scope_nid). Keeps notification_center_next's _seen_-based
      -- unread consistent, so dismissing one folder's mentions does not clear a
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
