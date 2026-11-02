DELIMITER $

-- =========================================================
-- org_member_join
--
-- Make an existing personal account (domain 1) a MEMBER of an organisation
-- because they joined one of its internal workspaces. The move itself is
-- domain_grant (privilege row + drumate/vhost/entity dom, tier 1 =
-- Remit.dom_member); on top of it the account remembers HOW it got in, so
-- org_member_leave can undo exactly this and nothing else:
--
--   profile.$.org_join = { source:'workspace', hub_id, domain_id,
--                          prev_privilege, since }
--
-- Accounts created by the admin console (member_add) carry no marker and are
-- never moved back by the leave path. The server decides whether to call this
-- (org_join_context); this procedure only performs the move.
-- =========================================================
DROP PROCEDURE IF EXISTS `org_member_join`$
CREATE PROCEDURE `org_member_join`(
  IN _uid            VARCHAR(16) CHARACTER SET ascii,
  IN _domain_id      INT UNSIGNED,
  IN _hub_id         VARCHAR(16) CHARACTER SET ascii,
  IN _prev_privilege INT
)
BEGIN
  CALL domain_grant(_domain_id, 1, _uid, 0);

  UPDATE drumate
     SET profile = JSON_SET(
       IFNULL(profile, '{}'),
       '$.org_join',
       JSON_OBJECT(
         'source', 'workspace',
         'hub_id', _hub_id,
         'domain_id', _domain_id,
         'prev_privilege', IFNULL(_prev_privilege, 1),
         'since', UNIX_TIMESTAMP()
       )
     )
   WHERE id = _uid;

  SELECT d.id, d.domain_id, p.privilege
    FROM drumate d
    LEFT JOIN privilege p ON p.uid = d.id
   WHERE d.id = _uid;
END $

DELIMITER ;
