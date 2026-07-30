CREATE TABLE IF NOT EXISTS `admin_access_request` (
  `sys_id`        int(11) unsigned NOT NULL AUTO_INCREMENT,
  `id`            varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `domain_id`     int(11) unsigned NOT NULL,
  `requester_uid` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `status`        enum('pending','dismissed','granted') NOT NULL DEFAULT 'pending',
  `ctime`         int(11) NOT NULL DEFAULT unix_timestamp(),
  `mtime`         int(11) NOT NULL DEFAULT unix_timestamp(),
  `dismissed_by`  varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `dismissed_at`  int(11) DEFAULT NULL,
  `granted_by`    varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `granted_at`    int(11) DEFAULT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `id` (`id`),
  KEY `idx_domain_status` (`domain_id`, `status`),
  KEY `idx_domain_requester` (`domain_id`, `requester_uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
