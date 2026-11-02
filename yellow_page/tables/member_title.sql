-- File: schemas/yellow_page/tables/member_title.sql
-- Purpose: one row per titled person per ORGANISATION — the Title column of
--          the Admin Console Member tab (Director / Manager / Executive).
--
-- KEYED BY (domain_id, uid), NOT BY uid. A title is the label an organisation
-- gives a person, so the same person can carry different titles in two orgs
-- and neither org sees the other's. domain_id is the tenant key everywhere in
-- yp (hub, entity.dom_id, privilege, department). Workspace collaborators from
-- another domain can be titled too: their row lives under the CALLER's domain.
--
-- A ROW EXISTS ONLY WHILE A TITLE IS SET. Clearing deletes the row
-- (member_title_set with ''), so "no title" never has two spellings.
--
-- title IS A varchar CHECKED BY member_title_set, not an ENUM: adding a title
-- later is a proc change, not an ALTER on a live table.
--
-- NO FOREIGN KEYS, matching yp's style (department, hub). A deleted account
-- leaves an orphan row that no listing can reach, because member_title_list
-- only answers for uids the caller already has.

CREATE TABLE IF NOT EXISTS `member_title` (
  `domain_id` int(11) unsigned NOT NULL
    COMMENT 'Reference to yp.domain.id — the organisation that set the title',
  `uid` varchar(16) NOT NULL
    COMMENT 'Reference to yp.drumate.id — the titled person',
  `title` varchar(16) NOT NULL
    COMMENT 'director | manager | executive (validated by member_title_set)',
  `by_id` varchar(16) DEFAULT NULL
    COMMENT 'Reference to yp.drumate.id — who set it. Informational only.',
  `mtime` int(11) unsigned NOT NULL COMMENT 'Unix timestamp, last set',
  PRIMARY KEY (`domain_id`,`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
COMMENT='Member titles per organisation — Admin Console Member tab';
