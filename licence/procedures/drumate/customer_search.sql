
DELIMITER $

DROP PROCEDURE IF EXISTS `customer_search`$
CREATE PROCEDURE `customer_search`(
 IN _args JSON
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  DECLARE _order VARCHAR(16) CHARACTER SET ascii;
  DECLARE _string VARCHAR(1000) CHARACTER SET ascii;
  DECLARE _page INTEGER;

  SELECT IFNULL(JSON_VALUE(_args, '$.order'), 'ASC') INTO _order;
  SELECT IFNULL(JSON_VALUE(_args, '$.string'), 'legal_name') INTO _string;
  SELECT IFNULL(JSON_VALUE(_args, '$.page'), 1) INTO _page;

  CALL yp.pageToLimits(_page, _offset, _range);  

  SET @pattern = CONCAT("%", _string, '%');
  DROP TABLE IF EXISTS _found;

  CREATE TABLE _found AS 
  SELECT id,
    id contact_id,
    firstname,
    lastname,
    IF(entity = source, NULL, entity) AS drumate_id,
    ctime,
    source AS email,
    NULL bu_id,
    NULL customer_id,
    0 isCustomer
  FROM contact WHERE source NOT IN (SELECT email FROM customer) AND 
    (firstname LIKE @pattern OR lastname LIKE @pattern OR source LIKE @pattern)
  UNION ALL
  SELECT id,
    NULL contact_id,
    firstname,
    lastname,
    (SELECT id FROM yp.drumate d WHERE d.email = c.email) AS drumate_id,
    ctime,
    email,
    bu_id,
    id customer_id,
    1 isCustomer
  FROM customer c WHERE firstname LIKE @pattern OR 
  lastname LIKE @pattern OR email LIKE @pattern;

  SELECT *,
    TRIM(IF(firstname=lastname, firstname, CONCAT(IFNULL(firstname, ''), " ", IFNULL(lastname, '')))) AS `filename`,
    IF(isCustomer, 'customer', 'contact') AS filetype
  FROM _found;
  DROP TABLE IF EXISTS _found;
END$

DELIMITER ;