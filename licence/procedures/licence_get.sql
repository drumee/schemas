
DELIMITER $

DROP PROCEDURE IF EXISTS `licence_get`$
CREATE PROCEDURE `licence_get`(
  IN  _key varchar(128) 
)
BEGIN
  SELECT 
    l.customer_id,
    l.reseller_id,
    l.content,
    l.ctime,
    l.atime,
    l.signature,
    l.key,
    l.domain,
    l.type,
    l.status,
    l.capacity,
    l.unit,
    l.domain domain_name, 
    d.email reseller_email
  FROM licence l INNER JOIN 
    yp.drumate d on d.id=l.reseller_id WHERE `key` = _key;
END$

DELIMITER ;
