DELIMITER $

-- =========================================================
-- department_add
-- =========================================================
-- Create a department inside an organisation (Figma 104:33055, "+ New
-- department"). Returns the new row, or a single-column error result the
-- service maps to an output status.
--
-- REFUSES domain 1. Domain 1 is the default public domain every account lands
-- on before it belongs to an organisation; a department there would be visible
-- to nobody and owned by everybody. NOT_IN_ORGANISATION is the same shape the
-- caller already handles for org-only endpoints.
--
-- The UNIQUE(domain_id, name) index is checked BEFORE the insert rather than
-- caught after it, so the caller gets DEPARTMENT_EXISTS instead of a duplicate-
-- key SQLEXCEPTION -- see the header of tables/department.sql for why that
-- index exists at all.
--
-- `rank` appends: MAX+1 within the domain, so a new department lands at the
-- bottom of the org view instead of reshuffling the sections above it.
DROP PROCEDURE IF EXISTS `department_add`$
CREATE PROCEDURE `department_add`(
  IN _domain_id INT UNSIGNED,
  IN _uid       VARCHAR(16),
  IN _name      VARCHAR(255)
)
proc: BEGIN
  DECLARE _id    VARCHAR(16);
  DECLARE _taken INT DEFAULT 0;
  DECLARE _rank  INT DEFAULT 0;
  DECLARE _now   INT UNSIGNED;

  SET _name = TRIM(_name);

  IF IFNULL(_domain_id, 0) <= 1 THEN
    SELECT 'NOT_IN_ORGANISATION' AS error;
    LEAVE proc;
  END IF;

  IF _name IS NULL OR _name = '' THEN
    SELECT 'INVALID_NAME' AS error;
    LEAVE proc;
  END IF;

  SELECT COUNT(*) INTO _taken
    FROM department WHERE domain_id = _domain_id AND name = _name;
  IF _taken > 0 THEN
    SELECT 'DEPARTMENT_EXISTS' AS error;
    LEAVE proc;
  END IF;

  SELECT UNIX_TIMESTAMP() INTO _now;
  SELECT LOWER(LEFT(REPLACE(UUID(), '-', ''), 16)) INTO _id;
  SELECT IFNULL(MAX(`rank`), 0) + 1 INTO _rank
    FROM department WHERE domain_id = _domain_id;

  INSERT INTO department (`id`, `domain_id`, `name`, `rank`, `owner_id`, `ctime`, `mtime`)
  VALUES (_id, _domain_id, _name, _rank, _uid, _now, _now);

  SELECT d.*, 0 AS workspace_count, 0 AS member_count
    FROM department d WHERE d.id = _id;
END$

DELIMITER ;
