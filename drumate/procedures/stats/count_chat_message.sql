-- Hub procedure: count chat messages by user (any chat: team or private)
-- Deploy to each hub database (same schema as list_message)
-- Used by reward-hub OT5 verification
DELIMITER $$

DROP PROCEDURE IF EXISTS `count_chat_message`$$
CREATE PROCEDURE `count_chat_message`(
  IN _in JSON
)
BEGIN
  DECLARE _uid VARCHAR(16) CHARACTER SET ascii;

  SELECT JSON_UNQUOTE(JSON_EXTRACT(_in, "$.uid")) INTO _uid;

  -- If uid not provided, get from current database context (same as list_message)
  IF _uid IS NULL OR CHAR_LENGTH(TRIM(COALESCE(_uid, ''))) = 0 THEN
    SELECT id FROM yp.entity WHERE db_name = DATABASE() INTO _uid;
  END IF;

  -- Count all messages where author_id = uid (team + private)
  SELECT COUNT(*) as cnt
  FROM channel c
  WHERE c.author_id = _uid
  LIMIT 1;
END$$

DELIMITER ;
