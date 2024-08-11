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


DROP PROCEDURE IF EXISTS `create_or_update_alias`$
CREATE PROCEDURE `create_or_update_alias`(
  IN _src VARCHAR(255),
  IN _dest VARCHAR(255)
)
BEGIN
  DECLARE _domain_id INT(6);
  DECLARE _domain_name VARCHAR(600);

  SELECT domain_id FROM users WHERE email=_src INTO _domain_id;
  SELECT `name` FROM domains WHERE  id=_domain_id INTO _domain_name;
  IF _domain_name IS NOT NULL THEN 
    REPLACE INTO aliases VALUES(NULL, _domain_id, _src, _dest);
  END IF;
END$

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

-- #####################
