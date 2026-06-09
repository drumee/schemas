-- =========================================================
-- Email-verification columns on drumate.
-- These are defined in yellow_page/tables/tables.sql but were
-- missing on live instances; this idempotent patch adds them.
-- Required by: drumate_set_verification_token,
--              drumate_verify_email_token, drumate_verify_email.
-- =========================================================
ALTER TABLE `drumate`
  ADD COLUMN IF NOT EXISTS `registration_verified` INT(4) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS `unverified_email` VARCHAR(255) DEFAULT NULL;
