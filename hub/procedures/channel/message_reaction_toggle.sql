-- File: schemas/hub/procedures/channel/message_reaction_toggle.sql
-- =========================================================
-- message_reaction_toggle  (HUB class — team chat + folder window)
-- ONE reaction per user per message: a user holds at most one emoji.
--   - Picking the user's current emoji again  -> remove it (toggle off).
--   - Picking a different emoji               -> move the user to it (replace).
-- Stored per-message in `channel`.metadata under `_reactions_`:
--   { "<emoji>": ["<uid>", ...] }. Only the _reactions_ subpath is touched,
-- so read-receipts (`_seen_`) and other metadata keys are preserved.
--
-- All writes operate DIRECTLY on `_meta` via JSON_REMOVE / JSON_ARRAY_APPEND /
-- JSON_SET(..., JSON_ARRAY()). We never JSON_SET a string variable as the value
-- (that double-encodes the sub-object into a quoted string). Atomic under
-- concurrency (transaction + FOR UPDATE). Requires MariaDB 10.2.3+. Caller
-- (service) validates emoji: single glyph, no quote/backslash/whitespace; uids
-- are 16-char ascii hex (safe for the JSON_SEARCH removal below).
--
-- Returns one row: found (0 if message absent), capped (1 if a new emoji hit
-- the distinct cap), reactions (the updated map as a JSON object).
--
-- Apply (DEV/STAGE ONLY — every hub instance on the server):
--   bin/patch-from-file patches/message-reaction-toggle.sql hub
-- =========================================================
DELIMITER $

DROP PROCEDURE IF EXISTS `message_reaction_toggle`$
CREATE PROCEDURE `message_reaction_toggle`(
  IN _message_id VARCHAR(16) CHARACTER SET ascii,
  IN _uid VARCHAR(16) CHARACTER SET ascii,
  IN _emoji VARCHAR(64) CHARACTER SET utf8mb4
)
BEGIN
  DECLARE _meta LONGTEXT;
  DECLARE _keys LONGTEXT;
  DECLARE _arr LONGTEXT;
  DECLARE _key VARCHAR(64) CHARACTER SET utf8mb4;
  DECLARE _kpath VARCHAR(160);
  DECLARE _epath VARCHAR(160);
  DECLARE _hit VARCHAR(64);
  DECLARE _n INT DEFAULT 0;
  DECLARE _k INT DEFAULT 0;
  DECLARE _was_mine INT DEFAULT 0;
  DECLARE _capped INT DEFAULT 0;
  DECLARE _exists INT DEFAULT 0;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  SET _epath = CONCAT('$._reactions_."', _emoji, '"');

  START TRANSACTION;
  SELECT COUNT(1) INTO _exists FROM `channel` WHERE message_id = _message_id;

  IF _exists = 0 THEN
    COMMIT;
    SELECT 0 AS found, 0 AS capped, JSON_OBJECT() AS reactions;
  ELSE
    SELECT metadata INTO _meta FROM `channel` WHERE message_id = _message_id FOR UPDATE;
    SET _meta = COALESCE(NULLIF(_meta, ''), '{}');
    IF JSON_EXTRACT(_meta, '$._reactions_') IS NULL THEN
      SET _meta = JSON_SET(_meta, '$._reactions_', JSON_OBJECT());
    END IF;

    -- Remove _uid from EVERY emoji array (one-per-user; also normalises any
    -- legacy state where the user sat on multiple emojis). Operates on _meta
    -- directly so nothing is re-encoded as a string.
    SET _keys = COALESCE(JSON_KEYS(JSON_EXTRACT(_meta, '$._reactions_')), JSON_ARRAY());
    SET _n = JSON_LENGTH(_keys);
    SET _k = 0;
    WHILE _k < _n DO
      SET _key = JSON_UNQUOTE(JSON_EXTRACT(_keys, CONCAT('$[', _k, ']')));
      SET _kpath = CONCAT('$._reactions_."', _key, '"');
      SET _arr = JSON_EXTRACT(_meta, _kpath);
      IF _arr IS NOT NULL AND JSON_CONTAINS(_arr, JSON_QUOTE(_uid)) THEN
        -- Compare emojis with BINARY collation. The connection's default
        -- utf8mb4_general_ci treats DISTINCT emojis as EQUAL ('👍' = '😮' is
        -- TRUE), which made a switch (react 👍, then pick 😮) look like a
        -- toggle-off: _was_mine was set, the old emoji was removed, and the new
        -- one was NEVER added until a second call. utf8mb4_bin keeps same-emoji
        -- equal (toggle-off still works) while distinguishing different emojis.
        IF _key = _emoji COLLATE utf8mb4_bin THEN SET _was_mine = 1; END IF;
        SET _hit = JSON_UNQUOTE(JSON_SEARCH(_arr, 'one', _uid));
        IF _hit IS NOT NULL THEN
          SET _meta = JSON_REMOVE(_meta, CONCAT(_kpath, SUBSTR(_hit, 2)));
        END IF;
        IF JSON_LENGTH(JSON_EXTRACT(_meta, _kpath)) = 0 THEN
          SET _meta = JSON_REMOVE(_meta, _kpath);
        END IF;
      END IF;
      SET _k = _k + 1;
    END WHILE;

    -- Re-add the user to the chosen emoji unless they toggled the same one off.
    IF _was_mine = 0 THEN
      IF JSON_EXTRACT(_meta, _epath) IS NULL THEN
        IF JSON_LENGTH(JSON_EXTRACT(_meta, '$._reactions_')) < 50 THEN
          SET _meta = JSON_SET(_meta, _epath, JSON_ARRAY(_uid));
        ELSE
          SET _capped = 1;
        END IF;
      ELSE
        SET _meta = JSON_ARRAY_APPEND(_meta, _epath, _uid);
      END IF;
    END IF;

    UPDATE `channel` SET metadata = _meta WHERE message_id = _message_id;
    COMMIT;
    SELECT 1 AS found, _capped AS capped,
           COALESCE(JSON_EXTRACT(_meta, '$._reactions_'), JSON_OBJECT()) AS reactions;
  END IF;
END $

DELIMITER ;
