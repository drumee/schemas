DELIMITER $

DROP PROCEDURE IF EXISTS `create_or_update_user`$
CREATE PROCEDURE `create_or_update_user`(
  IN _ident VARCHAR(80),
  IN _domain VARCHAR(255),
  IN _pw VARCHAR(255)
)
BEGIN
  DECLARE _domain_id INT(6);
  DECLARE _domain_name VARCHAR(600);

  SELECT id, `name` FROM domains WHERE `name`=_domain OR id=_domain INTO _domain_id, _domain_name;
  SET @_email = concat(_ident, '@', _domain_name);
  REPLACE INTO users VALUES(NULL, 
    _domain_id, ENCRYPT(_pw, CONCAT('$6$', SUBSTRING(SHA(RAND()), -16))), 
    _ident, @_email); 
END$

DELIMITER ;
