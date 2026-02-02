DELIMITER $

DROP PROCEDURE IF EXISTS `online_users`$
CREATE PROCEDURE `online_users`(
)
BEGIN
  SELECT d.firstname, d.lastname, d.email, d.id, online_state(d.id)
  FROM socket s INNER JOIN drumate d ON s.uid=d.id
  WHERE s.state='active';
END$

DELIMITER ;

-- #####################
