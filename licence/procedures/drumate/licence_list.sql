
DELIMITER $

DROP PROCEDURE IF EXISTS `licence_list`$
CREATE PROCEDURE `licence_list`(
  IN _args JSON
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  DECLARE _order VARCHAR(16) CHARACTER SET ascii;
  DECLARE _field VARCHAR(128) CHARACTER SET ascii;
  DECLARE _page INTEGER;
  DECLARE _reseller_id VARCHAR(16) DEFAULT NULL;

  SELECT IFNULL(JSON_VALUE(_args, '$.order'), 'ASC') INTO _order;
  SELECT IFNULL(JSON_VALUE(_args, '$.field'), 'atime') INTO _field;
  SELECT IFNULL(JSON_VALUE(_args, '$.page'), 1) INTO _page;

  CALL yp.pageToLimits(_page, _offset, _range);  
  SELECT id FROM yp.entity WHERE db_name=database() 
    INTO _reseller_id ;

  SELECT 
    l.id,
    l.id nid,
    l.key,
    l.domain,
    l.customer_id,
    l.reseller_id,
    l.ctime ctime, 
    l.atime atime,
    l.capacity number_of_bays,
    l.status,
    l.unit,
    l.signature,
    CONCAT ('/', domain) filepath,
    'drumeeLicence' filetype,
    l.domain `filename`,
    c.fullname,
    c.email,
    c.firstname,
    c.lastname
    FROM customer c INNER JOIN licence.licence l  
      ON l.customer_id=c.id WHERE l.reseller_id = _reseller_id
  ORDER BY 
    CASE WHEN LCASE(_field) = 'ctime' and LCASE(_order) = 'asc' THEN l.ctime END ASC,
    CASE WHEN LCASE(_field) = 'ctime' and LCASE(_order) = 'desc' THEN l.ctime END DESC,
    CASE WHEN LCASE(_field) = 'atime' and LCASE(_order) = 'asc' THEN atime END ASC,
    CASE WHEN LCASE(_field) = 'atime' and LCASE(_order) = 'desc' THEN atime END DESC,
    CASE WHEN LCASE(_field) = 'lastname' and LCASE(_order) = 'asc' THEN lastname END ASC,
    CASE WHEN LCASE(_field) = 'lastname' and LCASE(_order) = 'desc' THEN atime END DESC,
    CASE WHEN LCASE(_field) = 'domain' and LCASE(_order) = 'asc' THEN domain END ASC,
    CASE WHEN LCASE(_field) = 'domain' and LCASE(_order) = 'desc' THEN domain END DESC,
    CASE WHEN LCASE(_field) = 'email' and LCASE(_order) = 'asc' THEN email END ASC,
    CASE WHEN LCASE(_field) = 'email' and LCASE(_order) = 'desc' THEN email END DESC
    LIMIT _offset ,_range;

END$


DELIMITER ;

