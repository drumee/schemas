CREATE TABLE `notice` (
  `id` int(6) unsigned NOT NULL AUTO_INCREMENT,
  `dest_email` varchar(255) NOT NULL DEFAULT '',
  `category` enum('invitation','request','rendezvous','event','security','other') NOT NULL DEFAULT 'invitation',
  `sender_id` varbinary(16) NOT NULL,
  `dest_id` varbinary(16) NOT NULL,
  `link_id` varbinary(16) NOT NULL,
  `link_type` enum('community','event','poll') NOT NULL DEFAULT 'community',
  `status` enum('sent','received','open','declined') NOT NULL DEFAULT 'sent',
  `ctime` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `status` (`status`),
  KEY `subject_id` (`link_id`),
  KEY `subject_type` (`link_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci
