CREATE TABLE IF NOT EXISTS `organisation` (
  `sys_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `domain_id` int(11) NOT NULL,
  `name` varchar(512) DEFAULT NULL,
  `link` varchar(1024) DEFAULT NULL,
  `ident` varchar(80) DEFAULT NULL,
  `password_level` int(4) DEFAULT 1,
  `dir_visibility` varchar(40) DEFAULT 'all',
  `dir_info` varchar(40) DEFAULT 'all',
  `double_auth` int(1) DEFAULT 0,
  `usb_auth` int(1) DEFAULT 0,
  `owner_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`metadata`)),
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `domain_id` (`domain_id`),
  UNIQUE KEY `id` (`id`),
  -- `name` is a display label, deliberately NOT unique: org names are derived
  -- from the payer's display name ("<fullname>'s Team"), so two accounts that
  -- share a display name collided here and killed org_provision with
  -- ER_DUP_ENTRY -- taking down the LAUNCH30 claim and, after the card was
  -- charged, the checkout webhook. Identity lives in id / domain_id / ident /
  -- link, which stay unique. See patches/2026-08-10-organisation-name-not-unique.sql.
  UNIQUE KEY `owner_id` (`owner_id`),
  UNIQUE KEY `ident` (`ident`,`domain_id`),
  UNIQUE KEY `link` (`link`) USING HASH
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
