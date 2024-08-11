
/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
DROP TABLE IF EXISTS `__register_stack`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `__register_stack` (
  `id` varchar(16) DEFAULT NULL,
  `origin_id` varchar(16) DEFAULT NULL,
  `owner` varchar(16) DEFAULT NULL,
  `file_path` varchar(1000) DEFAULT NULL,
  `user_filename` varchar(128) DEFAULT NULL,
  `parent_id` varchar(16) DEFAULT '',
  `parent_path` varchar(1024) DEFAULT NULL,
  `extension` varchar(100) DEFAULT '',
  `mimetype` varchar(100) DEFAULT NULL,
  `category` varchar(16) DEFAULT NULL,
  `isalink` tinyint(2) unsigned DEFAULT 0,
  `filesize` bigint(20) unsigned DEFAULT 0,
  `geometry` varchar(200) DEFAULT '0x0',
  `publish_time` int(11) unsigned DEFAULT 0,
  `upload_time` int(11) unsigned DEFAULT 0,
  `status` varchar(20) DEFAULT 'active',
  `rank` int(8) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `__vfs__`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `__vfs__` (
  `origin_id` varchar(16) DEFAULT NULL,
  `user_filename` varchar(128) DEFAULT NULL,
  `id` varchar(16) DEFAULT NULL,
  `category` varchar(16) NOT NULL,
  `extension` varchar(100) NOT NULL DEFAULT '',
  `mimetype` varchar(100) NOT NULL,
  `geometry` varchar(200) NOT NULL DEFAULT '0x0',
  `filesize` int(20) unsigned NOT NULL DEFAULT 0,
  `location` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `acl`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `acl` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `pkey` varbinary(32) NOT NULL,
  `resource_id` varbinary(16) NOT NULL,
  `resource_type` enum('media','comment','link','layout','all','*') NOT NULL DEFAULT '*',
  `entity_id` varbinary(16) NOT NULL,
  `permission` tinyint(4) unsigned NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `pkey` (`pkey`),
  UNIQUE KEY `pkey_2` (`pkey`),
  KEY `resource_id` (`resource_id`),
  KEY `resource_type` (`resource_type`),
  KEY `entity_id` (`entity_id`),
  KEY `permission` (`permission`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `article`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `article` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `id` varbinary(16) NOT NULL,
  `author_id` varbinary(16) NOT NULL,
  `summary` text NOT NULL,
  `content` mediumtext NOT NULL,
  `draft` mediumtext NOT NULL,
  `create_time` int(11) unsigned NOT NULL DEFAULT 0,
  `publish_time` int(11) unsigned NOT NULL DEFAULT 0,
  `edit_time` int(11) unsigned NOT NULL DEFAULT 0,
  `rating` double NOT NULL DEFAULT 0,
  `lang` varchar(10) NOT NULL DEFAULT '',
  `status` enum('online','offline','draft','trash','archive') NOT NULL DEFAULT 'draft',
  `version` int(10) unsigned NOT NULL DEFAULT 0,
  `counter` int(10) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `id` (`id`),
  KEY `author_id` (`author_id`),
  KEY `create_time` (`create_time`),
  KEY `publish_time` (`publish_time`),
  KEY `status` (`status`),
  FULLTEXT KEY `content` (`content`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `block`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `block` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `id` varbinary(16) NOT NULL,
  `serial` int(6) unsigned NOT NULL DEFAULT 0,
  `active` int(6) NOT NULL DEFAULT 0,
  `author_id` varbinary(16) NOT NULL,
  `hashtag` varchar(500) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `type` enum('page','block','menu','header','footer') NOT NULL DEFAULT 'block',
  `editor` enum('creator','designer') CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT 'creator',
  `status` enum('online','offline','locked','readonly') CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT 'online',
  `ctime` int(11) NOT NULL,
  `mtime` int(11) NOT NULL,
  `version` varchar(10) NOT NULL DEFAULT '1.0.0',
  `owner_id` varchar(16) DEFAULT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `hashtag` (`hashtag`) USING BTREE,
  KEY `ctime` (`ctime`),
  KEY `mtime` (`mtime`),
  KEY `version` (`version`),
  KEY `author_id` (`author_id`),
  KEY `editor` (`editor`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `block_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `block_history` (
  `serial` int(10) NOT NULL AUTO_INCREMENT,
  `author_id` varbinary(16) NOT NULL,
  `master_id` varbinary(16) NOT NULL,
  `lang` varchar(10) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT 'en',
  `device` enum('desktop','tablet','mobile') CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT 'desktop',
  `status` enum('draft','history') NOT NULL DEFAULT 'history',
  `isonline` int(4) DEFAULT 0,
  `meta` mediumtext NOT NULL,
  `ctime` int(11) unsigned NOT NULL,
  PRIMARY KEY (`serial`),
  KEY `lang` (`lang`),
  KEY `device` (`device`),
  FULLTEXT KEY `meta` (`meta`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `chat`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `chat` (
  `sys_id` int(11) NOT NULL AUTO_INCREMENT,
  `id` varbinary(16) NOT NULL,
  `author_id` varbinary(16) NOT NULL,
  `pseudo` varchar(80) NOT NULL,
  `message` varchar(1000) NOT NULL,
  `namespace` varchar(80) NOT NULL,
  `room` varchar(80) NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `id` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `comment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `comment` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `id` varchar(16) DEFAULT NULL,
  `ref_id` varchar(16) DEFAULT NULL,
  `owner_id` varchar(16) DEFAULT NULL,
  `author_id` varchar(16) DEFAULT NULL,
  `content` mediumtext NOT NULL,
  `create_time` int(11) unsigned NOT NULL DEFAULT 0,
  `publish_time` int(11) unsigned NOT NULL DEFAULT 0,
  `edit_time` int(11) unsigned NOT NULL DEFAULT 0,
  `editable` tinyint(4) NOT NULL DEFAULT 0,
  `rating` double NOT NULL DEFAULT 0,
  `lang` varchar(16) DEFAULT NULL,
  `ext_data` mediumtext NOT NULL,
  `status` enum('draft','validated','online') DEFAULT NULL,
  `version` int(10) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `id` (`id`),
  KEY `ref_id` (`ref_id`),
  KEY `owner_id` (`owner_id`),
  KEY `author_id` (`author_id`),
  KEY `create_time` (`create_time`),
  KEY `publish_time` (`publish_time`),
  FULLTEXT KEY `every_text` (`content`,`ext_data`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `contact`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `contact` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `id` varchar(100) DEFAULT NULL,
  `ctime` int(11) NOT NULL,
  `mtime` int(11) NOT NULL,
  `vcard` text DEFAULT NULL,
  `email` varchar(255) GENERATED ALWAYS AS (trim(ifnull(json_unquote(json_extract(`vcard`,'$.email')),''))) STORED,
  `uid` varchar(255) GENERATED ALWAYS AS (trim(ifnull(json_unquote(json_extract(`vcard`,'$.uid')),''))) VIRTUAL,
  `fullname` varchar(255) GENERATED ALWAYS AS (trim(ifnull(json_unquote(json_extract(`vcard`,'$.fn')),''))) VIRTUAL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `id` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `content_tag`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `content_tag` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `language` varchar(50) NOT NULL,
  `type` enum('block','folder','link','video','image','audio','document','stylesheet','other') NOT NULL,
  `status` enum('online','offline') DEFAULT NULL,
  `name` varchar(500) NOT NULL,
  `description` varchar(1024) NOT NULL,
  `ctime` int(11) NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `id` (`id`,`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `font`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `font` (
  `sys_id` int(11) NOT NULL AUTO_INCREMENT,
  `family` varchar(256) DEFAULT NULL,
  `name` varchar(128) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `variant` varchar(128) DEFAULT NULL,
  `url` varchar(1024) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `status` enum('active','frozen') CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT 'active',
  `ctime` int(11) NOT NULL,
  `mtime` int(11) NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `family` (`family`),
  KEY `url` (`url`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `font_face`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `font_face` (
  `sys_id` int(6) NOT NULL AUTO_INCREMENT,
  `family` varchar(80) NOT NULL,
  `name` varchar(125) NOT NULL,
  `style` varchar(30) NOT NULL,
  `weight` int(2) NOT NULL DEFAULT 400,
  `local1` varchar(80) NOT NULL,
  `local2` varchar(80) NOT NULL,
  `url` varchar(1024) NOT NULL,
  `format` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `unicode_range` varchar(20) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `purpose` tinyint(4) NOT NULL DEFAULT 0,
  `comment` varchar(160) NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `name_2` (`name`),
  KEY `format` (`format`),
  KEY `usage` (`purpose`),
  FULLTEXT KEY `search` (`family`,`local1`,`local2`,`url`),
  FULLTEXT KEY `name` (`name`),
  FULLTEXT KEY `family` (`family`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `font_link`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `font_link` (
  `sys_id` int(11) NOT NULL AUTO_INCREMENT,
  `family` varchar(256) DEFAULT NULL,
  `name` varchar(128) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `variant` varchar(128) DEFAULT NULL,
  `url` varchar(1024) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `status` enum('active','frozen') CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT 'active',
  `ctime` int(11) NOT NULL,
  `mtime` int(11) NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `family` (`family`),
  KEY `url` (`url`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `huber`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `huber` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `id` varbinary(16) NOT NULL,
  `privilege` tinyint(2) NOT NULL DEFAULT 0,
  `expiry_time` int(11) NOT NULL DEFAULT 0,
  `ctime` int(11) NOT NULL,
  `utime` int(11) DEFAULT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `id` (`id`),
  KEY `ctime` (`ctime`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `hubs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `hubs` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `id` varbinary(16) NOT NULL,
  `rank` tinyint(4) NOT NULL DEFAULT 1,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `id` (`id`),
  KEY `rank` (`rank`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `language`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `language` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `base` varchar(10) NOT NULL,
  `name` varchar(100) NOT NULL,
  `locale` varchar(100) NOT NULL,
  `state` enum('deleted','active','frozen','replaced') NOT NULL,
  `ctime` int(11) NOT NULL,
  `mtime` int(11) NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `locale` (`locale`),
  KEY `base` (`base`),
  KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `layout`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `layout` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `id` varbinary(16) NOT NULL,
  `author_id` varbinary(16) NOT NULL,
  `hashtag` varchar(500) NOT NULL,
  `type` enum('page','block','menu','header','footer','slider','gallery') NOT NULL DEFAULT 'block',
  `context` enum('page','slider','slideshow','menu','creator','designer') NOT NULL DEFAULT 'creator',
  `editor` enum('designer','creator') CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT 'creator',
  `tag` varchar(400) NOT NULL,
  `hash` varchar(500) DEFAULT NULL,
  `device` varchar(2000) DEFAULT NULL,
  `lang` varchar(2000) DEFAULT NULL,
  `author` varchar(80) DEFAULT NULL,
  `comment` varchar(1024) DEFAULT NULL,
  `content` mediumtext DEFAULT NULL,
  `footnote` mediumtext DEFAULT NULL,
  `backup` mediumtext DEFAULT NULL,
  `newbie` mediumtext DEFAULT NULL,
  `expert` mediumtext DEFAULT NULL,
  `status` enum('active','deleted','locked','backup','readonly','draft','exported') DEFAULT NULL,
  `ctime` int(11) NOT NULL,
  `mtime` int(11) NOT NULL,
  `version` varchar(10) NOT NULL DEFAULT '1.0.0',
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `id_2` (`id`),
  UNIQUE KEY `id_3` (`id`),
  UNIQUE KEY `id_4` (`id`),
  UNIQUE KEY `hashtag` (`hashtag`),
  UNIQUE KEY `hash` (`hash`) USING BTREE,
  KEY `author` (`author`),
  KEY `ctime` (`ctime`),
  KEY `mtime` (`mtime`),
  KEY `version` (`version`),
  KEY `ltype` (`context`),
  KEY `tag` (`tag`),
  KEY `author_id` (`author_id`),
  KEY `editor` (`editor`),
  FULLTEXT KEY `content` (`content`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `mark`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `mark` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `author_id` varbinary(16) NOT NULL,
  `drum_id` varbinary(16) NOT NULL,
  `thread_id` varbinary(16) NOT NULL,
  `thread_rank` int(8) NOT NULL DEFAULT 0,
  `head_id` varbinary(16) NOT NULL,
  `priority` tinyint(4) NOT NULL,
  `msg_status` enum('new','seen','archived','deleted','draft','sent','todo','important') NOT NULL DEFAULT 'new',
  `cid` varbinary(16) NOT NULL,
  `tstamp` int(11) NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `drum_id` (`drum_id`),
  KEY `tstamp` (`tstamp`),
  KEY `author_id` (`author_id`),
  KEY `cid` (`cid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `media`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `media` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `id` varchar(16) DEFAULT NULL,
  `origin_id` varchar(16) DEFAULT NULL,
  `owner_id` varchar(16) NOT NULL,
  `host_id` varchar(16) NOT NULL,
  `file_path` varchar(512) DEFAULT NULL,
  `user_filename` varchar(128) DEFAULT NULL,
  `parent_id` varchar(16) NOT NULL DEFAULT '',
  `parent_path` varchar(1024) NOT NULL,
  `extension` varchar(100) NOT NULL DEFAULT '',
  `mimetype` varchar(100) NOT NULL,
  `category` enum('hub','folder','link','video','image','audio','document','stylesheet','script','vector','other') NOT NULL DEFAULT 'other',
  `isalink` tinyint(2) unsigned NOT NULL DEFAULT 0,
  `filesize` int(20) unsigned NOT NULL DEFAULT 0,
  `geometry` varchar(200) NOT NULL DEFAULT '0x0',
  `publish_time` int(11) unsigned NOT NULL DEFAULT 0,
  `upload_time` int(11) unsigned NOT NULL DEFAULT 0,
  `last_download` int(11) unsigned NOT NULL DEFAULT 0,
  `download_count` mediumint(8) unsigned NOT NULL DEFAULT 0,
  `metadata` varchar(1024) DEFAULT NULL,
  `caption` varchar(1024) DEFAULT NULL,
  `status` varchar(20) NOT NULL DEFAULT 'active',
  `approval` enum('submitted','verified','validated') NOT NULL,
  `rank` tinyint(4) NOT NULL DEFAULT 0,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `filepath` (`parent_id`,`user_filename`),
  KEY `approval` (`approval`),
  KEY `geometry` (`geometry`),
  KEY `parent_id` (`parent_id`),
  KEY `origin_id` (`origin_id`),
  KEY `file_path` (`file_path`),
  KEY `user_filename` (`user_filename`),
  KEY `category` (`category`),
  FULLTEXT KEY `content` (`caption`,`user_filename`,`file_path`,`metadata`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `member`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `member` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `id` varchar(16) NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `id` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `message`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `message` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `pkey` varchar(32) DEFAULT NULL,
  `resource_id` varchar(16) NOT NULL,
  `resource_type` enum('media','comment','link','page','all','*') NOT NULL DEFAULT '*',
  `entity_id` varchar(16) NOT NULL,
  `content` text DEFAULT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `message_pkey` (`pkey`),
  KEY `resource_id` (`resource_id`),
  KEY `resource_type` (`resource_type`),
  KEY `entity_id` (`entity_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `notification`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `notification` (
  `sys_id` int(11) NOT NULL AUTO_INCREMENT,
  `id` varbinary(16) NOT NULL,
  `type` enum('chat','message','invitation','event') CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT 'message',
  `text` varchar(256) DEFAULT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `id` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `permission`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `permission` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `resource_id` varchar(16) NOT NULL,
  `entity_id` varchar(512) NOT NULL,
  `expiry_time` int(11) NOT NULL DEFAULT 0,
  `ctime` int(11) DEFAULT NULL,
  `utime` int(11) DEFAULT NULL,
  `permission` tinyint(4) unsigned NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `pkey` (`resource_id`,`entity_id`),
  KEY `entity_id` (`entity_id`),
  KEY `permission` (`permission`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `seo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `seo` (
  `sys_id` int(11) NOT NULL AUTO_INCREMENT,
  `key` varchar(25) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `hashtag` varchar(256) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `lang` varchar(6) NOT NULL,
  `content` mediumtext NOT NULL,
  `link_data` mediumtext NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `key` (`key`),
  KEY `lang` (`lang`),
  FULLTEXT KEY `content` (`content`),
  FULLTEXT KEY `hashtag` (`hashtag`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `statistics`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `statistics` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `disk_usage` int(8) unsigned NOT NULL DEFAULT 0,
  `page_count` int(8) NOT NULL DEFAULT 0,
  `visit_count` int(8) NOT NULL DEFAULT 0,
  `ctime` int(11) NOT NULL,
  PRIMARY KEY (`sys_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `style`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `style` (
  `id` int(8) NOT NULL AUTO_INCREMENT,
  `name` varchar(80) NOT NULL DEFAULT 'My Style',
  `class_name` varchar(100) DEFAULT NULL,
  `selector` varchar(255) NOT NULL,
  `declaration` varchar(12000) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `comment` varchar(255) NOT NULL DEFAULT 'xxx',
  `status` enum('active','frozen') CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT 'active',
  PRIMARY KEY (`id`),
  KEY `className` (`selector`),
  KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tmp_id`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tmp_id` (
  `nid` varchar(16) NOT NULL,
  `mfs_root` varchar(1024) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tmp_media`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tmp_media` (
  `id` varchar(16) DEFAULT NULL,
  `origin_id` varchar(16) DEFAULT NULL,
  `file_path` varchar(512) DEFAULT NULL,
  `user_filename` varchar(128) DEFAULT NULL,
  `parent_id` varchar(16) DEFAULT '',
  `parent_path` varchar(1024) DEFAULT NULL,
  `extension` varchar(100) DEFAULT '',
  `mimetype` varchar(100) DEFAULT NULL,
  `category` varchar(16) DEFAULT NULL,
  `isalink` tinyint(2) unsigned DEFAULT 0,
  `filesize` int(20) unsigned DEFAULT 0,
  `geometry` varchar(200) DEFAULT '0x0',
  `publish_time` int(11) unsigned DEFAULT 0,
  `upload_time` int(11) unsigned DEFAULT 0,
  `status` varchar(20) DEFAULT 'active',
  `rank` int(8) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `used_colors`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `used_colors` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `rgba` varchar(50) NOT NULL,
  `hexacode` varchar(20) NOT NULL,
  `ctime` int(11) NOT NULL,
  PRIMARY KEY (`sys_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `used_fonts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `used_fonts` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(200) NOT NULL,
  `ctime` int(11) NOT NULL,
  PRIMARY KEY (`sys_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `fixcontact` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `fixcontact`()
BEGIN
DECLARE _missing_table int default 1;
DECLARE _missing_field int default 0;
 SELECT 0  FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name = 'contact'  AND  TABLE_SCHEMA = database() LIMIT 1 INTO _missing_table ; 
 SELECT 1  FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name = 'contact' AND TABLE_SCHEMA = database()   
 AND COLUMN_NAME NOT IN  ("sys_id","id","surname", "firstname","lastname", "comment", "message", "entity", "uid", "category", "status", "ctime", "mtime", "metadata", "source") LIMIT 1
 INTO _missing_field ;

 SELECT *  FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name = 'contact' AND TABLE_SCHEMA = database()   
 AND COLUMN_NAME NOT IN  ("sys_id","id","surname", "firstname","lastname", "comment", "message", "entity", "uid", "category", "status", "ctime", "mtime", "metadata", "source") ;


SELECT _missing_table,_missing_field;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

