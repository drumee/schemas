-- ALTER TABLE migration — existing hub databases
-- Adds the task_comment table (flat, chronological comment feed per task).
-- The author display name/avatar is resolved client-side from the hub member
-- list, so no FK to the drumate table is needed here.
--
-- Safe to run multiple times (CREATE TABLE IF NOT EXISTS). Apply to every hub
-- DB individually, e.g.:
--   mariadb <hub_db_name> < alter_task_comments.sql
--
-- The task_comment_create/list/update/delete procedures and the task_delete
-- cascade are deployed from common/procedures/task/ (procedures are replaced
-- wholesale on deploy, so no ALTER needed for them).

CREATE TABLE IF NOT EXISTS `task_comment` (
  `id`         varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `task_id`    varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `author_uid` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `body`       text NOT NULL,
  `edited`     tinyint(1) NOT NULL DEFAULT 0,
  `ctime`      int(11) NOT NULL DEFAULT 0,
  `mtime`      int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_task` (`task_id`),
  KEY `idx_author` (`author_uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
