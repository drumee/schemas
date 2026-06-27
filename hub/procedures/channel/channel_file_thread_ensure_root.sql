DELIMITER $

-- =========================================================
-- channel_file_thread_ensure_root
-- Atomically reserve the per-file chat thread for _file_nid and the
-- folder-visible "file.thread" root system card, if not already present.
-- Race-safe: UNIQUE(file_nid) guarantees exactly one thread per file even
-- under concurrent first sends. The winner's _root_message_id wins; losers
-- adopt the existing root_message_id (service MUST use the returned one).
-- Returns: file_nid, folder_nid, file_thread_id (=root_message_id), is_new.
-- =========================================================
DROP PROCEDURE IF EXISTS `channel_file_thread_ensure_root`$
CREATE PROCEDURE `channel_file_thread_ensure_root`(
  IN _file_nid VARCHAR(16),
  IN _folder_nid VARCHAR(16),
  IN _root_message_id VARCHAR(16),
  IN _uid VARCHAR(16)
)
BEGIN
  DECLARE _now INT(11) UNSIGNED;
  DECLARE _dup INT DEFAULT 0;
  DECLARE _eff_root VARCHAR(16) CHARACTER SET ascii DEFAULT NULL;
  DECLARE _eff_folder VARCHAR(16) CHARACTER SET ascii DEFAULT NULL;
  DECLARE _is_new INT DEFAULT 0;
  DECLARE _member VARCHAR(16) CHARACTER SET ascii;
  DECLARE _done INT DEFAULT 0;
  DECLARE member_cursor CURSOR FOR
    SELECT d.id
    FROM permission p
    INNER JOIN yp.drumate d ON p.entity_id = d.id
    WHERE p.resource_id = '*' AND d.id <> _uid;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET _done = 1;

  SET _now = UNIX_TIMESTAMP();
  SET _dup = 0;

  -- Scope the duplicate-key handler to ONLY the thread-reservation INSERT, so
  -- the UNIQUE(file_nid) race is absorbed here while any OTHER integrity error
  -- later in the proc surfaces instead of being silently swallowed.
  BEGIN
    DECLARE CONTINUE HANDLER FOR SQLSTATE '23000' SET _dup = 1;
    INSERT INTO file_thread (file_nid, folder_nid, root_message_id, created_by, last_message_id, reply_count, ctime, mtime, status)
    VALUES (_file_nid, _folder_nid, _root_message_id, _uid, NULL, 0, _now, _now, 'active');
  END;

  IF _dup = 1 THEN
    -- Another concurrent sender created this thread first; adopt its root.
    SET _is_new = 0;
    SELECT root_message_id, folder_nid INTO _eff_root, _eff_folder
      FROM file_thread WHERE file_nid = _file_nid AND status = 'active' LIMIT 1;
  ELSE
    SET _is_new = 1;
    SET _eff_root = _root_message_id;
    SET _eff_folder = _folder_nid;
  END IF;

  -- Ensure the folder-visible root system card exists (idempotent). The card
  -- is a normal channel row: file_thread_id NULL (it is not a child),
  -- metadata.message_type 'file.thread', scoped to the folder via _scope_nid.
  INSERT IGNORE INTO channel (message_id, author_id, message, thread_id, file_thread_id, ctime, attachment, mention_ids, metadata)
  SELECT _eff_root, _uid, NULL, NULL, NULL, _now, NULL, NULL,
    JSON_OBJECT(
      'message_type', 'file.thread',
      '_scope_nid', _eff_folder,
      '_file_thread_root', 1,
      '_file_thread_id', _eff_root,
      '_file_nid', _file_nid
    );

  -- Seed per-message seen/delivered for the creator so the card is not its own
  -- unread item; only applied if not already present.
  UPDATE channel SET metadata = JSON_MERGE(
      IFNULL(metadata, '{}'),
      JSON_OBJECT('_seen_', JSON_OBJECT(_uid, 1)),
      JSON_OBJECT('_delivered_', JSON_OBJECT(_uid, _now))
    )
    WHERE message_id = _eff_root
    AND JSON_EXISTS(metadata, CONCAT('$._seen_.', _uid)) = 0;

  -- Deliver the root card to every hub member (excluding the creator) so the
  -- notification center counts it as ONE unread folder item per thread. Mirrors
  -- the delivery cursor in channel_post_message. Idempotent (JSON_SET), so it is
  -- safe even if a concurrent caller already delivered the same card.
  SET _done = 0;
  OPEN member_cursor;
    read_loop: LOOP
      FETCH member_cursor INTO _member;
      IF _done = 1 THEN LEAVE read_loop; END IF;
      UPDATE channel SET metadata = JSON_SET(metadata, CONCAT('$._delivered_.', _member), _now)
        WHERE message_id = _eff_root AND _member IS NOT NULL;
    END LOOP read_loop;
  CLOSE member_cursor;

  SELECT
    _file_nid AS file_nid,
    _eff_folder AS folder_nid,
    _eff_root AS file_thread_id,
    _eff_root AS root_message_id,
    _is_new AS is_new;
END $

DELIMITER ;
