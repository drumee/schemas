DELIMITER $

-- =========================================================
-- org_extra_delete
-- =========================================================
-- Undo org_extra_create (rollback / QA cleanup): hand the pool entity back
-- as it was and remove every row keyed by the organisation's domain. Only
-- for organisations listed in org_extra -- never a primary organisation.
-- Refuses while the organisation still holds workspaces unless _force = 1
-- (they would be left pointing at a deleted domain).
--
-- Errors: NOT_AN_EXTRA_ORG, ORG_HAS_WORKSPACES.
DROP PROCEDURE IF EXISTS `org_extra_delete`$
CREATE PROCEDURE `org_extra_delete`(
  IN _domain_id INT UNSIGNED,
  IN _force     TINYINT
)
proc: BEGIN
  DECLARE _org_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _prev   LONGTEXT;
  DECLARE _hubs   INT DEFAULT 0;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  SELECT org_id, prev_entity INTO _org_id, _prev
    FROM org_extra WHERE domain_id = _domain_id;
  IF _org_id IS NULL THEN
    SELECT 'NOT_AN_EXTRA_ORG' AS error;
    LEAVE proc;
  END IF;

  SELECT COUNT(*) INTO _hubs FROM entity WHERE dom_id = _domain_id AND id != _org_id;
  IF _hubs > 0 AND NOT IFNULL(_force, 0) THEN
    SELECT 'ORG_HAS_WORKSPACES' AS error, _hubs AS workspaces;
    LEAVE proc;
  END IF;

  START TRANSACTION;

  UPDATE entity SET
    `area`     = JSON_VALUE(_prev, '$.area'),
    `type`     = JSON_VALUE(_prev, '$.type'),
    `status`   = JSON_VALUE(_prev, '$.status'),
    `dom_id`   = JSON_VALUE(_prev, '$.dom_id'),
    `homepage` = JSON_VALUE(_prev, '$.homepage')
  WHERE id = _org_id;

  DELETE FROM vhost WHERE id = _org_id;
  DELETE FROM hub WHERE id = _org_id;
  DELETE FROM organisation WHERE domain_id = _domain_id;
  DELETE FROM quota WHERE domain_id = _domain_id;
  DELETE FROM quota_usage WHERE domain_id = _domain_id;
  DELETE FROM org_membership WHERE domain_id = _domain_id;
  DELETE FROM department_grant WHERE domain_id = _domain_id;
  DELETE FROM department_member WHERE domain_id = _domain_id;
  DELETE FROM department WHERE domain_id = _domain_id;
  DELETE FROM member_title WHERE domain_id = _domain_id;
  DELETE FROM org_title WHERE domain_id = _domain_id;
  DELETE FROM org_reporting WHERE domain_id = _domain_id;
  DELETE FROM org_join_link WHERE domain_id = _domain_id;
  DELETE FROM domain WHERE id = _domain_id;
  DELETE FROM org_extra WHERE domain_id = _domain_id;

  COMMIT;

  SELECT _domain_id AS domain_id, _org_id AS org_id, 1 AS deleted;
END$

DELIMITER ;
