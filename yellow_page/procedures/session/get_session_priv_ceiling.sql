DELIMITER $

DROP FUNCTION IF EXISTS `get_session_priv_ceiling`$
CREATE FUNCTION `get_session_priv_ceiling`(
  _sid VARCHAR(64)
)
RETURNS TINYINT UNSIGNED DETERMINISTIC
BEGIN
  DECLARE _ceiling TINYINT UNSIGNED DEFAULT NULL;
  SELECT IF(ceiling_uid IS NOT NULL AND uid <=> ceiling_uid, priv_ceiling, NULL)
    FROM cookie WHERE id=_sid LIMIT 1 INTO _ceiling;
  RETURN _ceiling;
END$

DELIMITER ;
