CREATE TABLE IF NOT EXISTS `task_label` (
  `task_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `label_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `ctime` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`task_id`, `label_id`),
  KEY `idx_label_id` (`label_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
-- Cascade delete of task_label rows is handled explicitly in the task_delete and label_delete SPs.
