DELIMITER $


-- =========================================================
-- PMF rating survey — upsert one response row per user.
-- Empty _answers keeps any previously stored answers (the
-- score-only submit fires before the wizard completes).
-- =========================================================
DROP PROCEDURE IF EXISTS `survey_upsert`$
CREATE PROCEDURE `survey_upsert`(
  IN _uid VARCHAR(16),
  IN _score TINYINT UNSIGNED,
  IN _answers MEDIUMTEXT
)
BEGIN
  INSERT INTO survey_response (uid, score, answers, ctime, mtime)
  VALUES (_uid, _score, IF(_answers = '', NULL, _answers), UNIX_TIMESTAMP(), UNIX_TIMESTAMP())
  ON DUPLICATE KEY UPDATE
    score   = _score,
    answers = IF(_answers IS NULL OR _answers = '', answers, _answers),
    mtime   = UNIX_TIMESTAMP();
  SELECT * FROM survey_response WHERE uid = _uid;
END$

DELIMITER ;
