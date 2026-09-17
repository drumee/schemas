-- Attach workspaces to departments (Figma 104:33055, org view).
--
-- ADDITIVE AND NULLABLE, which is the whole point. Every workspace on a live
-- install keeps department_id NULL, and NULL is not a missing value here — it
-- is the design's own "ungrouped" state, the bare row of workspace cards the
-- org view draws below the last department section. So this deploys with no
-- backfill, and an organisation that never creates a department sees exactly
-- what it sees today.
--
-- A COLUMN ON hub RATHER THAN A MAPPING TABLE because the relationship is
-- one-to-many by product definition (a workspace sits in one department, the
-- way a file sits in one folder) and the org view's read is a single
-- LEFT JOIN either way. A mapping table would buy many-to-many nobody asked
-- for, at the cost of a second write path to keep consistent on hub delete.
--
-- NO FOREIGN KEY, matching yp.hub's existing style (owner_id and origin_id
-- carry none either). department_remove unsets this column explicitly, so the
-- integrity FK would enforce is enforced by the one procedure allowed to
-- delete a department.
--
-- The index is what makes the org view's "workspaces of this department" read
-- cheap; it is a covering prefix for the domain-scoped grouping in
-- org_workspaces.
--
-- NO EXPLICIT CHARACTER SET: the column inherits yp.hub's own
-- utf8mb4_general_ci, which is what hub.id and every other id column in yp
-- actually is (verified on stage 2026-09-04). tables/hub.sql in this repo
-- still declares `CHARACTER SET ascii`, but it has never been applied to a
-- live install -- CREATE TABLE IF NOT EXISTS is a no-op there, and the factory
-- dump that DOES create installs declares the table utf8mb4. Pinning ascii
-- here would have made this the only ascii column in the join graph.

ALTER TABLE `hub`
  ADD COLUMN IF NOT EXISTS `department_id` varchar(16)
    DEFAULT NULL
    COMMENT 'yp.department.id — NULL means ungrouped'
    AFTER `domain_id`,
  ADD INDEX IF NOT EXISTS `idx_department` (`domain_id`,`department_id`);
