DELIMITER $


-- =======================================================================
-- list all spaces the specified user belong to
-- =======================================================================
DROP PROCEDURE IF EXISTS `drumate_set_lang`$
CREATE PROCEDURE `drumate_set_lang`(
  IN _key VARCHAR(255),
  IN _lang VARCHAR(16)
)
BEGIN
  DECLARE _id VARBINARY(16);
  SELECT id FROM entity WHERE ident=_key OR id=_key INTO _id;
  UPDATE drumate SET `profile`=JSON_SET(`profile`,'$.lang', _lang) where id=_id;
  UPDATE user SET `profile`=JSON_SET(`profile`,'$.lang', _lang) where id=_id;
  SELECT `profile` FROM drumate WHERE id=_id;
END $

DELIMITER ;
