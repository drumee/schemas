DELIMITER $

-- =========================================================
-- Adds a color to drumate's used_colors table.
-- =========================================================
DROP PROCEDURE IF EXISTS `color_add`$
CREATE PROCEDURE `color_add`(
   IN _rgba         VARCHAR(50),
   IN _hexacode     VARCHAR(20)
)
BEGIN
  DECLARE _last INT(11) DEFAULT 0;
  INSERT INTO used_colors VALUES (NULL, _rgba, _hexacode, UNIX_TIMESTAMP());
  SELECT LAST_INSERT_ID() INTO _last;
  SELECT sys_id AS color_id, rgba, hexacode, ctime FROM used_colors WHERE sys_id = _last;
END$

-- =========================================================
-- Gets last used colors.
-- =========================================================
DROP PROCEDURE IF EXISTS `color_last`$
CREATE PROCEDURE `color_last`()
BEGIN
  SELECT sys_id AS color_id, rgba, hexacode, ctime FROM used_colors
    WHERE sys_id IN (SELECT MAX(sys_id) FROM used_colors GROUP BY hexacode)
    ORDER BY sys_id DESC LIMIT 7;
END$

DELIMITER ;