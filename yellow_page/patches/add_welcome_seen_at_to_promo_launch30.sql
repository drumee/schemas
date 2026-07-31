-- LAUNCH30 Modal B ("Welcome to Team") must show exactly once, right after
-- the payer lands on the new org domain post-claim — the automatic domain
-- redirect (org_provision moves the session to a new vhost) fires too fast
-- for the client to reliably show Modal B before the page navigates away
-- (tester feedback 2026-07-31: modal flashed then the page went blank
-- mid-transition). Fix: stop trying to show it on the old domain, and
-- instead have the new domain's first home mount auto-show it once, driven
-- by this server flag — same "seen once, forever, not localStorage" model
-- as home_seen_at/billing_seen_at.
ALTER TABLE `promo_launch30`
  ADD COLUMN IF NOT EXISTS `welcome_seen_at` int(11) unsigned DEFAULT NULL AFTER `billing_seen_at`;
