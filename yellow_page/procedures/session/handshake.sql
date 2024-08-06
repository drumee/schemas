DELIMITER $

-- =========================================================
-- 
-- =========================================================
DROP PROCEDURE IF EXISTS `handshake_add`$
CREATE PROCEDURE `handshake_add`(
  IN _handshake VARCHAR(64),
  IN _ip VARCHAR(64)
)
BEGIN
  DELETE FROM handshake WHERE UNIX_TIMESTAMP() - ctime > 300 ;
  INSERT INTO handshake SELECT null, _handshake, _ip, UNIX_TIMESTAMP();
END$

-- =========================================================
-- 
-- =========================================================
DROP PROCEDURE IF EXISTS `handshake_get`$
CREATE PROCEDURE `handshake_get`(
  IN _handshake VARCHAR(64)
)
BEGIN
  SELECT * FROM handshake WHERE id=_handshake;
END$


DELIMITER ;