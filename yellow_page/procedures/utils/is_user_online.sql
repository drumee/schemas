DELIMITER $
DROP FUNCTION IF EXISTS `is_user_online`$
CREATE FUNCTION `is_user_online`(
  _key VARCHAR(1024)
)
RETURNS VARCHAR(1024) DETERMINISTIC
BEGIN
  DECLARE _r INTEGER DEFAULT 0;
  SELECT COUNT(*) FROM socket s 
    INNER JOIN drumate d ON s.uid=d.id 
    WHERE s.state = 'active' AND s.uid=_key OR d.email=_key INTO _r;
  RETURN _r;
END$


DELIMITER ;
-- #####################
