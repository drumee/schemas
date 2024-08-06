DELIMITER $
-- =========================================================
-- Get offset and range from page number
-- =========================================================
DROP PROCEDURE IF EXISTS `pageToLimits`$
CREATE PROCEDURE `pageToLimits`(
  IN _page VARCHAR(32),
  OUT _offset BIGINT,
  OUT _range BIGINT
)
BEGIN
  IF @rows_per_page IS NULL THEN
    SET @rows_per_page=20;
  END IF;
  SELECT (_page - 1)*@rows_per_page, @rows_per_page INTO _offset,_range;
END $

DELIMITER ;
