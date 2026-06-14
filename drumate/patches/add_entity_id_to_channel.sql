-- Patch: add entity_id column to the channel table if it is missing.
-- Matches the id-column convention used elsewhere in the table (author_id,
-- message_id): varchar(16) ascii, nullable.
-- Safe to run multiple times (ADD COLUMN IF NOT EXISTS is idempotent in MariaDB 10.3+).

ALTER TABLE `channel`
  ADD COLUMN IF NOT EXISTS `entity_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL AFTER `author_id`;
