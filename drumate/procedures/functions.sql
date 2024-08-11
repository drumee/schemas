DELIMITER $
-- =========================================================
-- Get ident, based on database name
-- =========================================================

DROP FUNCTION IF EXISTS `get_finger_print`$
CREATE FUNCTION `get_finger_print`(
)
RETURNS VARCHAR(80) DETERMINISTIC
BEGIN
  DECLARE _fp VARCHAR(120);
  SELECT `value` FROM params WHERE pkey='password-master' INTO _fp;
  RETURN _fp;
END$


-- =========================================================
-- count_unread
-- =========================================================

DROP FUNCTION IF EXISTS `count_unread`$
CREATE FUNCTION `count_unread`(
  _cid VARBINARY(16)
)
RETURNS INT DETERMINISTIC
BEGIN
  DECLARE _count INT;

  IF _cid IS NOT NULL THEN
    SELECT COUNT(*) FROM mark WHERE msg_status='new' AND cid=_cid INTO _count;
  ELSE
    SELECT COUNT(*) FROM mark WHERE msg_status='new' INTO _count;
  END IF;

  RETURN _count;
END$


-- =========================================================
-- Copy pending invitation from directory into drumate's tables
-- =========================================================

DROP FUNCTION IF EXISTS `copy_notices`$
-- CREATE FUNCTION `copy_notices`(
--   in_email VARCHAR(255)
-- )
-- RETURNS BOOLEAN DETERMINISTIC
-- BEGIN
--    INSERT INTO notices SELECT * FROM yp.notice WHERE email=in_email;
--    DELETE FROM directory.notice WHERE email=in_email;
--    RETURN TRUE;
-- END$

DELIMITER ;
