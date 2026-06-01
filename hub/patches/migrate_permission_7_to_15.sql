-- Migrate workspace members whose stored permission = 7 (old write/upload level)
-- to permission = 15 (new upload/delete level).
--
-- Background: @drumee/server-essentials ^1.3.0 separated the download bit (4)
-- from the upload/write bit (8). Privilege=7 previously meant write/upload
-- (anon=1 + read=2 + write=4). After the change, privilege=7 means
-- download-only (anon=1 + read=2 + download=4). The new upload/delete level
-- is privilege=15 (anon=1 + read=2 + download=4 + upload=8).
--
-- Users who had write/upload access (7) must be bumped to 15 so they retain
-- that access after the constants change. Admin (31) and owner (63) rows are
-- unaffected — they already have all lower bits set.
--
-- Run against: all hub DBs  (bin/patch-from-file <this-file> hub)

UPDATE permission
  SET permission = 15, utime = UNIX_TIMESTAMP()
  WHERE permission = 7;
