DELIMITER $

-- =========================================================
-- org_workspaces
-- =========================================================
-- Every workspace in an organisation, with the department it belongs to
-- (NULL = the org view's ungrouped row) and its member count.
--
-- COLUMN NAMES DELIBERATELY MIRROR A desk.home ROW -- hub_id / home_id /
-- filename / area / filetype. The org view's cards and the desk's existing
-- home grid open a workspace through the SAME client helper
-- (ui-team libs/workspace-target.js workspaceTarget(), which feeds
-- Wm.loadWorkspace), and that helper reads exactly those keys. Renaming them
-- here would mean a second copy of the open-a-workspace rules living in the
-- org view, which is the thing workspace-target.js was extracted to prevent.
--
-- SCOPED BY domain_id ONLY -- NOT by what the caller can see. This is the
-- organisation's inventory: every workspace in the domain, including private
-- ones the caller has no access to.
--
-- THE CALLER GATE IS THEREFORE THE SERVICE'S, AND IT MUST STAY ONE.
-- organization.overview runs this only for a caller at dom_admin_security or
-- above; a plain member gets org_summary (aggregate counts) and neither list.
-- An earlier revision of this header claimed the ACL restricted the endpoint
-- to admin/owner while the ACL in fact allowed any member to read -- which
-- disclosed the name and member count of every workspace in the organisation
-- to people who could not open one. If this procedure ever acquires a second
-- caller, that caller owns the same check.
--
-- Filtering per caller instead is the road not taken: per-workspace membership
-- is not in yp at all, it lives in each hub's OWN database, which is the whole
-- reason yp.workspace_members exists as a count-only rollup. A member-scoped
-- listing already exists and answers a different question anyway -- desk.home,
-- which reads the caller's own home directory.
--
-- The area set and the status exclusions are the same ones org_departments
-- counts with; see that procedure's header for why 'public' is not a
-- workspace.
--
-- members comes from the yp.workspace_members rollup and is EXACT per
-- workspace (it is a count of live grants in that hub's own database, owner
-- included). A workspace that has never had a membership mutation since the
-- rollup shipped has no row and reports 0 -- stale, not wrong, and reconciled
-- by patches/workspace_members_backfill.sql. That is the documented failure
-- mode of the rollup itself.
DROP PROCEDURE IF EXISTS `org_workspaces`$
CREATE PROCEDURE `org_workspaces`(
  IN _domain_id INT UNSIGNED
)
BEGIN
  SELECT
    h.id                    AS hub_id,
    h.id                    AS id,
    e.home_id               AS home_id,
    h.name                  AS filename,
    h.name                  AS name,
    h.hubname               AS hubname,
    e.area                  AS area,
    'hub'                   AS filetype,
    h.department_id         AS department_id,
    h.owner_id              AS owner_id,
    e.ctime                 AS ctime,
    e.mtime                 AS mtime,
    IFNULL(w.members, 0)    AS members
  FROM hub h
  INNER JOIN entity e
    ON e.id = h.id
   AND e.`type` = 'hub'
   AND e.area IN ('private', 'share', 'restricted')
   AND IFNULL(e.status, 'active') NOT IN ('deleted', 'archived', 'frozen')
  -- Plain equality. tables/hub.sql declares hub.id `CHARACTER SET ascii`,
  -- which would have made this a mixed-collation comparison -- but that
  -- declaration has never reached a live install (CREATE TABLE IF NOT EXISTS
  -- is a no-op where the table exists, and the factory dump that actually
  -- creates installs declares hub utf8mb4). Verified on stage 2026-09-04:
  -- hub.id and workspace_members.hub_id are BOTH utf8mb4_general_ci. An
  -- earlier revision wrapped h.id in CONVERT() to defend against the
  -- declared-but-untrue ascii; that only added a function call on a join key
  -- and encoded a false claim about the schema in a comment.
  LEFT JOIN workspace_members w ON w.hub_id = h.id
  WHERE h.domain_id = _domain_id
  ORDER BY h.department_id IS NULL, h.department_id, h.name;
END$

DELIMITER ;
