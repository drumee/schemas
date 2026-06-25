DELIMITER $

DROP PROCEDURE IF EXISTS `clear_session_priv_ceiling`$
CREATE PROCEDURE `clear_session_priv_ceiling`(
  IN _sid VARCHAR(64)
)
BEGIN
  UPDATE cookie SET priv_ceiling=NULL, ceiling_uid=NULL WHERE id=_sid;
END$

DELIMITER ;
