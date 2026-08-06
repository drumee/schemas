DELIMITER $

-- =========================================================
-- org_over_limit_due
-- Orgs still over limit whose grace deadline has passed and
-- that are not yet hard-locked. Polled by the grace worker
-- (mirrors promo_launch30_due: plain setTimeout self-
-- rescheduler, the runtime ships Bull, not `cron`). Full scan
-- of organisation is fine — the table holds one row per org.
-- =========================================================
DROP PROCEDURE IF EXISTS `org_over_limit_due`$
CREATE PROCEDURE `org_over_limit_due`()
BEGIN
  SELECT
    o.id AS org_id,
    o.domain_id,
    o.owner_id,
    CAST(JSON_VALUE(o.metadata, '$.over_limit.grace_deadline') AS UNSIGNED) AS grace_deadline,
    CAST(IFNULL(JSON_VALUE(o.metadata, '$.over_limit.flags.storage'), 0) AS UNSIGNED) AS storage_over,
    CAST(IFNULL(JSON_VALUE(o.metadata, '$.over_limit.flags.seats'), 0) AS UNSIGNED) AS seats_over
  FROM organisation o
  WHERE JSON_VALUE(o.metadata, '$.over_limit.state') = 'over_limit'
    AND CAST(IFNULL(JSON_VALUE(o.metadata, '$.over_limit.grace_deadline'), 0) AS UNSIGNED)
        < UNIX_TIMESTAMP();
END $

DELIMITER ;
