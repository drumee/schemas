
DELIMITER $

DROP PROCEDURE IF EXISTS `enterprise_search`$
CREATE PROCEDURE `enterprise_search`(
 IN _args JSON
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  DECLARE _order VARCHAR(16) CHARACTER SET ascii;
  DECLARE _field VARCHAR(128) CHARACTER SET ascii;
  DECLARE _string VARCHAR(1000);
  DECLARE _page INTEGER;

  SELECT IFNULL(JSON_VALUE(_args, '$.field'), 'legal_name') INTO _field;
  SELECT IFNULL(JSON_VALUE(_args, '$.page'), 1) INTO _page;
  SELECT IFNULL(JSON_VALUE(_args, '$.order'), 'ASC') INTO _order;
  SELECT IFNULL(JSON_VALUE(_args, '$.string'), 'legal_name') INTO _string;

  CALL yp.pageToLimits(_page, _offset, _range);  

  SET @pattern = CONCAT(_string, '%');
  -- SET @pattern2 = CONCAT(_string, '%');
  SELECT *, 
  'company' filetype,
  IFNULL(commercial_name, legal_name) `filename`, 
  id nid, 
  1 isVirtual 
  FROM enterprise
    WHERE (legal_name LIKE @pattern)
  ORDER BY 
    CASE WHEN LCASE(_field) = 'date_of_start' and LCASE(_order) = 'asc' THEN date_of_start END ASC,
    CASE WHEN LCASE(_field) = 'date_of_start' and LCASE(_order) = 'desc' THEN date_of_start END DESC,
    CASE WHEN LCASE(_field) = 'legal_name' and LCASE(_order) = 'asc' THEN legal_name END ASC,
    CASE WHEN LCASE(_field) = 'legal_name' and LCASE(_order) = 'desc' THEN legal_name END DESC,
    CASE WHEN LCASE(_field) = 'postal_code' and LCASE(_order) = 'asc' THEN postal_code END ASC,
    CASE WHEN LCASE(_field) = 'postal_code' and LCASE(_order) = 'desc' THEN legal_name END DESC,
    CASE WHEN LCASE(_field) = 'district' and LCASE(_order) = 'asc' THEN district END ASC,
    CASE WHEN LCASE(_field) = 'district' and LCASE(_order) = 'desc' THEN district END DESC,
    CASE WHEN LCASE(_field) = 'category' and LCASE(_order) = 'asc' THEN category END ASC,
    CASE WHEN LCASE(_field) = 'category' and LCASE(_order) = 'desc' THEN category END DESC
    LIMIT _offset ,_range;

END$

DELIMITER ;