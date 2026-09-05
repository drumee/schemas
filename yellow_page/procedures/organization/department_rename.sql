DELIMITER $

-- =========================================================
-- department_rename
-- =========================================================
-- Rename a department. Domain-scoped on purpose: _domain_id is part of the
-- WHERE, not just a guard, so a caller holding a department id from another
-- tenant cannot rename it even if the id leaked.
--
-- A no-op rename (same name) is allowed through rather than reported as
-- DEPARTMENT_EXISTS -- the collision check excludes the row being renamed.
DROP PROCEDURE IF EXISTS `department_rename`$
CREATE PROCEDURE `department_rename`(
  IN _domain_id INT UNSIGNED,
  IN _id        VARCHAR(16),
  IN _name      VARCHAR(255)
)
proc: BEGIN
  DECLARE _taken  INT DEFAULT 0;
  DECLARE _exists INT DEFAULT 0;

  SET _name = TRIM(_name);

  IF _name IS NULL OR _name = '' THEN
    SELECT 'INVALID_NAME' AS error;
    LEAVE proc;
  END IF;

  SELECT COUNT(*) INTO _exists
    FROM department WHERE id = _id AND domain_id = _domain_id;
  IF _exists = 0 THEN
    SELECT 'DEPARTMENT_NOT_FOUND' AS error;
    LEAVE proc;
  END IF;

  SELECT COUNT(*) INTO _taken
    FROM department
   WHERE domain_id = _domain_id AND name = _name AND id != _id;
  IF _taken > 0 THEN
    SELECT 'DEPARTMENT_EXISTS' AS error;
    LEAVE proc;
  END IF;

  UPDATE department
     SET name = _name, mtime = UNIX_TIMESTAMP()
   WHERE id = _id AND domain_id = _domain_id;

  SELECT d.* FROM department d WHERE d.id = _id;
END$

DELIMITER ;
