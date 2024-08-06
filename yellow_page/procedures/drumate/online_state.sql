DELIMITER $


DROP FUNCTION IF EXISTS `online_state`$
CREATE FUNCTION `online_state`(
  _uid VARCHAR(80) CHARACTER SET ascii 
)
RETURNS INTEGER DETERMINISTIC
BEGIN
  DECLARE _meeting INTEGER DEFAULT 0;
  DECLARE _online INTEGER DEFAULT 0;

  SELECT count(*) FROM conference u INNER JOIN socket s ON 
    s.uid = u.uid WHERE s.uid = _uid AND s.state='active' INTO _meeting;

  SELECT count(*) FROM socket s 
    WHERE s.uid=_uid AND `state`='active' INTO _online;

  RETURN IF(_meeting > 0, 2, IF(_online > 0, 1, 0));

END$

DELIMITER ;