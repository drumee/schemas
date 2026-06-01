-- Migrate hub membership permission rows whose stored permission = 7
-- (old write/upload level) to permission = 15 (new upload/delete level).
--
-- Companion to hub/patches/migrate_permission_7_to_15.sql — see that file
-- for full background. Drumate DBs store a permission row for each hub the
-- user belongs to; if members_set_privilege(7) was ever called, those rows
-- also contain permission=7 and must be migrated.
--
-- Run against: all drumate DBs  (bin/patch-from-file <this-file> drumate)

UPDATE permission
  SET permission = 15, utime = UNIX_TIMESTAMP()
  WHERE permission = 7;
