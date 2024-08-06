DELIMITER $

DROP PROCEDURE IF EXISTS `delete_user`$
CREATE PROCEDURE `delete_user`(
  IN _email VARCHAR(255)
)
BEGIN
  DECLARE _domain_id INT(6);
  DECLARE _domain_name VARCHAR(600);

  DELETE FROM aliases WHERE source=_email;
  DELETE FROM users WHERE email=_email;
END$

DELIMITER ;
