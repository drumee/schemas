DELIMITER $

DROP PROCEDURE IF EXISTS `show_b2c_users`$
CREATE PROCEDURE `show_b2c_users`(
)
BEGIN
  SELECT username, firstname, lastname, email 
    FROM drumate INNER JOIN entity e USING(id) WHERE domain_id=1 AND 
    JSON_VALUE(profile, "$.email_verified")='yes' AND 
    status='active' AND remit=0 AND email NOT LIKE "%xialia.fr";
END$

DELIMITER ;

