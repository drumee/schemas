-- =========================================================
-- Add oauth_state.utm_* — the campaign an OAuth signup arrived on.
--
-- Exactly the problem 2026-08-11-oauth-state-ref.sql solved for the
-- referral handle, and left unsolved for everything beside it. The
-- signup UI captures utm_* in browser storage; the OAuth callback runs
-- server-side, and the visitor is bounced out to Google/Apple in
-- between, so browser storage is unreachable when the account is
-- finally created. The referral handle survives that round trip
-- because initiate parks it here. The campaign did not survive it,
-- because there was nowhere to put it.
--
-- The consequence was not a wrong number, it was an invisible one: a
-- visitor who clicked a campaign link and then signed in with Google
-- was recorded as organic, and nothing anywhere said otherwise.
--
-- FOUR COLUMNS, not one JSON blob. `ref` beside them is a column, the
-- analytics side reads these by name (distribution_signups groups on
-- campaign and source), and a blob would have to be parsed in three
-- places to answer what a column answers directly.
--
-- Sized and collated to match `ref` and the tags everywhere else: the
-- capture points trim and truncate to 64 characters before storing,
-- and the UTM builder lowercases every tag it writes.
--
-- NULLable with no default. A row written without them means "this
-- signup came from no campaign", which is the common case and what
-- the callback's guards already expect.
--
-- ADD COLUMN IF NOT EXISTS, so this is safe to replay and safe to run
-- on an instance that already has some of them.
-- =========================================================

ALTER TABLE `oauth_state`
  ADD COLUMN IF NOT EXISTS `utm_source` varchar(64)
    CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL
    COMMENT 'utm_source captured at initiate, read back at callback' AFTER `ref`,
  ADD COLUMN IF NOT EXISTS `utm_medium` varchar(64)
    CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL
    COMMENT 'utm_medium captured at initiate, read back at callback' AFTER `utm_source`,
  ADD COLUMN IF NOT EXISTS `utm_campaign` varchar(64)
    CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL
    COMMENT 'utm_campaign captured at initiate, read back at callback' AFTER `utm_medium`,
  ADD COLUMN IF NOT EXISTS `utm_content` varchar(64)
    CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL
    COMMENT 'utm_content captured at initiate, read back at callback' AFTER `utm_campaign`;
