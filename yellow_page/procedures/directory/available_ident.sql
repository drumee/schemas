DELIMITER $

DROP PROCEDURE IF EXISTS `available_ident`$
CREATE PROCEDURE `available_ident`(
  IN _key VARCHAR(84)
)
BEGIN
  SELECT _key AS ident, (SELECT NOT EXISTS (SELECT ident FROM entity WHERE ident=_key)) AS available;
END $


DELIMITER ;
