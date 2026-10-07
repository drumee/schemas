DELIMITER $

-- =========================================================
-- member_title_set
-- =========================================================
-- Set or clear one person's title in an organisation. '' (or NULL) clears it
-- by deleting the row. A built-in title (director / manager / executive) is
-- matched case-insensitively and stored as its lower-case key, so 'Manager'
-- and 'manager' are one value. Anything else must be one of the
-- organisation's own titles (yp.org_title, matched case-insensitively) and is
-- stored under the name as the organisation spelled it. Anything outside both
-- is refused with an error row rather than signalled, matching
-- department_assign, so the service can map it to a status without catching.
DROP PROCEDURE IF EXISTS `member_title_set`$
CREATE PROCEDURE `member_title_set`(
  IN _domain_id INT UNSIGNED,
  IN _uid       VARCHAR(16),
  IN _title     VARCHAR(255),
  IN _by        VARCHAR(16)
)
proc: BEGIN
  DECLARE _name VARCHAR(64) DEFAULT NULL;

  SET _title = TRIM(IFNULL(_title, ''));

  IF _title = '' THEN
    DELETE FROM member_title WHERE domain_id = _domain_id AND uid = _uid;
    SELECT _uid AS uid, NULL AS title;
    LEAVE proc;
  END IF;

  IF LOWER(_title) IN ('director', 'manager', 'executive') THEN
    SET _name = LOWER(_title);
  ELSE
    SELECT name INTO _name
      FROM org_title
     WHERE domain_id = _domain_id AND name = _title
     LIMIT 1;
  END IF;

  IF _name IS NULL THEN
    SELECT 'INVALID_TITLE' AS error;
    LEAVE proc;
  END IF;

  INSERT INTO member_title (domain_id, uid, title, by_id, mtime)
    VALUES (_domain_id, _uid, _name, _by, UNIX_TIMESTAMP())
    ON DUPLICATE KEY UPDATE
      title = VALUES(title),
      by_id = VALUES(by_id),
      mtime = VALUES(mtime);

  SELECT _uid AS uid, _name AS title;
END$

DELIMITER ;
