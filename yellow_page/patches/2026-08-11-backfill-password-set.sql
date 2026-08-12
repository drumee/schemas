-- =========================================================
-- Backfill profile.password_set for accounts that provably
-- logged in with a password (services_log: yp.login /
-- yp.signin / yp.login_top, success=1). The flag was silently
-- dropped for years by drumate_update_profile's whitelist
-- (fixed alongside this patch), so no historical stamp ever
-- persisted. Accounts without password-login evidence are
-- left untouched: they verify via email OTP until their
-- first password login self-heals the flag.
-- Applied on stage yp 2026-08-11.
-- =========================================================
UPDATE drumate d
JOIN (
  SELECT DISTINCT uid FROM services_log
  WHERE name IN ('yp.login','yp.signin','yp.login_top')
    AND JSON_VALUE(args,'$.success')='1'
    AND uid IS NOT NULL AND uid <> ''
) s ON s.uid = d.id
SET d.profile = JSON_SET(d.profile,'$.password_set',1)
WHERE JSON_VALUE(d.profile,'$.password_set') IS NULL;
