DELIMITER $
DROP PROCEDURE IF EXISTS `lookup_drumates`$
CREATE PROCEDURE `lookup_drumates`(
  IN _key VARCHAR(255),
  IN _page TINYINT(4)
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  CALL pageToLimits(_page, _offset, _range);
  SELECT 
    _page as `page`,
    d.id,
    e.ident,
    d.firstname,
    d.lastname,
    d.remit,
    email
  FROM entity e INNER JOIN (yp.drumate d) USING(id) 
    WHERE ident 
    LIKE CONCAT(_key, "%") OR 
    email LIKE CONCAT(_key, "%") OR 
    d.firstname LIKE CONCAT(_key, "%") OR 
    d.lastname LIKE CONCAT(_key, "%") ORDER BY d.lastname DESC LIMIT _offset, _range;
END$
DELIMITER ;