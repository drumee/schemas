DELIMITER $

DROP PROCEDURE IF EXISTS `mfs_merge_source_nodes`$
CREATE PROCEDURE `mfs_merge_source_nodes`()
BEGIN
  -- Every top level node of this workspace that a merge has to carry across,
  -- unpaged on purpose: a merge takes all of them or none, so a page boundary
  -- would silently leave part of the workspace behind.
  --
  -- Excluded, and why:
  --   __chat__ / __trash__ / __upload__  system folders created by
  --     mfs_init_folders, mfs_hub_chat_init and mfs_trash_init. They belong to
  --     the workspace machinery, not to its content, and the destination has
  --     its own.
  --   category 'hub'                     a workspace card. Those live on a
  --     desk, never inside a hub database, but mfs_move_all refuses them
  --     anyway - listing one here would report work that can never happen.
  --   hidden / deleted                   already out of sight; trashed rows
  --     stay with the workspace they were trashed in.
  --
  -- The root is reached by joining media to itself rather than through a
  -- DECLAREd variable. A local variable carries coercibility 2, the same as a
  -- column, so neither side yields and a database whose default collation
  -- differs from the column's raises ER_CANT_AGGREGATE_2COLLATIONS (1267) at
  -- CALL time. Two columns of one table can never disagree, and the '0'
  -- literal is coercible so it always takes the column's collation.
  SELECT
    m.id AS nid,
    m.user_filename AS filename,
    m.category AS category,
    IFNULL(m.filesize, 0) AS filesize
  FROM media m
    INNER JOIN media r ON m.parent_id = r.id
  WHERE r.parent_id = '0'
    AND m.category NOT IN ('hub', 'root')
    AND m.file_path NOT REGEXP '^/__(chat|trash|upload)__'
    AND m.`status` NOT IN ('hidden', 'deleted')
  ORDER BY m.`rank` ASC, m.user_filename ASC;
END$

DELIMITER ;
