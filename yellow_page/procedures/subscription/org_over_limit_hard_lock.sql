DELIMITER $

-- =========================================================
-- org_over_limit_hard_lock
-- Guarded over_limit -> hard_lock flip, run by the grace
-- worker once the deadline has passed. Guarded on BOTH the
-- current state and the stored deadline (same effect-first /
-- status-guarded shape as promo_launch30_mark_expired) so a
-- retried worker tick — or a worker racing a resolution — is
-- a no-op: if the owner resolved in the meantime the state is
-- 'ok'/absent and ROW_COUNT() stays 0.
-- =========================================================
DROP PROCEDURE IF EXISTS `org_over_limit_hard_lock`$
CREATE PROCEDURE `org_over_limit_hard_lock`(
  IN _org_id VARCHAR(16) CHARACTER SET ascii
)
BEGIN
  UPDATE organisation
  SET metadata = JSON_SET(
    metadata,
    '$.over_limit.state', 'hard_lock',
    '$.over_limit.hard_locked_at', UNIX_TIMESTAMP()
  )
  WHERE id = _org_id
    AND JSON_VALUE(metadata, '$.over_limit.state') = 'over_limit'
    AND CAST(IFNULL(JSON_VALUE(metadata, '$.over_limit.grace_deadline'), 0) AS UNSIGNED)
        <= UNIX_TIMESTAMP();

  SELECT ROW_COUNT() AS locked;
END $

DELIMITER ;
