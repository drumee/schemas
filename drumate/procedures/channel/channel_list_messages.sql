-- ============================================================================
-- DRAFT (Part 2) — for Aaron's review. Drumate-native channel_list_messages
-- with the per-file-thread delta applied to DRUMATE's own version (NOT the hub
-- version — hub uses read_channel UNIQUE(uid); drumate is per-entity, so the
-- hub SP cannot be shared here — see the Part-2 notes on PR).
--
-- Delta vs drumate's current (template-baked) version, all marked -- [ft]:
--   1) WHERE c.file_thread_id IS NULL  — file-thread replies must NOT appear in
--      the main personal chat list (they have their own path,
--      channel_file_thread_list_messages).
--   2) expose c.file_thread_id in the output.
-- Everything else is drumate's existing logic, unchanged.
--
-- TODO(Aaron): confirm output-parity needs (hub also returns mention_ids /
--   is_forward / file_thread_id / message_type) — added file_thread_id only here
--   since that's what the feature requires; add others if the client expects them.
-- ============================================================================
DELIMITER $
DROP PROCEDURE IF EXISTS `channel_list_messages`$
CREATE PROCEDURE `channel_list_messages`(
  IN _uid VARCHAR(16),
  IN _sort_by VARCHAR(20),
  IN _order   VARCHAR(20),
  IN _page    TINYINT(4)
)
BEGIN
  DECLARE _recipient_db VARCHAR(255);
  DECLARE _msg_id VARCHAR(16);
  DECLARE _timestamp int(11) unsigned;
  DECLARE _range bigint;
  DECLARE _offset bigint;
  CALL pageToLimits(_page, _offset, _range);

  SELECT
    c.author_id,
    c.message,
    c.message_id,
    c.thread_id,
    c.file_thread_id,                      -- [ft] expose thread membership
    c.attachment,
    c.status,
    c.ctime,
    c.metadata,
    firstname, lastname, CONCAT(firstname, ' ', lastname) fullname,
    CASE WHEN JSON_EXISTS(metadata, CONCAT("$._seen_.", _uid))= 1 THEN 1 ELSE 0 END is_readed,
    CASE WHEN JSON_LENGTH(metadata , '$._seen_')  =  JSON_LENGTH(metadata , '$._delivered_')
    THEN  1 ELSE 0 END is_seen
  FROM channel c INNER JOIN(yp.drumate d)
  ON author_id=d.id
  WHERE c.file_thread_id IS NULL           -- [ft] hide file-thread replies from main list
  ORDER BY
    CASE WHEN LCASE(_sort_by) = 'date' and LCASE(_order) = 'asc' THEN ctime END ASC,
    CASE WHEN LCASE(_sort_by) = 'date' and LCASE(_order) = 'desc' THEN ctime END DESC,
    CASE WHEN LCASE(_sort_by) = 'name' and LCASE(_order) = 'asc' THEN firstname END ASC,
    CASE WHEN LCASE(_sort_by) = 'name' and LCASE(_order) = 'desc' THEN firstname END DESC
  LIMIT _offset, _range;
END$
DELIMITER ;
