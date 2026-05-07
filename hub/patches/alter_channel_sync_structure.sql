ALTER TABLE `channel`
  DROP COLUMN IF EXISTS `entity_id`,
  MODIFY COLUMN `author_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  MODIFY COLUMN `message_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  MODIFY COLUMN `thread_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  MODIFY COLUMN `mention_ids` JSON NULL;
