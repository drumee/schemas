CREATE TABLE `attachment` (
  `message_id` varchar(16) NOT NULL,
  `hub_id` varchar(16) NOT NULL,
  `rid` varchar(16) NOT NULL,
  `uid` varchar(16) NOT NULL,
  UNIQUE KEY `id` (`message_id`,`rid`,`hub_id`,`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
