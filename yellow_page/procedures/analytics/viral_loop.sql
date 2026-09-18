-- Lives HERE, not in analytics-server, because bin/patch.js resolves its target
-- database from the path prefix: `yellow_page/` means the YP database, and
-- analytics-server/schemas/procedures/yp/ matches nothing it knows (see 8a4a082).
DELIMITER $
-- =========================================================
-- viral_loop
--
-- ALL TIME. Kept with its original signature, (), on purpose: stage runs
-- one shared yp behind several endpoints and MariaDB has no default
-- parameters, so giving this an argument raises ER_SP_WRONG_NO_OF_ARGS for
-- every build still calling it bare -- in EITHER deploy order.
--
-- The body lives in viral_loop_window; this delegates with no window, so there
-- is one definition and no copy to drift. NULL, not '{}': JSON_VALUE(NULL, ...)
-- is NULL, so both bounds read as absent.
-- =========================================================
DROP PROCEDURE IF EXISTS `viral_loop`$
CREATE PROCEDURE `viral_loop`()
BEGIN
  CALL viral_loop_window(NULL);
END $

DELIMITER ;
