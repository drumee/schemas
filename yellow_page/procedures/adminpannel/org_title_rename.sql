DELIMITER $

-- =========================================================
-- org_title_rename
-- =========================================================
-- Rename one of an organisation's own titles — the pencil beside it in the
-- Title dropdown. The people who carry it are renamed with it: member_title
-- stores a custom title by name, so their rows are rewritten in the same
-- transaction. (Access rules, keyed by the same name in organisation.metadata,
-- are rewritten by the service from the old_name this returns.)
--
-- Only custom titles: the built-ins are fixed keys, not rows, and have no id.
--
-- Refusals are error rows:
--   INVALID_NAME     empty after trimming, or longer than 64 characters
--   TITLE_NOT_FOUND  no such title in this organisation (also: another
--                    organisation's id — matched together with domain_id)
--   TITLE_EXISTS     the new name is a built-in or another title's name
DROP PROCEDURE IF EXISTS `org_title_rename`$
CREATE PROCEDURE `org_title_rename`(
  IN _domain_id INT UNSIGNED,
  IN _id        VARCHAR(16),
  IN _name      VARCHAR(255)
)
proc: BEGIN
  DECLARE _old VARCHAR(64) DEFAULT NULL;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  SET _name = TRIM(IFNULL(_name, ''));
  IF _name = '' OR CHAR_LENGTH(_name) > 64 THEN
    SELECT 'INVALID_NAME' AS error;
    LEAVE proc;
  END IF;

  SELECT name INTO _old FROM org_title WHERE domain_id = _domain_id AND id = _id;
  IF _old IS NULL THEN
    SELECT 'TITLE_NOT_FOUND' AS error;
    LEAVE proc;
  END IF;

  IF LOWER(_name) IN ('director', 'manager', 'executive')
     OR EXISTS (
       SELECT 1 FROM org_title
        WHERE domain_id = _domain_id AND name = _name AND id != _id
     ) THEN
    SELECT 'TITLE_EXISTS' AS error;
    LEAVE proc;
  END IF;

  START TRANSACTION;
  UPDATE org_title
     SET name = _name, mtime = UNIX_TIMESTAMP()
   WHERE domain_id = _domain_id AND id = _id;
  UPDATE member_title
     SET title = _name, mtime = UNIX_TIMESTAMP()
   WHERE domain_id = _domain_id AND title = _old;
  COMMIT;

  SELECT _id AS id, _name AS name, _old AS old_name;
END$

DELIMITER ;
