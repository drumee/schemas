DELIMITER $
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

DELIMITER ;
