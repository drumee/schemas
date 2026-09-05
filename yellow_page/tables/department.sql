-- File: schemas/yellow_page/tables/department.sql
-- Purpose: one row per DEPARTMENT — the grouping level the org view puts
--          between an organisation and its workspaces (Figma 104:33055).
--
-- WHY A TABLE AND NOT organisation.metadata. A department has to be JOINable
-- from yp.hub, because the org view's whole job is "give me every workspace in
-- this domain, grouped". Keeping the grouping in a JSON blob would push that
-- join into the service layer and make an ordinary listing O(workspaces) round
-- trips. It also has to survive its creator leaving, which a per-user blob does
-- not.
--
-- SCOPED BY domain_id, NOT BY OWNER. An organisation IS a domain in this schema
-- (yp.organisation is UNIQUE on domain_id), so domain_id is the tenant key
-- everywhere else — yp.hub, yp.entity.dom_id, yp.privilege, yp.quota — and a
-- department is a property of the organisation, not of whoever typed the name.
-- Departments in domain 1 (the default public domain) are therefore possible
-- but meaningless; the service refuses to create one there.
--
-- NAMES ARE UNIQUE WITHIN AN ORGANISATION, deliberately unlike
-- yp.organisation.name (see the note in organisation.sql for why THAT one had
-- its UNIQUE dropped). The distinction: org names are DERIVED server-side from
-- the payer's display name, so collisions were unavoidable and fatal mid-
-- provisioning. Department names are typed by an admin who is looking at the
-- existing list, so a collision is a mistake worth reporting — department_add
-- returns DEPARTMENT_EXISTS rather than signalling.
--
-- NO FOREIGN KEY to hub, and none to domain. Deleting a department must not
-- cascade into deleting workspaces — department_remove unsets
-- yp.hub.department_id instead, which returns those workspaces to the
-- ungrouped row the design already draws at the bottom of the org view.
--
-- `id` is a varchar(16) minted the same way every other late-model id here is
-- (LOWER(LEFT(REPLACE(UUID(),'-',''),16)) — cf. secure_share_create_access_
-- request), so it is opaque to the client and cannot be enumerated across
-- tenants. sys_id stays internal.

CREATE TABLE IF NOT EXISTS `department` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `id` varchar(16) NOT NULL
    COMMENT 'Opaque public id, minted from UUID()',
  `domain_id` int(11) unsigned NOT NULL
    COMMENT 'Reference to yp.domain.id — the organisation this belongs to',
  `name` varchar(255) NOT NULL
    COMMENT 'Display name, typed by an org admin',
  `rank` int(11) unsigned NOT NULL DEFAULT 0
    COMMENT 'Display order within the organisation; ties break on ctime',
  `owner_id` varchar(16) DEFAULT NULL
    COMMENT 'Reference to yp.drumate.id — who created it. Informational only.',
  `ctime` int(11) unsigned NOT NULL COMMENT 'Unix timestamp, created',
  `mtime` int(11) unsigned NOT NULL COMMENT 'Unix timestamp, last renamed',
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `domain_name` (`domain_id`,`name`),
  KEY `idx_domain` (`domain_id`,`rank`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
COMMENT='Departments — the grouping level between an organisation and its workspaces'
