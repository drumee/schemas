DELIMITER $

DROP PROCEDURE IF EXISTS `online_users`$
CREATE PROCEDURE `online_users`(
)
BEGIN
  SELECT d.firstname, d.lastname, s.server, d.email, d.id, online_state(d.id) `state`
  FROM socket s INNER JOIN drumate d ON s.uid=d.id
  WHERE s.state='active';
END$

DELIMITER ;