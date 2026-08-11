DELIMITER $

-- =========================================================
-- session_logout_others
-- Kill every session of _uid except _keep (the caller's own
-- session id). Cookies die first so the sessions cannot be
-- resumed, then their live sockets are dropped. Used by
-- drumate.change_password's "log out of other devices".
-- =========================================================

DROP PROCEDURE IF EXISTS `session_logout_others`$
CREATE PROCEDURE `session_logout_others`(
  IN _uid  VARCHAR(16),
  IN _keep VARCHAR(128)
)
BEGIN
  DELETE FROM cookie WHERE `uid`=_uid AND id <> _keep;
  DELETE FROM socket WHERE `uid`=_uid AND (cookie IS NULL OR cookie <> _keep);
END $

DELIMITER ;
