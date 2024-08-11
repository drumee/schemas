
DELIMITER $

DROP PROCEDURE IF EXISTS `customer_contact_search`$
CREATE PROCEDURE `customer_contact_search`(
 IN _args JSON
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  DECLARE _order VARCHAR(16) CHARACTER SET ascii;
  DECLARE _field VARCHAR(128) CHARACTER SET ascii;
  DECLARE _page INTEGER;
  DECLARE _string VARCHAR(1000) CHARACTER SET ascii;

  SELECT IFNULL(JSON_VALUE(_args, '$.order'), 'ASC') INTO _order;
  SELECT IFNULL(JSON_VALUE(_args, '$.field'), 'atime') INTO _field;
  SELECT IFNULL(JSON_VALUE(_args, '$.string'), 'legal_name') INTO _string;
  SELECT IFNULL(JSON_VALUE(_args, '$.page'), 1) INTO _page;

  CALL yp.pageToLimits(_page, _offset, _range);  
  SET @pattern = CONCAT("%", _string, '%');

  SELECT id,
    id contact_id,
    firstname,
    lastname,
    IF(entity = source, NULL, entity) AS drumate_id,
    ctime,
    source AS email,
    TRIM(IF(firstname=lastname, firstname, CONCAT(IFNULL(firstname, ''), " ", IFNULL(lastname, '')))) AS `filename`,
    'contact' AS filetype
  FROM contact WHERE
    (firstname LIKE @pattern OR lastname LIKE @pattern OR source LIKE @pattern)
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