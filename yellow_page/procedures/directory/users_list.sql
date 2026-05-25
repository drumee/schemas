DELIMITER $
DROP PROCEDURE IF EXISTS `users_list`$
CREATE PROCEDURE `users_list`(
  IN _args JSON
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  DECLARE _sort_by VARCHAR(20) DEFAULT 'name';
  DECLARE _order VARCHAR(20) DEFAULT 'asc';
  DECLARE _type VARCHAR(20) DEFAULT NULL;
  DECLARE _domain VARCHAR(20) DEFAULT NULL;
  DECLARE _page INTEGER DEFAULT 1;

  SELECT IFNULL(JSON_VALUE(_args, "$.sort_by"), 'ctime') INTO _sort_by;
  SELECT IFNULL(JSON_VALUE(_args, "$.order"), 'desc') INTO _order;
  SELECT IFNULL(JSON_VALUE(_args, "$.type"), 'desc') INTO _type;
  SELECT IFNULL(JSON_VALUE(_args, "$.domain"), 'desc') INTO _domain;
  SELECT IFNULL(JSON_VALUE(_args, "$.page"), 1) INTO _page;

  CALL pageToLimits(_page, _offset, _range);
  SELECT 
    _page as `page`,
    d.id,
    e.ctime,
    d.firstname,
    d.lastname,
    SUBSTRING_INDEX(d.email, '@', 1) AS username,
    SUBSTRING_INDEX(d.email, '@', -1) AS domain,
    email
  FROM entity e INNER JOIN (yp.drumate d) USING(id)
  WHERE IF(_type IS NULL, 1, type=_type) AND IF(_domain IS NULL, 1, domain=_domain)
  ORDER BY
    CASE WHEN LCASE(_sort_by) = 'date' AND LCASE(_order) = 'asc' THEN ctime END ASC,
    CASE WHEN LCASE(_sort_by) = 'date' AND LCASE(_order) = 'desc' THEN ctime END DESC,
    CASE WHEN LCASE(_sort_by) = 'email' AND LCASE(_order) = 'asc' THEN filename END ASC,
    CASE WHEN LCASE(_sort_by) = 'email' AND LCASE(_order) = 'desc' THEN filename END DESC,
    CASE WHEN LCASE(_sort_by) = 'username' AND LCASE(_order) = 'asc' THEN filename END ASC,
    CASE WHEN LCASE(_sort_by) = 'username' AND LCASE(_order) = 'desc' THEN filename END DESC,
    CASE WHEN LCASE(_sort_by) = 'domain' AND LCASE(_order) = 'asc' THEN filename END ASC,
    CASE WHEN LCASE(_sort_by) = 'domain' AND LCASE(_order) = 'desc' THEN filename END DESC
  LIMIT _offset, _range;
END$
DELIMITER ;