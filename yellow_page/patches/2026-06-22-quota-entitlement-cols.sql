-- yp.quota keeps its (domain_id,payer_id) key + quota JSON ($.disk drives the VIRTUAL `disk` col + enforcement).
-- Add provenance + expiry so the reducer/UI know where entitlement came from and when it lapses.
-- ADDITIVE only — NEVER DROP+CREATE yp.quota (holds rows + quota_usage FK + disk_usage trigger).
ALTER TABLE `quota`
  ADD COLUMN IF NOT EXISTS `source` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT 'free',
  ADD COLUMN IF NOT EXISTS `period_end` int(11) unsigned DEFAULT NULL;
