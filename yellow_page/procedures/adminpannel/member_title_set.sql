DELIMITER $

-- =========================================================
-- member_title_set
-- =========================================================
-- Set or clear one person's title in an organisation. '' (or NULL) clears it
-- by deleting the row. Input is trimmed and lower-cased so 'Manager' and
-- 'manager' are one value. Anything outside the three titles is refused with
-- an error row rather than signalled, matching department_assign, so the
-- service can map it to a status without catching.
DROP PROCEDURE IF EXISTS `member_title_set`$
CREATE PROCEDURE `member_title_set`(
  IN _domain_id INT UNSIGNED,
  IN _uid       VARCHAR(16),
  IN _title     VARCHAR(16),
  IN _by        VARCHAR(16)
)
proc: BEGIN
  SET _title = LOWER(TRIM(IFNULL(_title, '')));

  IF _title = '' THEN
    DELETE FROM member_title WHERE domain_id = _domain_id AND uid = _uid;
    SELECT _uid AS uid, NULL AS title;
    LEAVE proc;
  END IF;

  IF _title NOT IN ('director', 'manager', 'executive') THEN
    SELECT 'INVALID_TITLE' AS error;
    LEAVE proc;
  END IF;

  INSERT INTO member_title (domain_id, uid, title, by_id, mtime)
    VALUES (_domain_id, _uid, _title, _by, UNIX_TIMESTAMP())
    ON DUPLICATE KEY UPDATE
      title = VALUES(title),
      by_id = VALUES(by_id),
      mtime = VALUES(mtime);

  SELECT _uid AS uid, _title AS title;
END$

DELIMITER ;
