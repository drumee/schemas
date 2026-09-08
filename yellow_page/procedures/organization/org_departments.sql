DELIMITER $

-- =========================================================
-- org_departments
-- =========================================================
-- The department sections of the org view (Figma 104:33055): name, workspace
-- count, member count, in display order.
--
-- EMPTY DEPARTMENTS ARE RETURNED, with workspace_count 0. The design draws
-- "Department-name 3 / 0 workspace" as a header and a "+ New workspace" button
-- with no grid under it, so a department that filtered itself out the moment it
-- was created would be a department nobody could ever put anything into.
-- Hence LEFT JOIN, not INNER.
--
-- workspace_count IS EXACT. It counts yp.hub rows joined to an active
-- yp.entity in the collaborative areas -- the same set the desk's own sidebar
-- admits (private | share | restricted; see the workspace-list filter in
-- ui-team desk/workspace-list/index.js). 'public' is excluded on purpose: in
-- domain 1 that area holds system hubs (backoffice, stripe, reward, Onboarding)
-- and in an org domain it holds the organisation entity itself, none of which
-- are workspaces anybody opens.
--
-- member_count IS A SUM, NOT A DISTINCT COUNT, and the client must label it as
-- such. Per-workspace membership does not live in yp at all -- it is a
-- permission row inside each hub's OWN database (see the header of
-- tables/workspace_members.sql, which exists precisely so read paths never
-- crawl those databases). yp.workspace_members therefore gives a count per
-- workspace and no way to tell whether the same person holds grants in two of
-- them, so somebody in three workspaces of one department counts three times.
-- The alternative -- visiting every hub database on every org-view render --
-- is the cost that rollup was built to avoid. Exact distinct membership is
-- available at ORG level (org_summary counts yp.privilege) and at WORKSPACE
-- level (org_workspaces reads the rollup directly); it is only this middle
-- level that is an approximation.
DROP PROCEDURE IF EXISTS `org_departments`$
CREATE PROCEDURE `org_departments`(
  IN _domain_id INT UNSIGNED
)
BEGIN
  -- The workspace set is resolved in a derived table rather than as extra ON
  -- clauses hanging off the LEFT JOIN. Filtering hub-by-entity in the outer
  -- query needs a WHERE, and a WHERE on the null-extended side of a LEFT JOIN
  -- turns it back into an INNER one -- a department whose only hubs were all
  -- deleted would have vanished from the org view instead of showing as empty.
  SELECT
    d.id,
    d.name,
    d.`rank`,
    d.owner_id,
    d.ctime,
    d.mtime,
    COUNT(ws.id)                          AS workspace_count,
    IFNULL(SUM(ws.members), 0)            AS member_count
  FROM department d
  LEFT JOIN (
    SELECT
      h.id,
      h.domain_id,
      h.department_id,
      IFNULL(w.members, 0) AS members
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
  ) ws
    ON ws.department_id = d.id
   AND ws.domain_id     = d.domain_id
  WHERE d.domain_id = _domain_id
  GROUP BY d.sys_id, d.id, d.name, d.`rank`, d.owner_id, d.ctime, d.mtime
  ORDER BY d.`rank` ASC, d.ctime ASC;
END$

DELIMITER ;
