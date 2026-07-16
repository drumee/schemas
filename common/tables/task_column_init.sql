-- Marks a task folder scope as "columns initialized". The first time a scope's
-- board is opened, task_column_list seeds the four built-in columns as real
-- rows and records the scope here, so it is NEVER auto-seeded again. That lets
-- the built-ins be renamed / recoloured / reordered / DELETED and have those
-- changes persist (without a marker, a deleted built-in would just reappear on
-- the next open). scope_key = the folder nid, or '' for the workspace root
-- (NULL nid can't be a primary key).
CREATE TABLE IF NOT EXISTS `task_column_init` (
  `scope_key` VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `ctime`     INT(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`scope_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
