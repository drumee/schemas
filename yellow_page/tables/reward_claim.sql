CREATE TABLE IF NOT EXISTS `reward_claim` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `uid` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT 'Reference to yp.entity.id',
  `campaign` varchar(64) NOT NULL DEFAULT 'free-storage' COMMENT 'utm_campaign that opened the flow',
  `status` varchar(16) NOT NULL DEFAULT 'emailed' COMMENT 'emailed | started | dropped | done',
  `step` varchar(16) DEFAULT NULL COMMENT 'Furthest card step reached: step1 | step2 | step3',
  `emailed_count` int(11) unsigned NOT NULL DEFAULT 0 COMMENT 'Times the campaign mail was accepted for this user',
  `last_emailed` int(11) unsigned NOT NULL DEFAULT 0,
  `ctime` int(11) unsigned NOT NULL DEFAULT 0,
  `mtime` int(11) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uni_uid` (`uid`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
COMMENT='Claim-reward campaign funnel — one row per user, status advances monotonically'
