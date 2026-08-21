DELIMITER $

-- =========================================================
-- mkt_link_archive
--
-- Archiving is a FLAG, never a DELETE. An archived link is still printed on a
-- flyer and still in someone's scheduled post; the row has to survive so its
-- arrivals keep resolving to a campaign instead of falling into (none).
-- Reversible on purpose — the registry UI offers Restore.
-- =========================================================
DROP PROCEDURE IF EXISTS `mkt_link_archive`$
CREATE PROCEDURE `mkt_link_archive`(
  IN _id       INT,
  IN _archived TINYINT
)
BEGIN
  IF NOT EXISTS (SELECT 1 FROM mkt_campaign_link WHERE id = _id) THEN
    SELECT 'LINK_NOT_FOUND' AS error, _id AS id;
  ELSE
    UPDATE mkt_campaign_link
       SET archived = IF(_archived = 1, 1, 0),
           mtime = UNIX_TIMESTAMP()
     WHERE id = _id;
    SELECT * FROM mkt_campaign_link WHERE id = _id;
  END IF;
END $

DELIMITER ;
