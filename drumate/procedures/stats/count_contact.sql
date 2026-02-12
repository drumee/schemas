-- Hub procedure: count contacts by user (aligned with drumate contact_summary)
-- Deploy to each user database (same as count_media, count_folders)
-- Used by reward-hub OT6 verification
-- contact_summary: status IN ('active','informed','accept') - no uid filter (each drumate db = one user's contacts)
-- IN _in JSON: { uid } - optional, unused for count (contact table in user db = that user's contacts)
-- Returns: cnt
DELIMITER $$

DROP PROCEDURE IF EXISTS `count_contact`$$
CREATE PROCEDURE `count_contact`(
  IN _in JSON
)
BEGIN
  -- contact_summary logic: status IN ('active','informed','accept')
  -- Each drumate db contains only that user's contacts
  SELECT COUNT(*) as cnt
  FROM contact
  WHERE status IN ('active', 'informed', 'accept')
  LIMIT 1;
END$$

DELIMITER ;
