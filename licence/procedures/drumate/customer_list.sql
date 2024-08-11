
DELIMITER $

DROP PROCEDURE IF EXISTS `customer_list`$
CREATE PROCEDURE `customer_list`(
  IN _args JSON
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  DECLARE _order VARCHAR(16) CHARACTER SET ascii;
  DECLARE _field VARCHAR(128) CHARACTER SET ascii;
  DECLARE _page INTEGER;

  SELECT IFNULL(JSON_VALUE(_args, '$.order'), 'ASC') INTO _order;
  SELECT IFNULL(JSON_VALUE(_args, '$.field'), 'atime') INTO _field;
  SELECT IFNULL(JSON_VALUE(_args, '$.page'), 1) INTO _page;

  CALL yp.pageToLimits(_page, _offset, _range);  

  SELECT *,
    IF(firstname=lastname, lastname, fullname) AS `filename`,
    'customer' AS filetype,
    'customer' AS `type`
    FROM customer 
  ORDER BY 
    CASE WHEN LCASE(_field) = 'ctime' and LCASE(_order) = 'asc' THEN ctime END ASC,
    CASE WHEN LCASE(_field) = 'ctime' and LCASE(_order) = 'desc' THEN ctime END DESC,
    CASE WHEN LCASE(_field) = 'lastname' and LCASE(_order) = 'asc' THEN lastname END ASC,
    CASE WHEN LCASE(_field) = 'lastname' and LCASE(_order) = 'desc' THEN lastname END DESC,
    CASE WHEN LCASE(_field) = 'firstname' and LCASE(_order) = 'asc' THEN firstname END ASC,
    CASE WHEN LCASE(_field) = 'firstname' and LCASE(_order) = 'desc' THEN firstname END DESC,
    CASE WHEN LCASE(_field) = 'email' and LCASE(_order) = 'asc' THEN email END ASC,
    CASE WHEN LCASE(_field) = 'email' and LCASE(_order) = 'desc' THEN email END DESC
    LIMIT _offset ,_range;

END$


DELIMITER ;

