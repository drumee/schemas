DELIMITER $

-- #########################################################
--
-- SEO SECTION
--
-- #########################################################

--
-- =========================================================
DROP PROCEDURE IF EXISTS `get_seo`$
CREATE PROCEDURE `get_seo`(
  IN _key VARCHAR(512)
)
BEGIN
  IF _key IS NULL OR _key='' THEN
    SELECT * FROM seo limit 100;
  ELSE
    SELECT * FROM seo WHERE hashtag is NULL or hashtag='' limit 100;
  END IF;
END $
