-- ALTER TABLE migration — existing hub databases
-- Make task_comment_reaction.emoji byte-exact (utf8mb4_bin).
--
-- Root cause: the column inherited the table's utf8mb4_general_ci collation.
-- Under that collation (notably on older MariaDB/MySQL builds) DISTINCT EMOJIS
-- COLLATE AS EQUAL. With PRIMARY KEY (comment_id, uid, emoji) and the toggle
-- proc's `emoji = _emoji`, reacting with a second emoji matched the first
-- reaction's row → it deleted that reaction and could not insert the new one.
-- Net effect for the user: only one reaction per comment could stick, and
-- picking another reaction silently removed the previous chip.
--
-- utf8mb4_bin compares byte-exact, so every distinct emoji is its own row and a
-- user's reactions accumulate as an array.
--
-- Idempotent (skips when already utf8mb4_bin). Apply to every hub DB, e.g.:
--   mariadb <hub_db_name> < alter_task_comment_reaction_emoji_bin.sql

SET @needs = (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA  = DATABASE()
    AND TABLE_NAME    = 'task_comment_reaction'
    AND COLUMN_NAME   = 'emoji'
    AND COLLATION_NAME <> 'utf8mb4_bin'
);

SET @sql = IF(
  @needs = 1,
  'ALTER TABLE `task_comment_reaction` MODIFY `emoji` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL',
  'SELECT "task_comment_reaction.emoji already utf8mb4_bin — skipped" AS info'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
