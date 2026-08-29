DELIMITER $

-- =========================================================
-- feature_mark
--
-- Record that a user used a core feature, for the analytics
-- Engagement > Core function page. Safe to call on every
-- upload, every message, every task and every meeting join:
-- the table's PRIMARY KEY (uid, feature) makes the second and
-- later calls an UPDATE rather than a second row, so callers
-- need no "have they already?" query and cannot race each
-- other into a double count.
--
-- _hits AND _volume ARE INCREMENTS, NOT TOTALS. Callers batch
-- in-process and post the delta accumulated since their last
-- flush (see server-team service/lib/feature-usage.js), so a
-- 500-file upload arrives as one call with _hits = 500 rather
-- than 500 calls. Passing an absolute total here would make
-- two concurrent flushes lose each other's work.
--
-- ctime IS ABSENT FROM THE UPDATE CLAUSE, and that is the
-- whole first-use rule. It is set by the INSERT and never
-- touched again, so it means "first use" however many events
-- land afterwards. Do not add it to the UPDATE to "keep it
-- fresh" -- last-use is a different column, and nothing on the
-- page asks for it.
--
-- AN UNKNOWN FEATURE RAISES. It does not silently no-op: the
-- callers are fire-and-forget with a .catch(warn), so a signal
-- surfaces a typo in the log, whereas a quiet skip would
-- under-count adoption forever with nothing to notice. Same
-- choice funnel_mark makes, for the same reason.
--
-- VOLUME IS BYTES, AND TWO FEATURES USE IT: 'upload' (bytes stored) and
-- 'gdrive' (bytes migrated). Nothing enforces that here -- a byte count on a
-- chat row would be harmless and meaningless -- but core_function reads volume
-- off upload rows only and aha_moment off gdrive rows only, so writing it
-- anywhere else reports nowhere.
-- =========================================================
DROP PROCEDURE IF EXISTS `feature_mark`$
CREATE PROCEDURE `feature_mark`(
  IN _uid VARCHAR(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
  IN _feature VARCHAR(32),
  IN _hits INT(11),
  IN _volume BIGINT(20)
)
BEGIN
  -- The list is the enum's, and the two must be widened together in that
  -- order: this proc rejecting a value the column accepts is a harmless
  -- refusal, but accepting one the column does not is a write that fails
  -- deeper, inside a statement whose failure ends the shared connection.
  -- VARCHAR(32) is not incidental: 'selfhosted_click' is exactly 16 chars,
  -- and a future key one character longer would truncate silently here,
  -- fail the IN-list check, and SIGNAL — which rolls back and ends the
  -- shared yp connection, surfacing as stalled sibling requests.
  IF _feature NOT IN ('upload', 'chat', 'task', 'meeting', 'file_thread', 'gdrive',
                      'upgrade_click', 'selfhosted_click') THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'feature_mark: unknown feature (see yp.feature_usage enum)';
  END IF;

  -- An anonymous or system actor has no adoption row to write. Not an error:
  -- conference.join is reachable by a DMZ guest, and a guest is not a signup.
  -- Same guard funnel_mark applies, for the same reason.
  IF _uid IS NOT NULL AND _uid <> '' THEN
    INSERT INTO feature_usage (uid, feature, ctime, hits, volume)
      VALUES (
        _uid,
        _feature,
        UNIX_TIMESTAMP(),
        GREATEST(IFNULL(_hits, 1), 0),
        GREATEST(IFNULL(_volume, 0), 0)
      )
      ON DUPLICATE KEY UPDATE
        hits   = hits   + GREATEST(IFNULL(_hits, 1), 0),
        volume = volume + GREATEST(IFNULL(_volume, 0), 0);
  END IF;
END $

DELIMITER ;
