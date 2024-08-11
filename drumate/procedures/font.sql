
DELIMITER $

-- =========================================================
-- Adds a font to drumate's used_fonts table.
-- =========================================================
DROP PROCEDURE IF EXISTS `font_add`$
CREATE PROCEDURE `font_add`(
   IN _name         VARCHAR(200)
)
BEGIN
  DECLARE _last INT(11) DEFAULT 0;
  INSERT INTO used_fonts VALUES (NULL, _name, UNIX_TIMESTAMP());
  SELECT LAST_INSERT_ID() INTO _last;
  SELECT sys_id AS font_id, name, ctime FROM used_fonts WHERE sys_id = _last;
END$

-- =========================================================
-- Gets last used fonts.
-- =========================================================
DROP PROCEDURE IF EXISTS `font_last`$
CREATE PROCEDURE `font_last`()
BEGIN
  SELECT sys_id AS font_id, name, ctime FROM used_fonts
    WHERE sys_id IN (SELECT MAX(sys_id) FROM used_fonts GROUP BY name)
    ORDER BY sys_id DESC LIMIT 3;
END$

DELIMITER ;