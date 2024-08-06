DELIMITER $

DROP PROCEDURE IF EXISTS `get_settings`$
CREATE PROCEDURE `get_settings`(
  IN _key VARCHAR(255)
)
BEGIN
  DECLARE _id VARBINARY(16);
  IF _key REGEXP '^(.+)\\.(.+)' THEN
    SELECT id FROM `vhost` WHERE fqdn=_key INTO _id;
  ELSE
    SELECT id FROM `entity` WHERE id=_key OR ident=_key INTO _id;
  END IF;
  SELECT settings FROM entity WHERE id=_id;
END$



DELIMITER ;
