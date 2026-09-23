DELIMITER $

-- Every invitation to this workspace that is still waiting for an answer, or
-- has been refused. Backs the "Pending Invitations" section of the workspace
-- Access panel.
--
-- ONE ROW PER PERSON, not per invitation, following pending_invites_by_domain.
-- Two admins inviting the same address to the same workspace write two token
-- rows -- the unique key is (email, method, inviter_id), so the second does not
-- REPLACE the first -- and the panel must not show the same person twice with
-- two different answers beside them. The newest invitation is the live one, and
-- it is the one reported.
--
-- NEWEST BY sys_id, NOT ctime. token_hub_invite_add is a REPLACE, so a re-send
-- deletes and re-inserts and always takes a higher auto-increment; ctime is
-- second-resolution and two invitations sent in the same second would tie.
-- sys_id cannot tie.
--
-- 🚨 THE ORDER OF THE FILTER AND THE DEDUPE MATTERS. Both live in the
-- subquery, so the newest row is chosen from among the rows that qualify. Put
-- the expiry test outside instead and a person whose newest invitation has
-- lapsed disappears from the panel entirely, taking an older still-valid
-- invitation with them -- they would read as never invited.
--
-- STATUSES, and why only two are listed:
--   active    -> reported as 'pending'. Waiting for an answer.
--   declined  -> reported as 'declined'. They said no.
--   accepted  -> ABSENT on purpose. They are a member now, and a member belongs
--                in the Members section, not in Pending Invitations. This is
--                the whole reason the panel can show both lists without them
--                overlapping.
--
-- EXPIRY. Invitations are minted with a 7-day expiry and a lapsed one is not
-- pending -- nobody can redeem it -- so it is not listed. A declined row is
-- exempt because token_hub_invite_decline zeroes its expiry precisely so the
-- refusal survives; the test is written to cover both without special-casing.
--
-- 🚨 THIS DOES NOT KNOW WHO IS ALREADY A MEMBER, and cannot. Membership lives
-- in the workspace's own database (f_*), not in yp, and a yp procedure cannot
-- reach it without knowing the db_name. An address added straight to the
-- workspace by add_contributors, while an old invitation of its own was still
-- active, would therefore appear in BOTH lists. The caller (hub.invitations)
-- drops any row whose address matches a current member -- it already holds the
-- member list to render the other half of the panel.
--
-- COLLATIONS DIFFER AND THE JOINS ARE STILL PLAIN EQUALITY. token is
-- utf8mb3_general_ci while drumate.id and drumate.email are ascii_general_ci.
-- ascii is a subset of utf8mb3, so MariaDB coerces upward rather than raising
-- ER_CANT_AGGREGATE_2COLLATIONS -- verified on stage (11.8.6) rather than
-- assumed, because the two-column case does raise it when neither side is a
-- superset. An index seek on drumate.email is lost to the conversion; the row
-- count here is per-workspace invitations, so that is not worth an explicit
-- CONVERT that would mangle a non-ascii address into '?' and match the wrong
-- account.
--
-- THE INVITEE MAY HAVE NO ACCOUNT -- that is the common case for an invitation
-- -- so the join is LEFT and every invitee column can be NULL. The panel falls
-- back to the address, which is the only name it has for them.
--
-- THE SECRET IS NOT RETURNED. An admin listing has no use for it: re-sending
-- goes through hub.invite, which mints a fresh token. Handing the redeem secret
-- to every admin who opens the panel would put a credential that grants
-- workspace membership into an ordinary list response.
DROP PROCEDURE IF EXISTS `hub_invitations`$
CREATE PROCEDURE `hub_invitations`(
  IN _hub_id VARCHAR(16)
)
BEGIN
  DECLARE _method VARCHAR(80);

  SET _method = CONCAT('hub_invite:', _hub_id);

  SELECT
    t.email,
    IF(t.`status` = 'declined', 'declined', 'pending')      AS `status`,
    t.ctime,
    JSON_VALUE(t.metadata, '$.permission')                  AS permission,
    d.id                                                    AS invitee_uid,
    d.firstname                                             AS invitee_firstname,
    d.lastname                                              AS invitee_lastname,
    d.fullname                                              AS invitee_fullname,
    d.avatar                                                AS invitee_avatar,
    t.inviter_id,
    i.firstname                                             AS inviter_firstname,
    i.lastname                                              AS inviter_lastname,
    i.fullname                                              AS inviter_fullname
  FROM token t
  JOIN (
    SELECT MAX(sys_id) AS sys_id
      FROM token
     WHERE method = _method
       AND `status` IN ('active', 'declined')
       AND (`status` = 'declined' OR expiry = 0 OR expiry > UNIX_TIMESTAMP())
     GROUP BY email
  ) newest ON newest.sys_id = t.sys_id
  LEFT JOIN drumate d ON d.email = t.email
  LEFT JOIN drumate i ON i.id = t.inviter_id
  ORDER BY t.ctime DESC, t.sys_id DESC;
END$

DELIMITER ;
