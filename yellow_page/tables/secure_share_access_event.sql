CREATE TABLE IF NOT EXISTS `secure_share_access_event` (
  `sys_id`          int(11) unsigned NOT NULL AUTO_INCREMENT,
  `token_id`        varchar(80)      NOT NULL,
  `hub_id`          varchar(16)      CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `node_id`         varchar(16)      CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `recipient_email` varchar(512)     DEFAULT NULL,
  `actor_id`        varchar(16)      CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `socket_id`       varchar(32)      DEFAULT NULL,
  `entered_at`      int(11)          NOT NULL DEFAULT unix_timestamp(),
  `last_seen_at`    int(11)          NOT NULL DEFAULT unix_timestamp(),
  PRIMARY KEY (`sys_id`),
  KEY        `idx_token`        (`token_id`),
  KEY        `idx_token_socket` (`token_id`, `socket_id`),
  KEY        `idx_node`         (`node_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
