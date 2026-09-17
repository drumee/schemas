-- Lives HERE, not in analytics-server, because bin/patch.js resolves its target
-- database from the path prefix: `yellow_page/` means the YP database, and
-- analytics-server/schemas/procedures/yp/ matches nothing it knows. A
-- procedure there is one no documented tooling can apply (see 8a4a082, which
-- moved signup_track for the same reason).
DELIMITER $
-- =========================================================
-- funnel_summary
--
-- One-row tally of the activation funnel, ALL TIME. Kept with
-- its original signature, (), on purpose: stage runs one shared
-- yp behind several endpoints, and analytics-server builds
-- are called by exact arity -- `call funnel_summary()` against a
-- procedure that takes an argument raises ER_SP_WRONG_NO_OF_ARGS.
-- Every build that predates the window still calls it bare.
--
-- The body lives in funnel_summary_window, and this delegates
-- with no window, so there is one definition of the funnel and
-- no copy to drift. See that procedure's header for what the
-- counts mean and why a window is a SIGNUP-COHORT bound.
--
-- NULL, not '{}': JSON_VALUE(NULL, ...) is NULL, so both bounds
-- read as absent -- all time, exactly what this reported before.
-- =========================================================
DROP PROCEDURE IF EXISTS `funnel_summary`$
CREATE PROCEDURE `funnel_summary`()
BEGIN
  CALL funnel_summary_window(NULL);
END $

DELIMITER ;
