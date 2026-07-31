DELIMITER $

-- =========================================================
-- promo_launch30_mark_seen
-- Records that surface (home | billing) has shown Modal A to
-- this payer, ONCE, forever — a server flag, not localStorage,
-- so clearing cache or switching device does not re-trigger it
-- (design doc 2026-07-30, "the most common bug" call-out).
-- IFNULL keeps a flag already set from moving.
-- =========================================================
DROP PROCEDURE IF EXISTS `promo_launch30_mark_seen`$
CREATE PROCEDURE `promo_launch30_mark_seen`(
  IN _payer_id VARCHAR(16),
  IN _surface VARCHAR(16)
)
BEGIN
  INSERT INTO promo_launch30
    (payer_id, status, home_seen_at, billing_seen_at, ctime, mtime)
  VALUES
    (_payer_id, 'unclaimed',
     IF(_surface = 'home', UNIX_TIMESTAMP(), NULL),
     IF(_surface = 'billing', UNIX_TIMESTAMP(), NULL),
     UNIX_TIMESTAMP(), UNIX_TIMESTAMP())
  ON DUPLICATE KEY UPDATE
    home_seen_at = IF(_surface = 'home', IFNULL(home_seen_at, UNIX_TIMESTAMP()), home_seen_at),
    billing_seen_at = IF(_surface = 'billing', IFNULL(billing_seen_at, UNIX_TIMESTAMP()), billing_seen_at),
    mtime = UNIX_TIMESTAMP();

  SELECT status, home_seen_at, billing_seen_at
  FROM promo_launch30
  WHERE payer_id = _payer_id
  LIMIT 1;
END $

DELIMITER ;
