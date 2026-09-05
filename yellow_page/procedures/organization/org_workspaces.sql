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
-- organisation's inventory, which is what an org admin is asking for; the ACL
-- entry restricts the endpoint to admin/owner rather than filtering rows here.
-- A member-scoped listing already exists and is a different question:
-- desk.home, which reads the caller's OWN home directory.
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
