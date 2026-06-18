DELIMITER $

DROP PROCEDURE IF EXISTS `set_session_priv_ceiling`$
CREATE PROCEDURE `set_session_priv_ceiling`(
  IN _sid VARCHAR(64),
  IN _ceiling TINYINT UNSIGNED,
  IN _bound_uid VARCHAR(16)
)
BEGIN
  UPDATE cookie SET priv_ceiling=_ceiling, ceiling_uid=_bound_uid WHERE id=_sid;
END$

DELIMITER ;
