DELIMITER $

-- =========================================================
-- channel_reader_ids
--
-- Everyone who can read this hub's chat right now: an entity holding a live
-- (non-expired, non-zero) permission row in this hub and still backed by an
-- account (drumate or DMZ guest). The chat list uses it to drop stale readers
-- from metadata._seen_ at read time, so a member who left, was removed, lost
-- an expired grant or deleted the account no longer shows as "seen". _seen_
-- itself is left untouched.
-- =========================================================
DROP PROCEDURE IF EXISTS `channel_reader_ids`$
CREATE PROCEDURE `channel_reader_ids`()
BEGIN
  SELECT DISTINCT p.entity_id AS uid
  FROM permission p
  WHERE p.entity_id <> '*'
    AND p.permission > 0
    AND (p.expiry_time = 0 OR p.expiry_time > UNIX_TIMESTAMP())
    AND (
      EXISTS (SELECT 1 FROM yp.drumate d WHERE d.id = p.entity_id)
      OR EXISTS (SELECT 1 FROM yp.dmz_user du WHERE du.id = p.entity_id)
    );
END $

DELIMITER ;
