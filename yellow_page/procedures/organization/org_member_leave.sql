DELIMITER $

-- =========================================================
-- org_member_leave
--
-- Undo org_member_join: the account goes back to the personal domain (1) with
-- the privilege tier it had before, and the '$.org_join' marker is dropped.
-- Called by the server when a workspace-joined member leaves, or is removed
-- from, the last internal workspace of that organisation. Nothing in the
-- account's own data moves; only its domain bookkeeping does.
-- =========================================================
DROP PROCEDURE IF EXISTS `org_member_leave`$
CREATE PROCEDURE `org_member_leave`(
  IN _uid            VARCHAR(16) CHARACTER SET ascii,
  IN _prev_privilege INT
)
BEGIN
  CALL domain_grant(1, IFNULL(_prev_privilege, 1), _uid, 0);

  UPDATE drumate
     SET profile = JSON_REMOVE(profile, '$.org_join')
   WHERE id = _uid AND profile IS NOT NULL;

  SELECT d.id, d.domain_id, p.privilege
    FROM drumate d
    LEFT JOIN privilege p ON p.uid = d.id
   WHERE d.id = _uid;
END $

DELIMITER ;
