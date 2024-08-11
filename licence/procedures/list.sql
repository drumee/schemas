
DELIMITER $



DROP PROCEDURE IF EXISTS `list`$
CREATE PROCEDURE `list`(
  IN _uid VARCHAR(16) CHARACTER SET ascii,
  IN _sort_by VARCHAR(20),
  IN _order   VARCHAR(20),
  IN _page    TINYINT(4)
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  SELECT *, 
    ctime, 
    atime, 
    CONCAT ('/', domain) filepath,
    domain `filename`
    FROM licence WHERE reseller_id=_uid;
  --   ORDER BY 
  --   CASE WHEN LCASE(_sort_by) = 'start' and LCASE(_order) = 'asc' THEN `start` END ASC,
  --   CASE WHEN LCASE(_sort_by) = 'start' and LCASE(_order) = 'desc' THEN `start` END DESC,
  --   CASE WHEN LCASE(_sort_by) = 'domain' and LCASE(_order) = 'asc' THEN `domain` END ASC,
  --   CASE WHEN LCASE(_sort_by) = 'domain' and LCASE(_order) = 'desc' THEN `domain` END DESC,
  --   CASE WHEN LCASE(_sort_by) = 'end' and LCASE(_order) = 'asc' THEN `end` END ASC,
  --   CASE WHEN LCASE(_sort_by) = 'end' and LCASE(_order) = 'desc' THEN `end` END DESC,
  --   CASE WHEN LCASE(_sort_by) = 'status' and LCASE(_order) = 'asc' THEN 'status' END ASC,
  --   CASE WHEN LCASE(_sort_by) = 'status' and LCASE(_order) = 'desc' THEN `status` END DESC
  -- LIMIT _offset ,_range;

END$


DELIMITER ;

