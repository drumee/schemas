-- Room for custom titles in yp.member_title (B2B Org Structure "+ New Title").
--
-- WIDENING ONLY. title was varchar(16) for the three built-in keys; a custom
-- title is stored by its display name (yp.org_title.name, varchar(64)). Every
-- existing value still fits, nothing is rewritten, and rolling the procs back
-- leaves a wider column that the old member_title_set never fills past 16.
ALTER TABLE `member_title`
  MODIFY COLUMN `title` varchar(64) NOT NULL
    COMMENT 'director | manager | executive, or a yp.org_title.name of the same domain';
