DELIMITER $

-- =========================================================
-- org_title_add
-- =========================================================
-- Add a title to an organisation — the "+ New Title" row of the Admin Console
-- Title dropdown. Appended after the existing ones.
--
-- Refusals are error rows, not signals (same contract as member_title_set):
--   INVALID_NAME  empty after trimming, or longer than 64 characters
--   TITLE_EXISTS  a built-in key, or a name this organisation already has
--                 (both case-insensitive)
DROP PROCEDURE IF EXISTS `org_title_add`$
CREATE PROCEDURE `org_title_add`(
  IN _domain_id INT UNSIGNED,
  IN _name      VARCHAR(255),
  IN _by        VARCHAR(16)
)
proc: BEGIN
  DECLARE _id VARCHAR(16);
  DECLARE _rank INT UNSIGNED;

  SET _name = TRIM(IFNULL(_name, ''));
  IF _name = '' OR CHAR_LENGTH(_name) > 64 THEN
    SELECT 'INVALID_NAME' AS error;
    LEAVE proc;
  END IF;

  IF LOWER(_name) IN ('director', 'manager', 'executive')
     OR EXISTS (SELECT 1 FROM org_title WHERE domain_id = _domain_id AND name = _name) THEN
    SELECT 'TITLE_EXISTS' AS error;
    LEAVE proc;
  END IF;

  SET _id = LOWER(LEFT(REPLACE(UUID(), '-', ''), 16));
  SELECT IFNULL(MAX(`rank`), 0) + 1 INTO _rank FROM org_title WHERE domain_id = _domain_id;

  INSERT INTO org_title (id, domain_id, name, `rank`, by_id, ctime, mtime)
    VALUES (_id, _domain_id, _name, _rank, _by, UNIX_TIMESTAMP(), UNIX_TIMESTAMP());

  SELECT _id AS id, _name AS name, _rank AS `rank`;
END$

DELIMITER ;
