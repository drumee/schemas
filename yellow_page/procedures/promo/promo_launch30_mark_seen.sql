DELIMITER $

-- =========================================================
-- promo_launch30_mark_seen
-- Records that surface (home | billing | welcome | ended) has shown its
-- modal to this payer, ONCE, forever — a server flag, not
-- localStorage, so clearing cache or switching device does not
-- re-trigger it (design doc 2026-07-30, "the most common bug"
-- call-out). 'welcome' is Modal B, shown once on the new org
-- domain's first home mount right after a claim (tester feedback
-- 2026-07-31 #2/#3) — same one-shot model as home/billing.
-- 'ended' is the trial-ended decision gate and reads slightly
-- differently: it records that the owner ANSWERED (upgrade or
-- continue-free), and it is the only thing that stops that modal
-- reappearing on every home mount. IFNULL keeps a flag already set
-- from moving.
-- =========================================================
DROP PROCEDURE IF EXISTS `promo_launch30_mark_seen`$
CREATE PROCEDURE `promo_launch30_mark_seen`(
  IN _payer_id VARCHAR(16),
  IN _surface VARCHAR(16)
)
BEGIN
  INSERT INTO promo_launch30
    (payer_id, status, home_seen_at, billing_seen_at, welcome_seen_at, ended_seen_at, ctime, mtime)
  VALUES
    (_payer_id, 'unclaimed',
     IF(_surface = 'home', UNIX_TIMESTAMP(), NULL),
     IF(_surface = 'billing', UNIX_TIMESTAMP(), NULL),
     IF(_surface = 'welcome', UNIX_TIMESTAMP(), NULL),
     IF(_surface = 'ended', UNIX_TIMESTAMP(), NULL),
     UNIX_TIMESTAMP(), UNIX_TIMESTAMP())
  ON DUPLICATE KEY UPDATE
    home_seen_at = IF(_surface = 'home', IFNULL(home_seen_at, UNIX_TIMESTAMP()), home_seen_at),
    billing_seen_at = IF(_surface = 'billing', IFNULL(billing_seen_at, UNIX_TIMESTAMP()), billing_seen_at),
    welcome_seen_at = IF(_surface = 'welcome', IFNULL(welcome_seen_at, UNIX_TIMESTAMP()), welcome_seen_at),
    ended_seen_at = IF(_surface = 'ended', IFNULL(ended_seen_at, UNIX_TIMESTAMP()), ended_seen_at),
    mtime = UNIX_TIMESTAMP();

  SELECT status, home_seen_at, billing_seen_at, welcome_seen_at, ended_seen_at
  FROM promo_launch30
  WHERE payer_id = _payer_id
  LIMIT 1;
END $

DELIMITER ;
