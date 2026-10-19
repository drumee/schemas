-- Folder chat topics: an indexed, virtual topic_id on channel so # General
-- (topic_id IS NULL) and a topic (topic_id = ?) filter in SQL on an index
-- instead of JSON-parsing every row. Idempotent. Hub DBs only.
ALTER TABLE `channel`
  ADD COLUMN IF NOT EXISTS `topic_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci
    AS (JSON_VALUE(`metadata`, '$._topic_id')) VIRTUAL;
ALTER TABLE `channel`
  ADD INDEX IF NOT EXISTS `channel_topic_idx` (`topic_id`, `sys_id`);
