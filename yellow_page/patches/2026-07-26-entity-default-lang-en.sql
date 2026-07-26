-- Product default language is ENGLISH. yp.entity.default_lang defaulted to
-- 'fr', and drumate_create never overrides it, so every entity (drumate,
-- hub, organization) was stamped French at creation. get_hub returns the
-- column into the client env, and the CMS page/block services use it as
-- their content-language default — public pages fell back to French.
--
-- Column default only: existing rows are NOT rewritten. The seeded 'fr' in
-- current rows is indistinguishable from a deliberate French deployment, so
-- flipping rows wholesale is a per-installation decision — run the
-- commented backfill below manually where English is known to be right.
ALTER TABLE entity
  ALTER COLUMN default_lang SET DEFAULT 'en';

-- Optional per-installation backfill (NOT run automatically):
-- UPDATE entity SET default_lang = 'en' WHERE default_lang = 'fr';
