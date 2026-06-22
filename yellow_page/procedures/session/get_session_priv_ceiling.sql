DELIMITER $

DROP PROCEDURE IF EXISTS `get_session_priv_ceiling`$
CREATE PROCEDURE `get_session_priv_ceiling`(
  IN _sid VARCHAR(64)
)
BEGIN
  SELECT IF(ceiling_uid IS NOT NULL AND uid <=> ceiling_uid, priv_ceiling, NULL) AS priv_ceiling
    FROM cookie WHERE id=_sid LIMIT 1;
END$

DELIMITER ;
