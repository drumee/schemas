
DELIMITER $

DROP PROCEDURE IF EXISTS `licence_get`$
CREATE PROCEDURE `licence_get`(
  IN _key VARCHAR(128) CHARACTER SET ascii
)
BEGIN

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
    FROM customer c 
      INNER JOIN licence.licence l  
      ON l.customer_id=c.id
      WHERE `key` = _key;
END$


DELIMITER ;

