DELIMITER $

-- =========================================================
-- org_over_limit_set
-- Records the org's downgrade over-limit state in
-- organisation.metadata.$.over_limit (JSON home shared with the
-- versioning retention policy, organisation_set_retention).
--
-- Two INDEPENDENT flags (storage / seats) — never collapsed
-- into one boolean: if storage clears first, seats alone must
-- keep the workspace locked, and vice versa.
--
-- The whole $.over_limit object is rebuilt with JSON_OBJECT and
-- written at the single-level path '$.over_limit' ON PURPOSE:
-- JSON_SET only auto-creates the LAST leg of a path, so setting
-- '$.over_limit.state' on a metadata that has no $.over_limit
-- yet is a silent no-op (found the hard way on stage). Fields
-- that must survive re-evaluation (since, grace_deadline,
-- hard_locked_at, snooze) are read back from the pre-update
-- column value inside the same statement.
--
-- Transition rules (the caller computes the flags, this proc
-- owns the state machine so it is atomic under concurrent
-- webhook deliveries):
--   * both flags 0  -> $.over_limit removed entirely; returns
--                      prev_state so the caller can tell a real
--                      resolution (over_limit->ok) from a no-op.
--   * any flag 1    -> state stays 'hard_lock' if it already
--                      was (a re-evaluation never un-hard-locks
--                      by itself — only full resolution does),
--                      otherwise 'over_limit'.
--   * grace_deadline is set ONCE, on the ok->over_limit
--     transition, and NEVER moved by later evaluations — a
--     duplicate webhook, a partial fix or a second downgrade
--     must not extend (or shrink) the grace window.
--   * flags + usage/limit numbers are refreshed on every call
--     so the popup/banner always shows current overage.
-- =========================================================
DROP PROCEDURE IF EXISTS `org_over_limit_set`$
CREATE PROCEDURE `org_over_limit_set`(
  IN _org_id VARCHAR(16) CHARACTER SET ascii,
  IN _storage_over TINYINT,
  IN _seats_over TINYINT,
  IN _grace_seconds INT,
  IN _disk_used BIGINT UNSIGNED,
  IN _disk_limit BIGINT UNSIGNED,
  IN _seats_used INT,
  IN _seat_limit INT,
  IN _plan VARCHAR(80) CHARACTER SET ascii
)
BEGIN
  DECLARE _prev VARCHAR(16) DEFAULT NULL;

  SELECT JSON_UNQUOTE(JSON_VALUE(metadata, '$.over_limit.state'))
  FROM organisation WHERE id = _org_id
  INTO _prev;

  IF IFNULL(_storage_over, 0) = 0 AND IFNULL(_seats_over, 0) = 0 THEN
    -- Fully within limits: drop the whole block (snooze map included —
    -- a future, unrelated downgrade starts clean).
    UPDATE organisation
    SET metadata = JSON_REMOVE(
      IF(metadata IS NULL OR metadata = '' OR NOT JSON_VALID(metadata), '{}', metadata),
      '$.over_limit'
    )
    WHERE id = _org_id;

    SELECT _prev AS prev_state, 'ok' AS state,
           0 AS storage_over, 0 AS seats_over,
           NULL AS grace_deadline;
  ELSE
    UPDATE organisation
    SET metadata = JSON_SET(
      IF(metadata IS NULL OR metadata = '' OR NOT JSON_VALID(metadata), '{}', metadata),
      '$.over_limit',
      JSON_OBJECT(
        'state', IF(_prev = 'hard_lock', 'hard_lock', 'over_limit'),
        'flags', JSON_OBJECT(
          'storage', IF(IFNULL(_storage_over, 0) > 0, 1, 0),
          'seats',   IF(IFNULL(_seats_over, 0) > 0, 1, 0)
        ),
        'disk_used',  IFNULL(_disk_used, 0),
        'disk_limit', IFNULL(_disk_limit, 0),
        'seats_used', IFNULL(_seats_used, 0),
        'seat_limit', IFNULL(_seat_limit, 0),
        'plan', IFNULL(_plan, ''),
        'since',
          IF(_prev IN ('over_limit', 'hard_lock'),
             CAST(IFNULL(JSON_VALUE(metadata, '$.over_limit.since'), UNIX_TIMESTAMP()) AS UNSIGNED),
             UNIX_TIMESTAMP()),
        'grace_deadline',
          IF(_prev IN ('over_limit', 'hard_lock'),
             CAST(IFNULL(JSON_VALUE(metadata, '$.over_limit.grace_deadline'),
                         UNIX_TIMESTAMP() + IFNULL(_grace_seconds, 604800)) AS UNSIGNED),
             UNIX_TIMESTAMP() + IFNULL(_grace_seconds, 604800)),
        'hard_locked_at',
          CAST(IFNULL(JSON_VALUE(metadata, '$.over_limit.hard_locked_at'), 0) AS UNSIGNED),
        'snooze',
          IFNULL(JSON_QUERY(metadata, '$.over_limit.snooze'), JSON_OBJECT())
      )
    )
    WHERE id = _org_id;

    SELECT _prev AS prev_state,
           JSON_UNQUOTE(JSON_VALUE(metadata, '$.over_limit.state')) AS state,
           CAST(JSON_VALUE(metadata, '$.over_limit.flags.storage') AS UNSIGNED) AS storage_over,
           CAST(JSON_VALUE(metadata, '$.over_limit.flags.seats') AS UNSIGNED) AS seats_over,
           CAST(JSON_VALUE(metadata, '$.over_limit.grace_deadline') AS UNSIGNED) AS grace_deadline
    FROM organisation WHERE id = _org_id;
  END IF;
END $

DELIMITER ;
