-- =========================================================
-- drumate_tutorial_seen
--
-- Records that a user has been shown one contextual tutorial tour, and
-- returns the whole seen-map.
--
-- The map lives at `entity.settings.$.tutorials_seen` as
-- {"<tour_id>": <unix seconds>}. Tour ids are validated by the caller
-- (service/private/drumate.js tutorial_seen) against an allow-list that must
-- stay in sync with acl/drumate.json and ui-team
-- src/drumee/modules/desk/tutorial/tours.js.
--
-- Two properties this procedure exists to provide, neither of which
-- drumate.update_settings can give:
--
--   atomic   one UPDATE merging into the CURRENT column value, so two
--            sessions recording two different tours both survive.
--            update_settings read-modify-writes from a session snapshot
--            and loses one of them.
--   idempotent  the `IS NULL` predicate makes it first-write-wins: a repeat
--            for the same tour matches zero rows and still returns the map,
--            never an error the client has to special-case.
--
-- `entity.settings` is mediumtext, not a native JSON column, and may hold ''
-- on an untouched row — hence the JSON_VALID guard on every read of it.
-- =========================================================

DELIMITER $

DROP PROCEDURE IF EXISTS `drumate_tutorial_seen`$
CREATE PROCEDURE `drumate_tutorial_seen`(
  IN _id      VARCHAR(16),
  IN _tour_id VARCHAR(32),
  IN _reset   TINYINT
)
BEGIN
  -- UNIX_TIMESTAMP() is inlined into JSON_OBJECT rather than read from a
  -- DECLAREd variable. A routine variable loses its numeric type on the way
  -- through JSON_OBJECT — every integer type tested (INT, INT UNSIGNED,
  -- BIGINT) writes {"migrate": "1787093945"}, a JSON STRING, while the bare
  -- function call writes {"migrate": 1787093945}. The map is meant to hold
  -- unix seconds a report can compare numerically, so the string form is
  -- wrong even though both round-trip through the client unchanged.

  IF _reset = 1 THEN
    -- QA reset (dev-gated in the service layer). Empties the map and drops
    -- the legacy monolithic-tour flag, so every tour becomes triggerable
    -- again on the same account.
    UPDATE entity
       SET settings = JSON_REMOVE(
             JSON_SET(
               IF(JSON_VALID(settings), settings, '{}'),
               '$.tutorials_seen', JSON_OBJECT()
             ),
             '$.tutorial_done'
           )
     WHERE id = _id;

  ELSEIF _tour_id IS NOT NULL AND _tour_id <> '' THEN
    UPDATE entity
       SET settings = JSON_MERGE_PATCH(
             IF(JSON_VALID(settings), settings, '{}'),
             JSON_OBJECT('tutorials_seen', JSON_OBJECT(_tour_id, UNIX_TIMESTAMP()))
           )
     WHERE id = _id
       AND JSON_EXTRACT(
             IF(JSON_VALID(settings), settings, '{}'),
             CONCAT('$.tutorials_seen."', _tour_id, '"')
           ) IS NULL;
  END IF;

  SELECT
    IFNULL(
      JSON_EXTRACT(IF(JSON_VALID(settings), settings, '{}'), '$.tutorials_seen'),
      JSON_OBJECT()
    ) AS tutorials_seen
    FROM entity WHERE id = _id;
END $

DELIMITER ;
