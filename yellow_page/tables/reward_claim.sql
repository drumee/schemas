CREATE TABLE IF NOT EXISTS `reward_claim` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `uid` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT 'Reference to yp.entity.id',
  `campaign` varchar(64) NOT NULL DEFAULT 'free-storage' COMMENT 'utm_campaign that opened the flow',
  `status` varchar(16) NOT NULL DEFAULT 'emailed' COMMENT 'emailed | failed | clicked | started | left | dropped | missed | done',
  `step` varchar(16) DEFAULT NULL COMMENT 'Furthest card step reached: step1 | step2 | step3',
  `clicked_at` int(11) unsigned NOT NULL DEFAULT 0 COMMENT 'When the CTA was followed for the current attempt; 0 = not yet',
  `emailed_count` int(11) unsigned NOT NULL DEFAULT 0 COMMENT 'Times the campaign mail was accepted for this user',
  `completed_count` int(11) unsigned NOT NULL DEFAULT 0 COMMENT 'Times this user has ever finished; survives a re-arm. > 0 holds one of the campaign''s limited slots',
  `completed_at` int(11) unsigned NOT NULL DEFAULT 0 COMMENT 'When the slot was first won; start of the reward term. 0 = never won',
  `last_emailed` int(11) unsigned NOT NULL DEFAULT 0,
  `failed_at` int(11) unsigned NOT NULL DEFAULT 0 COMMENT 'When the MTA last refused this user''s address; 0 = never',
  `last_error` varchar(190) DEFAULT NULL COMMENT 'Why the last send to this user failed, e.g. "No such mailbox (550)". NULL once a later send succeeds',
  `ctime` int(11) unsigned NOT NULL DEFAULT 0,
  `mtime` int(11) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uni_uid` (`uid`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
COMMENT='Claim-reward campaign funnel — one row per user, status advances monotonically'
