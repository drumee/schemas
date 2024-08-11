

DROP TABLE IF EXISTS `__vfs__`;
CREATE TABLE `__vfs__` (
  `id` varchar(16) DEFAULT NULL,
  `origin_id` varchar(16) DEFAULT NULL,
  `owner_id` varchar(16) NOT NULL,
  `host_id` varchar(16) NOT NULL,
  `file_path` varchar(512) DEFAULT NULL,
  `user_filename` varchar(128) DEFAULT NULL,
  `parent_id` varchar(16) DEFAULT '',
  `parent_path` varchar(1024) NOT NULL,
  `extension` varchar(100) NOT NULL DEFAULT '',
  `mimetype` varchar(100) NOT NULL,
  `category` varchar(16) NOT NULL,
  `isalink` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `filesize` int(20) unsigned NOT NULL DEFAULT '0',
  `geometry` varchar(200) NOT NULL DEFAULT '0x0',
  `publish_time` int(11) unsigned NOT NULL DEFAULT '0',
  `upload_time` int(11) unsigned NOT NULL DEFAULT '0',
  `last_download` int(11) unsigned NOT NULL DEFAULT '0',
  `download_count` mediumint(8) unsigned NOT NULL DEFAULT '0',
  `metadata` varchar(1024) DEFAULT NULL,
  `caption` varchar(1024) DEFAULT NULL,
  `status` varchar(20) NOT NULL DEFAULT 'active',
  `approval` enum('submitted','verified','validated') NOT NULL,
  `rank` tinyint(4) NOT NULL DEFAULT '0',
  `relative_path` varchar(1024) NOT NULL,
  `lvl` int(11) DEFAULT '0',
  `is_checked` tinyint(1) DEFAULT '0',
  `is_matched` tinyint(1) DEFAULT '0',
  `is_delete` tinyint(1) DEFAULT '0',
  `is_update` tinyint(1) DEFAULT '0',
  `update_file_path` varchar(1024) DEFAULT NULL,
  `update_parent_path` varchar(1024) DEFAULT NULL,
  `new_id` varchar(16) DEFAULT NULL,
  `new_parent_id` varchar(16) DEFAULT NULL,
  `new_file_path` varchar(1024) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `alias`;
CREATE TABLE `alias` (
  `sn` int(6) NOT NULL AUTO_INCREMENT,
  `id` varbinary(16) NOT NULL,
  `ident` varchar(40) NOT NULL DEFAULT '',
  `vhost` varchar(250) NOT NULL,
  `scope` enum('alternate','user','main') NOT NULL,
  `domain` varchar(128) NOT NULL,
  PRIMARY KEY (`sn`),
  UNIQUE KEY `vhost` (`vhost`),
  UNIQUE KEY `sn` (`sn`),
  KEY `scope` (`scope`),
  KEY `domain` (`domain`),
  KEY `ident` (`ident`),
  KEY `id` (`id`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8;


--
-- Table structure for table `area`
--

DROP TABLE IF EXISTS `area`;
CREATE TABLE `area` (
  `id` varchar(16) NOT NULL,
  `owner_id` varchar(16) NOT NULL,
  `level` enum('public','restricted','private','personal','system','dummy') NOT NULL,
  PRIMARY KEY (`id`),
  KEY `level` (`level`),
  KEY `owner_id` (`owner_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


--
-- Table structure for table `area_bak`
--

DROP TABLE IF EXISTS `area_bak`;
CREATE TABLE `area_bak` (
  `id` varchar(36) CHARACTER SET ascii NOT NULL,
  `drumate_id` varchar(16) CHARACTER SET ascii NOT NULL,
  `hub_id` varchar(16) CHARACTER SET ascii NOT NULL,
  `level` enum('public','restricted','private','personal','system','dummy') CHARACTER SET ascii NOT NULL,
  PRIMARY KEY (`id`),
  KEY `drumate_id` (`drumate_id`),
  KEY `level` (`level`),
  KEY `hub_id` (`hub_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


--
-- Table structure for table `avatar`
--

DROP TABLE IF EXISTS `avatar`;
CREATE TABLE `avatar` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `drumate_id` varbinary(16) NOT NULL,
  `location` varchar(1024) DEFAULT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `drumate_id` (`drumate_id`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8;


--
-- Table structure for table `cities`
--

DROP TABLE IF EXISTS `cities`;
CREATE TABLE `cities` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(30) NOT NULL,
  `state_id` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1;


--
-- Table structure for table `city`
--

DROP TABLE IF EXISTS `city`;
CREATE TABLE `city` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `cc_iso` varchar(2) DEFAULT NULL,
  `name_ascii` varchar(100) DEFAULT NULL,
  `name_utf8` varchar(100) DEFAULT NULL,
  `region` varchar(100) DEFAULT NULL,
  `lat` int(8) DEFAULT NULL,
  `lng` int(8) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `name_ascii` (`name_ascii`),
  FULLTEXT KEY `name_utf8` (`name_utf8`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8;


--
-- Table structure for table `community`
--

DROP TABLE IF EXISTS `community`;
CREATE TABLE `community` (
  `id` varbinary(16) NOT NULL,
  `owner_id` varbinary(16) NOT NULL,
  `dmail` varchar(255) COLLATE utf8_bin NOT NULL,
  `cname` varchar(80) CHARACTER SET utf8 NOT NULL,
  `create_time` int(11) NOT NULL,
  `photo` varchar(255) CHARACTER SET utf8 NOT NULL,
  `photo_banner` varbinary(16) NOT NULL,
  `slide` varchar(255) COLLATE utf8_bin NOT NULL,
  `theme` varbinary(16) NOT NULL,
  `update_time` int(11) unsigned NOT NULL,
  `mtime` int(11) NOT NULL,
  `on_banner` varchar(8) COLLATE utf8_bin NOT NULL DEFAULT 'off',
  `on_directory` varchar(8) COLLATE utf8_bin NOT NULL DEFAULT 'off',
  `on_profile` varchar(8) COLLATE utf8_bin NOT NULL DEFAULT 'off',
  `autojoin` varchar(8) COLLATE utf8_bin NOT NULL DEFAULT 'off',
  `description` text CHARACTER SET utf8 NOT NULL,
  `keywords` text CHARACTER SET utf8 NOT NULL,
  `permission` tinyint(4) unsigned NOT NULL,
  PRIMARY KEY (`id`),
  KEY `owner_id` (`owner_id`),
  KEY `dmail` (`dmail`),
  KEY `photo_banner` (`photo_banner`),
  KEY `default_perm` (`permission`),
  FULLTEXT KEY `cname` (`cname`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;


--
-- Table structure for table `corporate`
--

DROP TABLE IF EXISTS `corporate`;
CREATE TABLE `corporate` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `owner_id` varchar(16) NOT NULL,
  `entity_id` varchar(16) NOT NULL,
  `expiry_time` int(11) NOT NULL DEFAULT '0',
  `status` enum('active','invite','delete') DEFAULT 'invite',
  `ctime` int(11) DEFAULT NULL,
  `utime` int(11) DEFAULT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `pkey` (`owner_id`,`entity_id`),
  KEY `entity_id` (`entity_id`),
  KEY `owner_id` (`owner_id`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8;


--
-- Table structure for table `countries`
--

DROP TABLE IF EXISTS `countries`;
CREATE TABLE `countries` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `sortname` varchar(3) NOT NULL,
  `name` varchar(150) NOT NULL,
  `phonecode` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8;


--
-- Table structure for table `country`
--

DROP TABLE IF EXISTS `country`;
CREATE TABLE `country` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `cc_iso` varchar(3) NOT NULL,
  `tld` varchar(3) CHARACTER SET ascii NOT NULL,
  `fr` varchar(200) NOT NULL,
  `en` varchar(200) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `tld` (`tld`),
  FULLTEXT KEY `lang` (`fr`,`en`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8;


--
-- Table structure for table `disk_usage`
--

DROP TABLE IF EXISTS `disk_usage`;
CREATE TABLE `disk_usage` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `hub_id` varchar(16) NOT NULL,
  `size` float DEFAULT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `hub_id` (`hub_id`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8;


--
-- Table structure for table `domain`
--

DROP TABLE IF EXISTS `domain`;
CREATE TABLE `domain` (
  `sn` int(6) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `alias` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  PRIMARY KEY (`sn`),
  UNIQUE KEY `name` (`name`),
  KEY `type` (`alias`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;


--
-- Table structure for table `domains`
--

DROP TABLE IF EXISTS `domains`;
CREATE TABLE `domains` (
  `id` int(6) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


--
-- Table structure for table `drumate`
--

DROP TABLE IF EXISTS `drumate`;
CREATE TABLE `drumate` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `id` varchar(16) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `dmail` varchar(512) NOT NULL DEFAULT '',
  `photo_pub` varchar(255) NOT NULL DEFAULT '',
  `photo_res` varchar(255) NOT NULL DEFAULT '',
  `photo_prv` varchar(255) NOT NULL DEFAULT '',
  `photo_banner` varchar(16) DEFAULT NULL,
  `fingerprint` varchar(128) NOT NULL DEFAULT '',
  `remit` tinyint(4) NOT NULL DEFAULT '0',
  `activation_key` varchar(255) NOT NULL DEFAULT '',
  `activation_time` int(11) unsigned DEFAULT NULL,
  `connexion_time` int(11) unsigned DEFAULT NULL,
  `pw_changed` int(11) DEFAULT NULL,
  `ip_pw_changing` varchar(5) DEFAULT NULL,
  `first_cnx` tinyint(1) NOT NULL DEFAULT '1',
  `country` varchar(150) DEFAULT NULL,
  `city` varchar(80) DEFAULT NULL,
  `backup_email` varchar(255) NOT NULL DEFAULT '',
  `mobile` varchar(30) CHARACTER SET ascii DEFAULT NULL,
  `category` enum('individual','professional','worker','corporate') DEFAULT 'individual',
  `membership` enum('founder','shareholder','vip','staff','premium','free') NOT NULL DEFAULT 'free',
  `profile` varchar(16000) DEFAULT NULL,
  `quota` varchar(4000) CHARACTER SET ascii NOT NULL DEFAULT '{"disk": 500000000, "hub":50}',
  `gender` char(200) GENERATED ALWAYS AS (json_unquote(json_extract(`profile`,'$.gender'))) VIRTUAL,
  `firstname` char(200) GENERATED ALWAYS AS (json_unquote(json_extract(`profile`,'$.firstname'))) VIRTUAL,
  `lastname` char(200) GENERATED ALWAYS AS (json_unquote(json_extract(`profile`,'$.lastname'))) VIRTUAL,
  `registration_verified` int(4) NOT NULL DEFAULT '0',
  `unverified_email` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `id` (`id`),
  KEY `dmail` (`dmail`),
  KEY `ip_pw_changing` (`ip_pw_changing`),
  KEY `remit` (`remit`),
  KEY `fingerprint` (`fingerprint`),
  KEY `photo_banner` (`photo_banner`),
  KEY `country` (`country`),
  KEY `city` (`city`),
  KEY `back_email` (`backup_email`),
  KEY `category` (`category`),
  KEY `mobile` (`mobile`),
  KEY `membership` (`membership`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8;



--
-- Table structure for table `entity`
--

DROP TABLE IF EXISTS `entity`;
CREATE TABLE `entity` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `id` varchar(16) DEFAULT NULL,
  `ident` varchar(80) NOT NULL,
  `vhost` varchar(512) NOT NULL DEFAULT '',
  `db_name` varchar(255) CHARACTER SET ascii NOT NULL,
  `db_host` varchar(255) NOT NULL DEFAULT '',
  `fs_host` varchar(255) NOT NULL DEFAULT '',
  `home_dir` varchar(512) NOT NULL DEFAULT '',
  `default_lang` varchar(12) CHARACTER SET ascii NOT NULL DEFAULT 'fr',
  `home_layout` varchar(128) NOT NULL DEFAULT '',
  `homepage` varchar(1600) CHARACTER SET ascii NOT NULL DEFAULT '{}' COMMENT 'TO BE REMOVED',
  `overview` mediumtext,
  `layout` mediumtext COMMENT 'TO BE REMOVED',
  `type` enum('community','hub','drumate','shop','blog','forum','guest','dummy') DEFAULT NULL,
  `area` enum('public','shared','limited','restricted','private','personal','system','dummy','pool') DEFAULT NULL,
  `domain` varchar(255) DEFAULT 'drumee.com',
  `area_id` varbinary(16) DEFAULT NULL,
  `headline` varchar(255) DEFAULT NULL,
  `status` enum('active','frozen','deleted','archived','system','locked','online','offline','hidden') DEFAULT NULL,
  `accessibility` enum('open','membership','personal') DEFAULT 'open',
  `ctime` int(11) unsigned NOT NULL,
  `mtime` int(11) unsigned NOT NULL,
  `space` float NOT NULL DEFAULT '0',
  `menu` varchar(255) CHARACTER SET ascii DEFAULT NULL COMMENT 'Pointer to the default menu',
  `settings` mediumtext NOT NULL,
  `icon` varchar(500) CHARACTER SET ascii NOT NULL DEFAULT 'https://fonts.drumee.name/static/images/drumee/logo.png',
  `frozen_time` int(11) unsigned DEFAULT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `ident` (`ident`,`domain`),
  KEY `category` (`type`),
  KEY `db_name` (`db_name`),
  KEY `ctime` (`ctime`,`mtime`),
  KEY `home_layout` (`home_layout`),
  KEY `status` (`status`),
  KEY `home_dir` (`home_dir`(333)),
  KEY `area_id` (`area_id`),
  KEY `default_lang` (`default_lang`),
  KEY `icon` (`icon`),
  FULLTEXT KEY `settings` (`settings`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8;


--
-- Table structure for table `error`
--

DROP TABLE IF EXISTS `error`;
CREATE TABLE `error` (
  `code` varchar(40) CHARACTER SET ascii NOT NULL,
  `level` enum('request','security','critical','system','bug','user') COLLATE utf8_unicode_ci NOT NULL DEFAULT 'user',
  `http_code` int(11) NOT NULL DEFAULT '500',
  PRIMARY KEY (`code`),
  KEY `level` (`level`,`http_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;




--
-- Table structure for table `files_formats`
--

DROP TABLE IF EXISTS `files_formats`;
CREATE TABLE `files_formats` (
  `key` varchar(64) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL,
  `extension` varchar(16) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL,
  `category` varchar(16) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL,
  `mimetype` varchar(64) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL,
  `capability` varchar(8) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL,
  `description` varchar(512) CHARACTER SET utf8 NOT NULL DEFAULT '*',
  PRIMARY KEY (`key`),
  KEY `category` (`category`,`mimetype`,`capability`),
  FULLTEXT KEY `description` (`description`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;


--
-- Table structure for table `font`
--

DROP TABLE IF EXISTS `font`;
CREATE TABLE `font` (
  `sys_id` int(6) NOT NULL AUTO_INCREMENT,
  `family` varchar(80) NOT NULL,
  `name` varchar(125) NOT NULL,
  `style` varchar(30) NOT NULL,
  `weight` int(2) NOT NULL DEFAULT '400',
  `local1` varchar(80) NOT NULL,
  `local2` varchar(80) NOT NULL,
  `url` varchar(1024) NOT NULL,
  `format` varchar(16) CHARACTER SET ascii NOT NULL,
  `unicode_range` varchar(20) CHARACTER SET ascii NOT NULL,
  `purpose` tinyint(4) NOT NULL DEFAULT '0',
  `comment` varchar(160) NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `name_2` (`name`),
  KEY `format` (`format`),
  KEY `usage` (`purpose`),
  FULLTEXT KEY `search` (`family`,`local1`,`local2`,`url`),
  FULLTEXT KEY `name` (`name`),
  FULLTEXT KEY `family` (`family`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8;


--
-- Table structure for table `frozen_language`
--

DROP TABLE IF EXISTS `frozen_language`;
CREATE TABLE `frozen_language` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `hub_id` varchar(255) NOT NULL,
  `dbase_name` varchar(255) NOT NULL,
  `root_path` varchar(500) NOT NULL,
  `job_id` varchar(100) NOT NULL,
  `lang` varchar(100) NOT NULL,
  `ctime` int(11) NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `hub_id_lang` (`hub_id`,`lang`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8;


--
-- Table structure for table `guest`
--

DROP TABLE IF EXISTS `guest`;
CREATE TABLE `guest` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `id` varchar(16) NOT NULL,
  `email` varchar(512) NOT NULL,
  `firstname` varchar(128) DEFAULT '',
  `lastname` varchar(128) DEFAULT '',
  `expiry_time` int(11) NOT NULL DEFAULT '0',
  `ctime` int(11) DEFAULT NULL,
  `utime` int(11) DEFAULT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `email` (`email`),
  KEY `firstname` (`firstname`),
  KEY `lastname` (`lastname`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8;


--
-- Table structure for table `header`
--

DROP TABLE IF EXISTS `header`;
CREATE TABLE `header` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `id` varbinary(16) NOT NULL,
  `language` varchar(50) NOT NULL,
  `icon` varchar(500) NOT NULL,
  `title` varchar(500) NOT NULL,
  `keywords` varchar(500) NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `id` (`id`,`language`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8;


--
-- Table structure for table `homework`
--

DROP TABLE IF EXISTS `homework`;
CREATE TABLE `homework` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `home_id` varchar(16) NOT NULL,
  `work_id` varchar(16) NOT NULL,
  `ctime` int(11) DEFAULT NULL,
  `utime` int(11) DEFAULT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `pkey` (`home_id`,`work_id`),
  UNIQUE KEY `home_id` (`home_id`),
  KEY `work_id` (`work_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


--
-- Table structure for table `hub`
--

DROP TABLE IF EXISTS `hub`;
CREATE TABLE `hub` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `id` varchar(16) DEFAULT NULL,
  `owner_id` varchar(16) DEFAULT NULL,
  `origin_id` varchar(16) DEFAULT NULL,
  `dmail` varchar(255) NOT NULL DEFAULT '',
  `name` varchar(80) NOT NULL,
  `photo` varchar(40) CHARACTER SET ascii DEFAULT NULL,
  `description` varchar(2000) DEFAULT NULL,
  `keywords` varchar(2000) DEFAULT NULL,
  `permission` tinyint(4) unsigned NOT NULL DEFAULT '0',
  `profile` mediumtext,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `id` (`id`),
  KEY `dmail` (`dmail`),
  KEY `default_perm` (`permission`),
  KEY `owner_id` (`owner_id`),
  KEY `origin_id` (`origin_id`),
  FULLTEXT KEY `keywords` (`name`,`keywords`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8;

--
-- Table structure for table `icons`
--

DROP TABLE IF EXISTS `icons`;
CREATE TABLE `icons` (
  `sys_id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(128) DEFAULT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8;


--
-- Table structure for table `intl`
--

DROP TABLE IF EXISTS `intl`;
CREATE TABLE `intl` (
  `key_code` varchar(40) NOT NULL,
  `category` enum('ui','page','params','error','info','msg','email','text','question','nop','tpl','icon','natural') DEFAULT NULL,
  `fr` text NOT NULL,
  `en` text NOT NULL,
  `ru` text NOT NULL,
  `zh` text NOT NULL,
  PRIMARY KEY (`key_code`),
  KEY `category` (`category`),
  FULLTEXT KEY `fr` (`fr`),
  FULLTEXT KEY `en` (`en`),
  FULLTEXT KEY `ru` (`ru`),
  FULLTEXT KEY `zh` (`zh`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


--
-- Table structure for table `intl_bak`
--

DROP TABLE IF EXISTS `intl_bak`;
CREATE TABLE `intl_bak` (
  `key_code` varchar(40) NOT NULL,
  `category` enum('ui','page','params','error','info','msg','email','text','question','nop','tpl') NOT NULL DEFAULT 'page',
  `fr` text NOT NULL,
  `en` text NOT NULL,
  `ru` text NOT NULL,
  PRIMARY KEY (`key_code`),
  KEY `category` (`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


--
-- Table structure for table `job_credential`
--

DROP TABLE IF EXISTS `job_credential`;
CREATE TABLE `job_credential` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `app_key` varchar(100) NOT NULL,
  `customer_key` varchar(100) NOT NULL,
  `job_id` varchar(100) NOT NULL,
  `user_id` varchar(100) NOT NULL,
  `ctime` int(11) NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `job_id` (`job_id`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8;


--
-- Table structure for table `language`
--

DROP TABLE IF EXISTS `language`;
CREATE TABLE `language` (
  `code` varchar(8) NOT NULL,
  `lcid` varchar(16) NOT NULL,
  `locale_en` varchar(128) NOT NULL,
  `locale` varchar(128) NOT NULL,
  `flag_image` varchar(200) DEFAULT NULL,
  `state` enum('active','deleted') NOT NULL DEFAULT 'deleted',
  `comment` varchar(128) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


--
-- Table structure for table `locale`
--

DROP TABLE IF EXISTS `locale`;
CREATE TABLE `locale` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `lang` varchar(16) DEFAULT '',
  `lang_scope` enum('global','country') DEFAULT 'global',
  `lang_desc` varchar(255) DEFAULT '',
  `lc_ctype` varchar(16) DEFAULT '',
  `lc_numeric` varchar(16) DEFAULT '',
  `lc_time` varchar(16) DEFAULT '',
  `lc_date` varchar(64) DEFAULT '',
  `lc_collate` varchar(16) DEFAULT '',
  `lc_monetary` varchar(16) DEFAULT '',
  `lc_messages` varchar(16) DEFAULT '',
  `lc_paper` varchar(16) DEFAULT '',
  `lc_name` varchar(16) DEFAULT '',
  `lc_address` varchar(16) DEFAULT '',
  `lc_telephone` varchar(16) DEFAULT '',
  `lc_measurement` varchar(16) DEFAULT '',
  `lc_identification` varchar(16) DEFAULT '',
  `lc_all` varchar(16) DEFAULT '',
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `lang` (`lang`),
  KEY `lang_type` (`lang_scope`),
  FULLTEXT KEY `lc_monetary` (`lc_monetary`),
  FULLTEXT KEY `lc_paper` (`lc_paper`),
  FULLTEXT KEY `lc_measurement` (`lc_measurement`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8;


--
-- Table structure for table `locale2`
--

DROP TABLE IF EXISTS `locale2`;
CREATE TABLE `locale2` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `lang` varchar(16) DEFAULT '',
  `lang_scope` enum('global','country') DEFAULT 'global',
  `lang_desc` varchar(255) DEFAULT '',
  `lc_ctype` varchar(16) DEFAULT '',
  `lc_numeric` varchar(16) DEFAULT '',
  `lc_time` varchar(16) DEFAULT '',
  `lc_date` varchar(64) DEFAULT '',
  `lc_collate` varchar(16) DEFAULT '',
  `lc_monetary` varchar(16) DEFAULT '',
  `lc_messages` varchar(16) DEFAULT '',
  `lc_paper` varchar(16) DEFAULT '',
  `lc_name` varchar(16) DEFAULT '',
  `lc_address` varchar(16) DEFAULT '',
  `lc_telephone` varchar(16) DEFAULT '',
  `lc_measurement` varchar(16) DEFAULT '',
  `lc_identification` varchar(16) DEFAULT '',
  `lc_all` varchar(16) DEFAULT '',
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `lang` (`lang`),
  KEY `lang_type` (`lang_scope`),
  FULLTEXT KEY `lc_monetary` (`lc_monetary`),
  FULLTEXT KEY `lc_paper` (`lc_paper`),
  FULLTEXT KEY `lc_measurement` (`lc_measurement`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8;


--
-- Table structure for table `locale_tmp`
--

DROP TABLE IF EXISTS `locale_tmp`;
CREATE TABLE `locale_tmp` (
  `lang` varchar(16) COLLATE utf8_unicode_ci NOT NULL,
  `lang_scope` enum('global','country') COLLATE utf8_unicode_ci NOT NULL,
  `lang_desc` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `lc_ctype` varchar(16) COLLATE utf8_unicode_ci NOT NULL,
  `lc_numeric` varchar(16) COLLATE utf8_unicode_ci NOT NULL,
  `lc_time` varchar(16) COLLATE utf8_unicode_ci NOT NULL,
  `lc_date` varchar(64) COLLATE utf8_unicode_ci NOT NULL,
  `lc_collate` varchar(16) COLLATE utf8_unicode_ci NOT NULL,
  `lc_monetary` varchar(16) COLLATE utf8_unicode_ci NOT NULL,
  `lc_messages` varchar(16) COLLATE utf8_unicode_ci NOT NULL,
  `lc_paper` varchar(16) COLLATE utf8_unicode_ci NOT NULL,
  `lc_name` varchar(16) COLLATE utf8_unicode_ci NOT NULL,
  `lc_address` varchar(16) COLLATE utf8_unicode_ci NOT NULL,
  `lc_telephone` varchar(16) COLLATE utf8_unicode_ci NOT NULL,
  `lc_measurement` varchar(16) COLLATE utf8_unicode_ci NOT NULL,
  `lc_identification` varchar(16) COLLATE utf8_unicode_ci NOT NULL,
  `lc_all` varchar(16) COLLATE utf8_unicode_ci NOT NULL,
  PRIMARY KEY (`lang`),
  KEY `lang_type` (`lang_scope`),
  FULLTEXT KEY `lc_monetary` (`lc_monetary`),
  FULLTEXT KEY `lc_paper` (`lc_paper`),
  FULLTEXT KEY `lc_measurement` (`lc_measurement`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;


--
-- Table structure for table `log`
--

DROP TABLE IF EXISTS `log`;
CREATE TABLE `log` (
  `sn` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `id` varchar(64) COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `key_id` varchar(64) COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `user_id` varbinary(16) NOT NULL DEFAULT '0',
  `username` varchar(40) COLLATE utf8_unicode_ci NOT NULL,
  `update_time` int(11) unsigned NOT NULL DEFAULT '0',
  `start_time` int(11) unsigned NOT NULL DEFAULT '0',
  `ttl` int(11) unsigned NOT NULL DEFAULT '0',
  `last_ip` varchar(40) COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `last_ip_fwd_for` varchar(40) COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `req_uri` varchar(255) COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `referer` varchar(255) COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `ua` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `action` varchar(40) COLLATE utf8_unicode_ci NOT NULL,
  PRIMARY KEY (`sn`),
  KEY `user_id` (`user_id`),
  KEY `last_ip` (`last_ip`),
  KEY `ua` (`ua`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;


--
-- Table structure for table `membership`
--

DROP TABLE IF EXISTS `membership`;
CREATE TABLE `membership` (
  `id` varbinary(40) NOT NULL,
  `user_id` varbinary(16) DEFAULT NULL,
  `drumate_id` varbinary(16) NOT NULL,
  `privilege` tinyint(4) unsigned NOT NULL,
  `hub_id` varbinary(16) NOT NULL,
  `area_id` varbinary(16) DEFAULT NULL,
  `area` enum('private','restricted','public') DEFAULT NULL,
  `username` varchar(40) DEFAULT NULL,
  `add_time` int(11) unsigned NOT NULL,
  `update_time` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  KEY `area` (`area`),
  KEY `username` (`username`),
  KEY `permission` (`privilege`),
  KEY `area_id` (`area_id`) USING BTREE,
  KEY `id` (`id`),
  KEY `hub_id` (`hub_id`),
  KEY `drumate_id` (`drumate_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `membership_old`
--

DROP TABLE IF EXISTS `membership_old`;
CREATE TABLE `membership_old` (
  `id` varchar(40) CHARACTER SET ascii NOT NULL DEFAULT '',
  `user_id` varbinary(16) DEFAULT NULL,
  `drumate_id` varbinary(16) NOT NULL,
  `privilege` tinyint(4) unsigned NOT NULL,
  `hub_id` varbinary(16) NOT NULL,
  `area_id` varbinary(16) DEFAULT NULL,
  `area` enum('private','restricted','public') COLLATE utf8_unicode_ci DEFAULT NULL,
  `username` varchar(40) COLLATE utf8_unicode_ci DEFAULT NULL,
  `add_time` int(11) unsigned NOT NULL,
  `update_time` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  KEY `area` (`area`),
  KEY `username` (`username`),
  KEY `permission` (`privilege`),
  KEY `area_id` (`area_id`) USING BTREE,
  KEY `id` (`id`),
  KEY `hub_id` (`hub_id`),
  KEY `drumate_id` (`drumate_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;


--
-- Table structure for table `non_drumate`
--

DROP TABLE IF EXISTS `non_drumate`;
CREATE TABLE `non_drumate` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `id` varbinary(16) NOT NULL,
  `email` varchar(500) NOT NULL,
  `firstname` varchar(200) DEFAULT NULL,
  `lastname` varchar(200) DEFAULT NULL,
  `mobile` varchar(40) DEFAULT NULL,
  `extra` mediumtext,
  `privilege` varchar(50) DEFAULT NULL,
  `token` varchar(255) NOT NULL,
  `action` enum('add_contributor','add_contact','share_media') NOT NULL,
  `entity_id` varchar(100) NOT NULL,
  `item_id` varchar(100) NOT NULL,
  `expiry_time` int(11) NOT NULL DEFAULT '0',
  `ctime` int(11) NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `email` (`email`,`action`,`entity_id`,`item_id`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8;


--
-- Table structure for table `notice`
--

DROP TABLE IF EXISTS `notice`;
CREATE TABLE `notice` (
  `id` int(6) unsigned NOT NULL AUTO_INCREMENT,
  `dest_email` varchar(255) COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `category` enum('invitation','request','rendezvous','event','security','other') COLLATE utf8_unicode_ci NOT NULL DEFAULT 'invitation',
  `sender_id` varbinary(16) NOT NULL,
  `dest_id` varbinary(16) NOT NULL,
  `link_id` varbinary(16) NOT NULL,
  `link_type` enum('community','event','poll') COLLATE utf8_unicode_ci NOT NULL DEFAULT 'community',
  `status` enum('sent','received','open','declined') COLLATE utf8_unicode_ci NOT NULL DEFAULT 'sent',
  `ctime` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `status` (`status`),
  KEY `subject_id` (`link_id`),
  KEY `subject_type` (`link_type`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;


--
-- Table structure for table `notification`
--

DROP TABLE IF EXISTS `notification`;
CREATE TABLE `notification` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `share_id` varchar(16) NOT NULL,
  `owner_id` varchar(16) NOT NULL,
  `resource_id` varchar(16) NOT NULL,
  `entity_id` varchar(512) NOT NULL,
  `message` mediumtext,
  `expiry_time` int(11) NOT NULL DEFAULT '0',
  `permission` tinyint(4) unsigned NOT NULL,
  `status` enum('receive','accept','refuse','remove','change') DEFAULT 'receive',
  `ctime` int(11) DEFAULT NULL,
  `utime` int(11) DEFAULT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `pkey` (`resource_id`,`entity_id`),
  UNIQUE KEY `share_id` (`share_id`),
  KEY `entity_id` (`entity_id`),
  KEY `owner_id` (`owner_id`),
  KEY `resource_id` (`resource_id`),
  KEY `permission` (`permission`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8;


--
-- Table structure for table `profile`
--

DROP TABLE IF EXISTS `profile`;
CREATE TABLE `profile` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `id` varchar(80) CHARACTER SET ascii NOT NULL,
  `drumate_id` varbinary(16) NOT NULL,
  `photo` varbinary(16) NOT NULL,
  `area` varchar(10) DEFAULT 'public',
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `id` (`id`),
  KEY `public` (`photo`),
  KEY `drumate_id` (`drumate_id`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8;


--
-- Table structure for table `quota`
--

DROP TABLE IF EXISTS `quota`;
CREATE TABLE `quota` (
  `id` varbinary(16) NOT NULL,
  `size` decimal(12,1) NOT NULL DEFAULT '0.0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;


--
-- Table structure for table `remit`
--

DROP TABLE IF EXISTS `remit`;
CREATE TABLE `remit` (
  `method` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `level` bit(3) NOT NULL,
  UNIQUE KEY `method` (`method`),
  KEY `module` (`level`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;


--
-- Table structure for table `request`
--

DROP TABLE IF EXISTS `request`;
CREATE TABLE `request` (
  `sn` int(6) unsigned NOT NULL AUTO_INCREMENT,
  `firstname` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `lastname` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `email` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `id` varbinary(80) NOT NULL,
  `message` text COLLATE utf8_unicode_ci NOT NULL,
  `reason` enum('request','presub','subscribe') COLLATE utf8_unicode_ci NOT NULL DEFAULT 'request',
  `ident` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `tstamp` int(11) NOT NULL,
  PRIMARY KEY (`sn`),
  KEY `name` (`firstname`(128),`lastname`(128)),
  KEY `email` (`email`),
  KEY `ident` (`ident`),
  FULLTEXT KEY `message` (`message`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;


--
-- Table structure for table `sessions`
--

DROP TABLE IF EXISTS `sessions`;
CREATE TABLE `sessions` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `id` varbinary(64) NOT NULL,
  `user_id` varbinary(16) NOT NULL,
  `username` varchar(64) NOT NULL DEFAULT '',
  `domain` varchar(128) NOT NULL DEFAULT 'drumee.net',
  `expire_time` int(11) NOT NULL DEFAULT '0',
  `update_time` int(11) NOT NULL DEFAULT '0',
  `start_time` int(11) NOT NULL DEFAULT '0',
  `ttl` int(11) NOT NULL DEFAULT '86400',
  `last_ip` varchar(64) NOT NULL DEFAULT '',
  `last_ip_fwd_for` varchar(40) NOT NULL DEFAULT '',
  `req_uri` varchar(255) NOT NULL DEFAULT '',
  `referer` varchar(64) NOT NULL DEFAULT '',
  `ua` varchar(64) NOT NULL DEFAULT '',
  `action` varchar(40) NOT NULL,
  `host_id` varbinary(16) NOT NULL DEFAULT '\0',
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `id` (`id`),
  KEY `user_id` (`user_id`),
  KEY `last_ip` (`last_ip`),
  KEY `ua` (`ua`),
  KEY `username` (`username`),
  KEY `referer` (`referer`),
  KEY `domain` (`domain`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8;


--
-- Table structure for table `settings`
--

DROP TABLE IF EXISTS `settings`;
CREATE TABLE `settings` (
  `build` int(4) unsigned NOT NULL,
  `dbhost` varchar(128) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'localhost',
  `fshost` varchar(128) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'localhost',
  `mfs_root` varchar(255) COLLATE utf8_unicode_ci NOT NULL DEFAULT '/data/mfs/',
  `user_root` varchar(255) COLLATE utf8_unicode_ci NOT NULL DEFAULT '/data/mfs/user/',
  `site_root` varchar(255) COLLATE utf8_unicode_ci NOT NULL DEFAULT '/data/mfs/site/',
  `icon` varchar(1024) COLLATE utf8_unicode_ci DEFAULT NULL,
  `overview` varchar(3000) COLLATE utf8_unicode_ci DEFAULT NULL,
  `settings` varchar(3000) COLLATE utf8_unicode_ci DEFAULT NULL,
  `domainname` varchar(100) COLLATE utf8_unicode_ci DEFAULT NULL,
  `alt_domain` varchar(200) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`build`),
  UNIQUE KEY `domainname` (`domainname`),
  KEY `site_root` (`site_root`),
  KEY `mfs_root` (`mfs_root`),
  KEY `dbhost` (`dbhost`),
  KEY `fshost` (`fshost`),
  KEY `mfs_root_2` (`mfs_root`),
  KEY `user_root` (`user_root`),
  KEY `site_root_2` (`site_root`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;


--
-- Table structure for table `share_box`
--

DROP TABLE IF EXISTS `share_box`;
CREATE TABLE `share_box` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `id` varchar(16) NOT NULL,
  `owner_id` varchar(16) NOT NULL,
  `root_id` varchar(16) NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `owner_id` (`owner_id`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8;


--
-- Table structure for table `site`
--

DROP TABLE IF EXISTS `site`;
CREATE TABLE `site` (
  `id` varchar(16) NOT NULL,
  `owner_id` varbinary(16) NOT NULL,
  `dmail` varchar(255) NOT NULL DEFAULT '',
  `name` varchar(80) NOT NULL,
  `ctime` int(11) NOT NULL,
  `photo` varchar(255) NOT NULL,
  `mtime` int(11) NOT NULL,
  `autojoin` varchar(8) NOT NULL DEFAULT 'off',
  `description` text NOT NULL,
  `keywords` text NOT NULL,
  `permission` tinyint(4) unsigned NOT NULL,
  PRIMARY KEY (`id`),
  KEY `dmail` (`dmail`),
  KEY `default_perm` (`permission`),
  KEY `owner_id` (`owner_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


--
-- Table structure for table `states`
--

DROP TABLE IF EXISTS `states`;
CREATE TABLE `states` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(30) NOT NULL,
  `country_id` int(11) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1;


--
-- Table structure for table `sys_conf`
--

DROP TABLE IF EXISTS `sys_conf`;
CREATE TABLE `sys_conf` (
  `conf_key` varchar(40) NOT NULL,
  `conf_value` varchar(225) DEFAULT NULL,
  PRIMARY KEY (`conf_key`),
  FULLTEXT KEY `conf_value` (`conf_value`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


--
-- Table structure for table `team`
--

DROP TABLE IF EXISTS `team`;
CREATE TABLE `team` (
  `id` varchar(16) CHARACTER SET ascii NOT NULL,
  `firstname` varchar(80) COLLATE utf8_unicode_ci NOT NULL,
  `lastname` varchar(80) COLLATE utf8_unicode_ci NOT NULL,
  `domain` enum('tech','design','management','qos','marketing','sell') COLLATE utf8_unicode_ci NOT NULL,
  `priority` tinyint(4) NOT NULL,
  `email` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `mobile` varchar(80) COLLATE utf8_unicode_ci NOT NULL,
  KEY `priority` (`priority`),
  KEY `name` (`firstname`,`lastname`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;


--
-- Table structure for table `test`
--

DROP TABLE IF EXISTS `test`;
CREATE TABLE `test` (
  `id` varbinary(16) NOT NULL,
  `profile` json DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


--
-- Table structure for table `translate`
--

DROP TABLE IF EXISTS `translate`;
CREATE TABLE `translate` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(40) CHARACTER SET ascii NOT NULL,
  `key_code` varchar(40) CHARACTER SET ascii DEFAULT NULL,
  `lang` varchar(40) CHARACTER SET ascii NOT NULL,
  `content` text,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `code` (`code`,`lang`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8;


--
-- Table structure for table `user`
--

DROP TABLE IF EXISTS `user`;
CREATE TABLE `user` (
  `id` varbinary(16) NOT NULL,
  `title` varchar(200) NOT NULL,
  `data` json DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


--
-- Table structure for table `device_registation`
--

DROP TABLE IF EXISTS `device_registation`;
CREATE TABLE `device_registation` (
  `device_id` varchar(200) NOT NULL,
  `device_type` enum('ios','android','web') NOT NULL,
  `push_token` text NOT NULL,
  `metadata` json DEFAULT NULL,
  `uid` varchar(16) DEFAULT NULL,
  `status` varchar(20) NOT NULL DEFAULT 'active',
  `ctime` int(11) NOT NULL DEFAULT 0,
  `mtime` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`device_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

