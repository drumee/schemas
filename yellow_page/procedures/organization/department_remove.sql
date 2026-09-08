DELIMITER $

-- =========================================================
-- department_remove
-- =========================================================
-- Delete a department WITHOUT touching its workspaces.
--
-- This is the reason tables/department.sql carries no foreign key: a cascade
-- here would delete real workspaces because somebody tidied up a grouping.
-- Instead the member workspaces have department_id set back to NULL, which
-- returns them to the org view's ungrouped row -- the same place every
-- workspace on a pre-department install already sits. Nothing is destroyed
-- except the label.
--
-- Both statements run in one transaction so a failure cannot leave the
-- department gone and its hubs still pointing at it (which would hide those
-- workspaces from the org view entirely: they would match no section and no
-- ungrouped row).
--
-- NB on the nesting, before anyone "fixes" it: server-essentials' mariadb stub
-- opens a transaction before EVERY await_proc, so this always runs already
-- inside one. START TRANSACTION here implicitly commits that outer (empty) one
-- and opens ours -- legal, and exactly what org_provision has been doing in
-- production since 2026-07. The EXIT HANDLER's ROLLBACK then unwinds OUR
-- transaction, which is the unit that matters.
DROP PROCEDURE IF EXISTS `department_remove`$
CREATE PROCEDURE `department_remove`(
  IN _domain_id INT UNSIGNED,
  IN _id        VARCHAR(16)
)
proc: BEGIN
  DECLARE _exists  INT DEFAULT 0;
  DECLARE _release INT DEFAULT 0;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  SELECT COUNT(*) INTO _exists
    FROM department WHERE id = _id AND domain_id = _domain_id;
  IF _exists = 0 THEN
    SELECT 'DEPARTMENT_NOT_FOUND' AS error;
    LEAVE proc;
  END IF;

  SELECT COUNT(*) INTO _release
    FROM hub WHERE domain_id = _domain_id AND department_id = _id;

  START TRANSACTION;

  UPDATE hub SET department_id = NULL
   WHERE domain_id = _domain_id AND department_id = _id;

  DELETE FROM department WHERE id = _id AND domain_id = _domain_id;

  COMMIT;

  SELECT _id AS id, _release AS released;
END$

DELIMITER ;
