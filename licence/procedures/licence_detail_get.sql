
DELIMITER $


DROP PROCEDURE IF EXISTS `licence_detail_get`$
CREATE PROCEDURE `licence_detail_get`(
  IN  _domain_name  varchar(1000),
  IN  _email varchar(1000) 
)
BEGIN
  SELECT  0 as failed,
    fom.id token,
    l.key,
    l.status,
    fom.profile
  FROM 
    licence l
    INNER JOIN customer cus on l.customer_id = cus.id
    INNER JOIN company com on cus.company_id    = com.id 
    INNER JOIN form fom on cus.form_id    = fom.id 
    INNER JOIN user u on cus.user_id    = u.id 
  WHERE 
    u.email = _email  AND 
    fom.domain_name =_domain_name;


END$


DELIMITER ;
