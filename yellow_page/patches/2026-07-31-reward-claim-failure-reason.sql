-- =========================================================
-- Give reward_claim somewhere to record a failed delivery.
--
-- The funnel could say a user was mailed but never that the
-- mail bounced. A campaign to 169 addresses reached 152 and was
-- refused for 17 ("550 User unknown in virtual mailbox table" —
-- test accounts with no mailbox), and the dashboard had no way
-- to show the difference between those 17 and the people who
-- were reached and ignored it.
--
-- failed_at / last_error are written by reward_claim_failed and
-- cleared by reward_claim_emailed, so the pair always describes
-- the LAST outcome for that address rather than accumulating
-- history. Both are safe on an existing table: every current
-- row is a delivery that was accepted, which is exactly what
-- 0 / NULL mean.
--
-- 190 chars holds an SMTP reply line with room for the short
-- reason analytics-server prefixes, and stays inside the
-- utf8mb4 index-key limit should this ever need indexing.
-- =========================================================

ALTER TABLE `reward_claim`
  ADD COLUMN IF NOT EXISTS `failed_at` int(11) unsigned NOT NULL DEFAULT 0
    COMMENT 'When the MTA last refused this user''s address; 0 = never'
    AFTER `last_emailed`,
  ADD COLUMN IF NOT EXISTS `last_error` varchar(190) DEFAULT NULL
    COMMENT 'Why the last send to this user failed, e.g. "No such mailbox (550)". NULL once a later send succeeds'
    AFTER `failed_at`;

-- 'failed' is a new value for an existing free-text column, so this only
-- refreshes the documentation of what the column may hold.
ALTER TABLE `reward_claim`
  MODIFY COLUMN `status` varchar(16) NOT NULL DEFAULT 'emailed'
    COMMENT 'emailed | failed | clicked | started | dropped | missed | done';
