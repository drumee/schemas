-- =========================================================
-- get_visitor
-- =========================================================
DELIMITER $

DROP PROCEDURE IF EXISTS `get_tutorial`$
CREATE PROCEDURE `get_tutorial`(
  _key  varchar(512)
)
BEGIN
  SELECT * FROM tutorial WHERE `name`=_key;
END$

DELIMITER ;