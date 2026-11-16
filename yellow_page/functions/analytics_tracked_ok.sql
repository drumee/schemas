DELIMITER $

-- =========================================================
-- analytics_tracked_ok
-- Whether account `_uid` is counted when the dashboard asks for tracked
-- list `_list` (yp.analytics_tracked_user.list_name).
--
--   NULL, or not a plain list name -> 1: no list, everyone counts, which
--                                     is what every existing caller gets
--   '<list>'                       -> 1 only for accounts on that list; an
--                                     unknown list tracks nobody
--
-- Applied beside analytics_test_email_regexp(), never instead of it.
-- =========================================================
DROP FUNCTION IF EXISTS `analytics_tracked_ok`$
CREATE FUNCTION `analytics_tracked_ok`(
  _uid VARCHAR(16) CHARACTER SET ascii,
  _list VARCHAR(255)
)
RETURNS TINYINT READS SQL DATA
BEGIN
  IF _list IS NULL OR _list NOT REGEXP '^[A-Za-z0-9_-]{1,64}$' THEN
    RETURN 1;
  END IF;
  RETURN EXISTS (SELECT 1 FROM analytics_tracked_user t WHERE t.list_name = _list AND t.uid = _uid);
END$

DELIMITER ;
