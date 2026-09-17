-- File: schemas/drumate/procedures/notification/notification_read_v2.sql
-- Purpose: notification_read, plus a row in notification_activity_history.
--
-- v2 exists because recording history needs the rollup's originating _ctime,
-- and adding that parameter to `notification_read` in place would have been a
-- breaking change: MariaDB stored procedures have no default parameter values,
-- so the deployed callers that pass four arguments would fail with
-- ER_SP_WRONG_NO_OF_ARGS the moment the new body was applied. Preview/UAT and
-- PROD share one database, so that break would have been immediate and
-- fleet-wide. The v1 contract is therefore left exactly as it is and the new
-- argument lives here.
--
-- The body is not duplicated: this is v1 plus the history snapshot. Callers
-- that want history call v2; everything already deployed keeps calling v1 and
-- behaves exactly as before. notification_history_snapshot itself ignores a
-- NULL or zero _ctime and falls back to the current timestamp.

DELIMITER $

DROP PROCEDURE IF EXISTS `notification_read_v2`$

CREATE PROCEDURE `notification_read_v2`(
  IN _category VARCHAR(16),
  IN _key_id VARCHAR(255),
  IN _hub_id VARCHAR(16),
  IN _last_id BIGINT,
  IN _ctime INT UNSIGNED
)
BEGIN
  CALL notification_history_snapshot(
    _category, _key_id, _hub_id, _last_id, _ctime
  );

  CALL notification_read(_category, _key_id, _hub_id, _last_id);
END$

DELIMITER ;
