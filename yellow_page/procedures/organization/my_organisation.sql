DELIMITER $

-- =========================================================
-- my_organisation  (SINGULAR -- returns ONE row, deliberately)
-- =========================================================
-- THE organisation that owns this person's identity: their home.
--
-- Its plural sibling, my_organisations, lists every membership. This one
-- answers a different and narrower question, and every caller depends on the
-- answer being a single row:
--
--   drumate.update_ident   -- is this username free in the domain that owns
--                             the identity record we are about to rewrite?
--   channel.update_ticket  -- is this person helpdesk staff?
--   lib/env.js             -- which organisation does the SPA boot into?
--   contact.js             -- which host brands the outgoing mail?
--
-- IT USED TO BE SINGLE-ROW ONLY BY ACCIDENT OF AN INDEX. yp.privilege carried
-- UNIQUE (uid), so "the memberships of one person" and "one row" were the same
-- statement and this procedure never needed a LIMIT. Widening that key to
-- (uid, domain_id) -- see patches/2026-09-07-privilege-multi-domain.sql --
-- separated them, and the separation is silent: await_proc collapses one row
-- to a bare object but N rows to an ARRAY, so `my_org.domain_id` simply
-- becomes undefined at every call site the moment anyone holds a second
-- membership.
--
-- Most of those sites then fail CLOSED, which is merely broken. update_ident
-- fails OPEN: get_user_in_domain(ident, NULL) can no longer match its
-- username clause, so the uniqueness check silently passes and two accounts
-- in one domain can take the same name. That is the reason this file is
-- pinned rather than left to the caller.
--
-- HOME IS ALSO THE RIGHT ANSWER, not just a safe one. Every question above is
-- about the domain that owns the identity -- where the username must be
-- unique, which vhost the mail points at -- and that is precisely what
-- is_authoritative marks. A membership someone merely joined answers none of
-- them.
--
-- The ORDER BY, not a bare LIMIT: it makes the choice explicit rather than
-- leaving it to row order. IFNULL guards the column's 0 default.
DROP PROCEDURE IF EXISTS `my_organisation`$
CREATE PROCEDURE `my_organisation`(
   IN _uid VARCHAR(16) CHARACTER SET ascii
)
BEGIN
  SELECT
    r.*,
    r.link `url`,
    p.privilege
  FROM
    privilege p
  INNER JOIN organisation r ON r.domain_id = p.domain_id
  WHERE (p.domain_id <> 1 OR JSON_VALUE(r.metadata, "$.isOrganization")=1)
    AND p.uid = _uid
  ORDER BY IFNULL(p.is_authoritative, 0) DESC
  LIMIT 1;
END$

DELIMITER ;
