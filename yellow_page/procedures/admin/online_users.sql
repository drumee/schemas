DELIMITER $

DROP PROCEDURE IF EXISTS `online_users`$
CREATE PROCEDURE `online_users`(
)
BEGIN
  select d.firstname, d.lastname, s.server, online_state(d.id)
  from socket s inner join drumate d on s.uid=d.id
  WHERE s.state='active';
END$

DELIMITER ;

-- #####################
