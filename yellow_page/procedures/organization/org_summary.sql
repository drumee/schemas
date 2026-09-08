DELIMITER $

-- =========================================================
-- org_summary
-- =========================================================
-- The org-dropdown header (Figma 104:33055): the organisation row plus the two
-- counts drawn beside its name -- "3 [cube]" departments and "24 [people]"
-- members.
--
-- member_count IS EXACT AND IS THE ORGANISATION'S, not the caller's. It counts
-- yp.privilege rows for the domain, which is the same definition
-- server-team payment.js already uses for its seat check -- so the number in
-- the dropdown and the number the billing page enforces against cannot drift.
-- System accounts and archived entities are excluded there and are excluded
-- here for the same reason: they hold a privilege row but are not people the
-- org is paying for.
--
-- Returns exactly one row. A caller still on domain 1 has no organisation, and
-- gets an empty result rather than a fabricated one -- the client is expected
-- to fall back to the personal-desk chrome, which is what it renders today.
-- That is the MAJORITY of accounts, not an edge case: 231 of 294 on stage.
--
-- DELIBERATELY STRICTER THAN my_organisation, and not by oversight. That
-- procedure also returns a domain-1 row when it carries
-- metadata.isOrganization = 1 -- a flag that exists so the shared server domain
-- can own its own branding (name, wallpaper). On stage exactly one row has it,
-- and it makes "Drumee Stage Server" the organisation of every free account.
-- Honouring it here would hand all 231 of them a department tree inside a
-- domain none of them owns, and an org chip naming the server they happen to
-- be hosted on. billing (checkout.js needsOrgBootstrap) and payment.js both
-- draw the line at domain_id > 1; so does this, and so does the client's
-- libs/org-overview inOrganization().
DROP PROCEDURE IF EXISTS `org_summary`$
CREATE PROCEDURE `org_summary`(
  IN _domain_id INT UNSIGNED
)
proc: BEGIN
  IF IFNULL(_domain_id, 0) <= 1 THEN
    LEAVE proc;
  END IF;

  SELECT
    o.id,
    o.domain_id,
    o.name,
    o.link,
    o.link                       AS url,
    o.ident,
    o.owner_id,
    o.metadata,
    (SELECT COUNT(*) FROM department d
      WHERE d.domain_id = _domain_id)      AS department_count,
    (SELECT COUNT(*)
       FROM hub h
       INNER JOIN entity e
         ON e.id = h.id
        AND e.`type` = 'hub'
        AND e.area IN ('private', 'share', 'restricted')
        AND IFNULL(e.status, 'active') NOT IN ('deleted', 'archived', 'frozen')
      WHERE h.domain_id = _domain_id)      AS workspace_count,
    (SELECT COUNT(*)
       FROM privilege p
       INNER JOIN drumate d2 ON p.uid = d2.id
       INNER JOIN entity   e2 ON d2.id = e2.id
      WHERE p.domain_id = _domain_id
        AND COALESCE(JSON_VALUE(d2.profile, '$.category'), '') <> 'system'
        AND e2.status <> 'archived')       AS member_count
  FROM organisation o
  WHERE o.domain_id = _domain_id
  LIMIT 1;
END$

DELIMITER ;
