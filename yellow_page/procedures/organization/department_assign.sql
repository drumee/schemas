DELIMITER $

-- =========================================================
-- department_assign
-- =========================================================
-- Move one workspace into a department, or out of every department when
-- _department_id is NULL (the org view's ungrouped row).
--
-- BOTH SIDES ARE TENANT-CHECKED. The hub must be in _domain_id and so must the
-- department; either check failing is refused rather than silently no-op'ing,
-- because a silent no-op here reads to the client as a successful move and the
-- workspace visibly snaps back on the next refresh.
--
-- Does NOT touch yp.entity, yp.vhost or the hub's own database. Department is
-- a label on the organisation's side of the world -- moving a workspace
-- between departments changes no permission, no address and no storage, which
-- is exactly why it is safe to expose to an org admin.
DROP PROCEDURE IF EXISTS `department_assign`$
CREATE PROCEDURE `department_assign`(
  IN _domain_id     INT UNSIGNED,
  IN _hub_id        VARCHAR(16),
  IN _department_id VARCHAR(16)
)
proc: BEGIN
  DECLARE _exists INT DEFAULT 0;

  SELECT COUNT(*) INTO _exists
    FROM hub WHERE id = _hub_id AND domain_id = _domain_id;
  IF _exists = 0 THEN
    SELECT 'WORKSPACE_NOT_FOUND' AS error;
    LEAVE proc;
  END IF;

  IF _department_id IS NOT NULL AND _department_id != '' THEN
    SELECT COUNT(*) INTO _exists
      FROM department WHERE id = _department_id AND domain_id = _domain_id;
    IF _exists = 0 THEN
      SELECT 'DEPARTMENT_NOT_FOUND' AS error;
      LEAVE proc;
    END IF;
  ELSE
    SET _department_id = NULL;
  END IF;

  UPDATE hub SET department_id = _department_id
   WHERE id = _hub_id AND domain_id = _domain_id;

  SELECT _hub_id AS hub_id, _department_id AS department_id;
END$

DELIMITER ;
