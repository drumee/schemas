
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
DROP TABLE IF EXISTS `action_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `action_log` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `uid` varchar(16) NOT NULL,
  `action` enum('added','deleted','changed','left','removed','backup','connection') DEFAULT NULL,
  `category` enum('media','permission','member','admin','title') NOT NULL,
  `notify_to` enum('all','member','admin') NOT NULL,
  `entity_id` varchar(16) DEFAULT NULL,
  `log` varchar(1000) NOT NULL,
  `ctime` int(11) NOT NULL,
  PRIMARY KEY (`sys_id`)
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
DROP TABLE IF EXISTS `attachment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `attachment` (
  `message_id` varchar(16) NOT NULL,
  `hub_id` varchar(16) NOT NULL,
  `rid` varchar(16) NOT NULL,
  `uid` varchar(16) NOT NULL,
  UNIQUE KEY `id` (`message_id`,`rid`,`hub_id`,`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `channel`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `channel` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `author_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `message` mediumtext DEFAULT NULL,
  `message_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `thread_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `attachment` longtext DEFAULT NULL CHECK (json_valid(`attachment`)),
  `is_forward` tinyint(1) DEFAULT 0,
  `status` enum('draft','active','trashed') NOT NULL DEFAULT 'active',
  `ctime` int(11) NOT NULL,
  `metadata` mediumtext DEFAULT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `message_id` (`message_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
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
  `rank` int(8) NOT NULL,
  `group_rank` int(8) NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `id` (`id`,`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `custom`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `custom` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `id` varchar(16) NOT NULL,
  `name` varchar(100) NOT NULL,
  `author_id` varchar(16) NOT NULL,
  `ctime` int(11) DEFAULT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `delete_channel`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `delete_channel` (
  `uid` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `ref_sys_id` int(11) unsigned NOT NULL,
  `ctime` int(11) NOT NULL,
  UNIQUE KEY `id` (`uid`,`ref_sys_id`)
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
  `style` varchar(30) NOT NULL,
  `weight` int(2) NOT NULL DEFAULT 400,
  `local1` varchar(80) NOT NULL,
  `local2` varchar(80) NOT NULL,
  `url` varchar(1024) NOT NULL,
  `format` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `unicode_range` varchar(20) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `comment` varchar(160) NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `family` (`family`,`weight`),
  KEY `format` (`format`)
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
DROP TABLE IF EXISTS `map_ticket`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `map_ticket` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `message_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `ticket_id` int(11) unsigned NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `id` (`message_id`,`ticket_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `media`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `media` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `origin_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `owner_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `host_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `file_path` varchar(1000) DEFAULT NULL,
  `user_filename` varchar(128) DEFAULT NULL,
  `parent_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `parent_path` varchar(1024) NOT NULL,
  `extension` varchar(100) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `mimetype` varchar(100) NOT NULL,
  `category` varchar(16) NOT NULL DEFAULT 'other',
  `isalink` tinyint(2) unsigned NOT NULL DEFAULT 0,
  `filesize` bigint(20) unsigned DEFAULT 0,
  `geometry` varchar(200) NOT NULL DEFAULT '0x0',
  `publish_time` int(11) unsigned NOT NULL DEFAULT 0,
  `upload_time` int(11) unsigned NOT NULL DEFAULT 0,
  `last_download` int(11) unsigned NOT NULL DEFAULT 0,
  `download_count` mediumint(8) unsigned NOT NULL DEFAULT 0,
  `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT '{}' CHECK (json_valid(`metadata`)),
  `caption` varchar(1024) DEFAULT NULL,
  `status` varchar(20) NOT NULL DEFAULT 'active',
  `approval` enum('submitted','verified','validated','draft','online','offline') DEFAULT 'draft',
  `rank` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `filepath` (`file_path`),
  UNIQUE KEY `path` (`parent_id`,`user_filename`,`extension`),
  KEY `approval` (`approval`),
  KEY `geometry` (`geometry`),
  KEY `parent_id` (`parent_id`),
  KEY `origin_id` (`origin_id`),
  KEY `file_path` (`file_path`),
  KEY `user_filename` (`user_filename`),
  KEY `category` (`category`),
  KEY `idx_status` (`status`),
  KEY `id_user_filename` (`id`,`user_filename`,`parent_id`),
  FULLTEXT KEY `content` (`file_path`)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `permission`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `permission` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `resource_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `entity_id` varchar(512) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `message` mediumtext DEFAULT NULL,
  `expiry_time` int(11) NOT NULL DEFAULT 0,
  `ctime` int(11) DEFAULT NULL,
  `utime` int(11) DEFAULT NULL,
  `permission` tinyint(4) unsigned NOT NULL,
  `assign_via` enum('system','link','share','no_traversal','root') DEFAULT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `pkey` (`resource_id`,`entity_id`),
  KEY `entity_id` (`entity_id`),
  KEY `permission` (`permission`)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `read_channel`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `read_channel` (
  `uid` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `ref_sys_id` int(11) unsigned NOT NULL,
  `ctime` int(11) NOT NULL,
  UNIQUE KEY `id` (`uid`),
  KEY `ref_sys_id` (`ref_sys_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `read_ticket_channel`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `read_ticket_channel` (
  `uid` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `ticket_id` int(11) unsigned NOT NULL,
  `ref_sys_id` int(11) unsigned NOT NULL,
  `ctime` int(11) NOT NULL,
  UNIQUE KEY `id` (`uid`,`ticket_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `seo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `seo` (
  `sys_id` int(11) NOT NULL AUTO_INCREMENT,
  `ctime` int(11) unsigned DEFAULT NULL,
  `occurrence` int(6) unsigned DEFAULT 1,
  `word` varchar(300) NOT NULL,
  `hub_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `nid` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `key` (`word`,`hub_id`,`nid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `seo_object`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `seo_object` (
  `sys_id` int(11) NOT NULL AUTO_INCREMENT,
  `hub_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `nid` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `node` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`node`)),
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `key` (`hub_id`,`nid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
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
DROP TABLE IF EXISTS `trash_media`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `trash_media` (
  `sys_id` int(11) unsigned NOT NULL,
  `id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `origin_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `owner_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `host_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `file_path` varchar(1000) DEFAULT NULL,
  `user_filename` varchar(128) DEFAULT NULL,
  `parent_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `parent_path` varchar(1024) NOT NULL,
  `extension` varchar(100) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `mimetype` varchar(100) NOT NULL,
  `category` varchar(16) NOT NULL DEFAULT 'other',
  `isalink` tinyint(2) unsigned NOT NULL DEFAULT 0,
  `filesize` bigint(20) unsigned DEFAULT 0,
  `geometry` varchar(200) NOT NULL DEFAULT '0x0',
  `publish_time` int(11) unsigned NOT NULL DEFAULT 0,
  `upload_time` int(11) unsigned NOT NULL DEFAULT 0,
  `last_download` int(11) unsigned NOT NULL DEFAULT 0,
  `download_count` mediumint(8) unsigned NOT NULL DEFAULT 0,
  `metadata` longtext DEFAULT NULL,
  `caption` varchar(1024) DEFAULT NULL,
  `status` varchar(20) NOT NULL DEFAULT 'active',
  `approval` enum('submitted','verified','validated','draft','online','offline') DEFAULT 'draft',
  `rank` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `id` (`id`),
  KEY `approval` (`approval`),
  KEY `geometry` (`geometry`),
  KEY `origin_id` (`origin_id`),
  KEY `file_path` (`file_path`(768)),
  KEY `user_filename` (`user_filename`),
  KEY `category` (`category`),
  KEY `parent_id` (`parent_id`),
  KEY `id_category` (`id`,`category`),
  KEY `idx_status` (`status`),
  FULLTEXT KEY `content` (`caption`,`user_filename`,`file_path`,`metadata`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP FUNCTION IF EXISTS `clean_path` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE FUNCTION `clean_path`(_path VARCHAR(1024)
) RETURNS varchar(1024) CHARSET utf8mb4
    DETERMINISTIC
BEGIN
  DECLARE _r VARCHAR(1024);
  SELECT REGEXP_REPLACE(_path, '/+', '/') INTO _r;
  SELECT REGEXP_REPLACE(_r, '\<.*\>', '') INTO _r;
  RETURN _r;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP FUNCTION IF EXISTS `domain_name` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE FUNCTION `domain_name`() RETURNS varchar(512) CHARSET utf8mb4
    DETERMINISTIC
BEGIN
  RETURN "drumee.com";
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP FUNCTION IF EXISTS `filepath` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE FUNCTION `filepath`(_id VARCHAR(1024)
) RETURNS varchar(1500) CHARSET utf8mb4 COLLATE utf8mb4_general_ci
    DETERMINISTIC
BEGIN
  DECLARE _r TEXT;

  SELECT CONCAT(
    parent_path(id), 
    REGEXP_REPLACE(user_filename, '^ +| +$|/+', ''),
    IF(extension REGEXP "^ *$" OR category IN('root', 'folder', 'hub') , 
    '', CONCAT('.', extension))
  ) FROM media WHERE id=_id INTO _r;
  SELECT REGEXP_REPLACE(_r, '^ +| $', '') INTO _r;
  SELECT REGEXP_REPLACE(_r, '/+', '/') INTO _r;
  SELECT REGEXP_REPLACE(_r, '\\\.+', '.') INTO _r;
  SELECT REGEXP_REPLACE(_r, '\<.*\>', '') INTO _r;
  RETURN _r;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP FUNCTION IF EXISTS `get_area_id` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE FUNCTION `get_area_id`() RETURNS varchar(80) CHARSET utf8mb4
    DETERMINISTIC
BEGIN
  DECLARE _id VARCHAR(120);
  SELECT area_id FROM yp.entity WHERE db_name=database() INTO _id;
  RETURN _id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP FUNCTION IF EXISTS `get_home_id` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE FUNCTION `get_home_id`() RETURNS varchar(16) CHARSET utf8mb4
    DETERMINISTIC
BEGIN
  DECLARE _id VARCHAR(16);
  SELECT  id FROM media WHERE parent_id='0' INTO _id;
  RETURN _id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP FUNCTION IF EXISTS `get_id` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE FUNCTION `get_id`() RETURNS varchar(80) CHARSET utf8mb4
    DETERMINISTIC
BEGIN
  DECLARE _id VARCHAR(120);
  SELECT id FROM yp.entity WHERE db_name=database() INTO _id;
  RETURN _id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP FUNCTION IF EXISTS `get_ident` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE FUNCTION `get_ident`() RETURNS varchar(80) CHARSET utf8mb4
    DETERMINISTIC
BEGIN
  DECLARE _ident VARCHAR(120);
  SELECT ident FROM yp.entity WHERE db_name=database() INTO _ident;
  RETURN _ident;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP FUNCTION IF EXISTS `get_json_array` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE FUNCTION `get_json_array`(_json json,
  _index int(8) unsigned
) RETURNS text CHARSET utf8mb4
    DETERMINISTIC
BEGIN
  DECLARE _res text;
  SELECT JSON_UNQUOTE(JSON_EXTRACT(_json, CONCAT("$[", _index, "]"))) INTO _res;
  RETURN _res;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP FUNCTION IF EXISTS `get_json_object` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE FUNCTION `get_json_object`(_json json,
  _name text
) RETURNS text CHARSET utf8mb4
    DETERMINISTIC
BEGIN
  DECLARE _res text;
  SELECT JSON_UNQUOTE(JSON_EXTRACT(_json, CONCAT("$.", _name))) INTO _res;
  RETURN _res;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP FUNCTION IF EXISTS `get_privilege` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE FUNCTION `get_privilege`(_uid VARBINARY(16),
  _area VARCHAR(12)
) RETURNS tinyint(2)
    DETERMINISTIC
BEGIN
  DECLARE _id VARBINARY(16);
  DECLARE _res TINYINT(2);
  DECLARE _priv TINYINT(2);

  SELECT privilege FROM huber WHERE id=_uid INTO _priv;
  IF _priv IS NULL OR _priv='' THEN
    IF _area = 'public' THEN
      SET _res=1;
    ELSE
      SET _res=0;
    END IF;
  ELSE
    SET _res=_priv;
  END IF;
  RETURN _res;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP FUNCTION IF EXISTS `init_env` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE FUNCTION `init_env`(_lc_time VARCHAR(512),
  _rows_per_page tinyint(4)
) RETURNS varchar(80) CHARSET utf8mb4
    DETERMINISTIC
BEGIN
  SET lc_time_names = _lc_time;
  SET @rows_per_page = _rows_per_page;
  RETURN  @rows_per_page;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP FUNCTION IF EXISTS `is_new` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE FUNCTION `is_new`(_metadata JSON,
  _oid VARCHAR(16),
  _uid VARCHAR(16)
) RETURNS tinyint(1)
    DETERMINISTIC
BEGIN
  RETURN IF(
      NOT json_valid(_metadata) OR 
      _metadata IS NULL OR _metadata IN('{}', '') OR _oid = _uid OR
      JSON_EXTRACT(_metadata, "$._seen_") IS NULL OR 
      JSON_UNQUOTE(JSON_EXTRACT(_metadata, CONCAT("$._seen_.", _uid))) IS NOT NULL, 
      0, 1
    );
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP FUNCTION IF EXISTS `is_parent_of` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE FUNCTION `is_parent_of`(_parent_id VARCHAR(16),
  _node_id VARCHAR(16)
) RETURNS tinyint(2)
    DETERMINISTIC
BEGIN

  DECLARE _pid VARCHAR(16);
  DECLARE _res VARCHAR(16);
  DECLARE _depth SMALLINT DEFAULT 0;

  IF _node_id IS NULL OR _parent_id IS NULL THEN 
    RETURN 0;
  END IF;

  IF _node_id NOT IN ('', 0, '0', "*") AND _parent_id = _node_id THEN
    RETURN 1;
  END IF; 
  SELECT IF(parent_id=_parent_id, 1, 0), parent_id 
    FROM media WHERE id=_node_id INTO _res, _pid;
  WHILE _depth  < 120 AND _pid != '0' AND _res = 0 DO
    SELECT IF(parent_id=_parent_id, 1, 0), parent_id 
      FROM media WHERE id=_pid INTO _res, _pid;
    SELECT _depth + 1 INTO _depth;
  END WHILE;
  RETURN _res;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP FUNCTION IF EXISTS `layoutMatching` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE FUNCTION `layoutMatching`(_hashtag VARCHAR(512),
   _key VARCHAR(512),
   _screen  VARCHAR(16),
   _lang  VARCHAR(16)
) RETURNS int(8)
    DETERMINISTIC
BEGIN
  DECLARE res INT(8) DEFAULT 0;
  SELECT IF(_hashtag=concat(_key, '.', _lang, '.', _screen), 6, 0)
     + IF(_hashtag=concat(_key, '.', _screen, '.', _lang), 6, 0)
     + IF(_hashtag=concat(_key, '.', _lang), 4, 0)
     + IF(_hashtag=concat(_key, '.', _screen), 5, 0)
     + IF(_hashtag=_key , 1, 0) INTO res;
  RETURN res;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP FUNCTION IF EXISTS `layout_ident` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE FUNCTION `layout_ident`(_tag VARCHAR(512),
   _lang  VARCHAR(16),
   _device  VARCHAR(16)
) RETURNS varchar(512) CHARSET utf8mb4
    DETERMINISTIC
BEGIN
  RETURN concat(_tag, '!', _lang, '!', _device);
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP FUNCTION IF EXISTS `layout_score` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE FUNCTION `layout_score`(_hash VARCHAR(512),
   _tag VARCHAR(512),
   _lang  VARCHAR(16),
   _device  VARCHAR(16)
) RETURNS int(8)
    DETERMINISTIC
BEGIN
  DECLARE res INT(8) DEFAULT 0;
  SELECT IF(_hash=layout_ident(_tag, _lang, _device), 6, 0)
     + IF(_hash LIKE concat(_tag, '!', _lang, '!%'), 5, 0)
     + IF(_hash LIKE concat(_tag, '!%', _lang), 3, 0) INTO res;
  RETURN res;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP FUNCTION IF EXISTS `logical_path` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE FUNCTION `logical_path`(_id VARCHAR(16)
) RETURNS longtext CHARSET utf8mb4 COLLATE utf8mb4_bin
    DETERMINISTIC
BEGIN
  DECLARE _r VARCHAR(1024);
  DECLARE _pid VARCHAR(16);
  DECLARE _home_id VARCHAR(16);
  DECLARE _max INTEGER DEFAULT 0;
  DECLARE _res JSON;

  IF _pid IN('0', NULL) THEN 
    SELECT JSON_ARRAY(id) FROM media WHERE parent_id='0' INTO _res;
    RETURN _res;
  END IF;

  SELECT parent_id, JSON_ARRAY(id) FROM media WHERE id=_id INTO _pid, _res;
  WHILE _pid != '0' AND _max < 100 DO 
    SELECT _max + 1 INTO _max;
    SELECT parent_id, JSON_MERGE(JSON_ARRAY(_pid), _res) FROM media WHERE id = _pid INTO _pid, _res;
  END WHILE;
  RETURN _res;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP FUNCTION IF EXISTS `media_notified` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE FUNCTION `media_notified`(_metadata JSON,
  _uid VARCHAR(16)
) RETURNS int(11)
    DETERMINISTIC
BEGIN
  DECLARE _res INTEGER DEFAULT 0;
  SELECT 
    JSON_QUERY(_metadata, "$.acknowledge") IS NOT NULL AND 
    IF(JSON_SEARCH(JSON_QUERY(_metadata,"$.acknowledge"), "one", _uid) IS NULL, 1, 0) INTO _res;
  RETURN _res;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP FUNCTION IF EXISTS `media_ttl` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE FUNCTION `media_ttl`(_uid VARCHAR(16),
  _rid VARCHAR(16)
) RETURNS int(11)
    DETERMINISTIC
BEGIN
  DECLARE _expiry INT(11);
  DECLARE _db_name VARCHAR(60);
  DECLARE _category VARCHAR(60);
  DECLARE _file_path VARCHAR(1024);
  
  SET _expiry = NULL;
  SELECT category FROM media WHERE id=_rid INTO _category;

  SELECT expiry_time FROM media LEFT JOIN permission ON 
      resource_id=media.id WHERE entity_id=_uid AND media.id=_rid INTO _expiry;

  IF _expiry IS NULL THEN 
      SELECT expiry_time FROM permission WHERE (entity_id=_uid AND resource_id='*') INTO _expiry;
  END IF;
  IF _expiry IS NULL THEN 
      SELECT file_path FROM media WHERE id=_rid INTO _file_path;
      SELECT IFNULL(expiry_time, 0) FROM media LEFT JOIN permission ON 
        resource_id=media.id AND entity_id= _uid WHERE  REPLACE(_file_path  , '(',')')  REGEXP  REPLACE(user_filename , '(',')')  AND permission 
        IS NOT NULL
        ORDER BY (LENGTH(parent_path)-LENGTH(REPLACE(parent_path, '/', '')))  DESC LIMIT 1 
        INTO _expiry;
  END IF;
  
  SELECT IFNULL(_expiry, 0) INTO _expiry;
  SELECT IF(_expiry=0, 0, _expiry - UNIX_TIMESTAMP()) INTO _expiry;
  RETURN _expiry;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP FUNCTION IF EXISTS `media_unseen` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE FUNCTION `media_unseen`(_metadata JSON,
  _uid VARCHAR(16)
) RETURNS int(11)
    DETERMINISTIC
BEGIN
  DECLARE _res INTEGER DEFAULT 0;
  SELECT 
    IF(JSON_EXISTS(_metadata, "$._seen_") AND NOT JSON_EXISTS(_metadata, CONCAT("$._seen_.", _uid)), 1, 0) INTO _res;
  RETURN _res;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP FUNCTION IF EXISTS `node_id_from_path` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE FUNCTION `node_id_from_path`(_path VARCHAR(1024)
) RETURNS varchar(16) CHARSET utf8mb4 COLLATE utf8mb4_general_ci
    DETERMINISTIC
BEGIN
  DECLARE _r VARCHAR(16) CHARACTER SET ascii;
  DECLARE _node_id VARCHAR(16) CHARACTER SET ascii;
  IF _path regexp  '^\/.+' THEN 
    SELECT id FROM media 
      WHERE REPLACE(file_path, '/', '') = 
      REPLACE(IF(category ='hub', CONCAT(_path, '.', extension), _path), '/','')
      INTO _node_id;
  ELSE 
    SELECT id FROM media WHERE file_path = '/' INTO _node_id;
  END IF;
  SELECT id FROM media WHERE id = _node_id INTO _r;
  RETURN _r;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP FUNCTION IF EXISTS `normalize_path` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE FUNCTION `normalize_path`(_id VARCHAR(16)
) RETURNS varchar(1024) CHARSET utf8mb4
    DETERMINISTIC
BEGIN
  DECLARE _r VARCHAR(1024);

  SELECT CONCAT('/', parent_path) FROM media WHERE id=_id  INTO @path ;
  WHILE @path regexp '\/\/' DO 
    SELECT REPLACE(@path, '//', '/') INTO @path;
  END WHILE;
  UPDATE media SET parent_path=TRIM(TRAILING '/' FROM @path) WHERE id=_id;

  SELECT file_path FROM media WHERE id=_id INTO @path ;
  WHILE @path regexp '\/\/' DO 
    SELECT REPLACE(@path, '//', '/') INTO @path;
  END WHILE;

  UPDATE media SET file_path=TRIM(TRAILING '/' FROM @path) WHERE id=_id;

  UPDATE media SET user_filename=TRIM('/' FROM user_filename) WHERE id=_id;

  SELECT CONCAT(parent_path, '/', TRIM('/' FROM user_filename)) 
    FROM media WHERE id=_id INTO _r;
  RETURN _r;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP FUNCTION IF EXISTS `parent_path` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE FUNCTION `parent_path`(_id VARCHAR(16) CHARACTER SET ascii
) RETURNS text CHARSET utf8mb4 COLLATE utf8mb4_general_ci
    DETERMINISTIC
BEGIN
  DECLARE _home_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _pid VARCHAR(16) CHARACTER SET ascii DEFAULT NULL;
  DECLARE _nodename VARCHAR(600) ;
  DECLARE _r TEXT;
  DECLARE _type VARCHAR(1000);
  DECLARE _max INTEGER DEFAULT 0;
  SET @res = '/';

  SELECT id FROM media WHERE parent_id='0' INTO _home_id;
  IF _home_id = _id THEN
    RETURN '';
  END IF;

  SELECT id FROM media WHERE id=_id AND parent_id = _id INTO _pid;
  IF (_pid IS NOT NULL) THEN
    RETURN '/__trash__/';
  END IF;

  SET @pid = NULL;
  SELECT parent_id FROM media WHERE id=_id INTO _pid;


  SELECT user_filename, parent_id, category FROM media WHERE id=_pid 
    INTO _nodename, @pid, _type;

  IF (@pid IS NULL) THEN
    RETURN '/__trash__/';
  ELSEIF _type = 'root' THEN 
    RETURN '/';
  ELSE
    SELECT _nodename INTO @res;
    
    WHILE _pid != '0' 
      AND _pid IS NOT NULL 
      AND _nodename IS NOT NULL 
      AND @pid IS NOT NULL 
      AND _max < 100 DO 
        SELECT _max + 1 INTO _max;
        SELECT parent_id FROM media WHERE id = _pid INTO _pid;



        SELECT user_filename, parent_id, category FROM media WHERE id=_pid 
          INTO _nodename, @pid, _type;
        IF _type = 'root' OR @pid='0' OR _nodename IN('', '/') THEN
          SELECT '0', NULL, NULL INTO _pid, _nodename, @pid;
        ELSE
          SELECT CONCAT(_nodename, '/', IFNULL(@res, '')) INTO @res;
        END IF;
    END WHILE;
  END IF;
  IF (@res IS NULL) THEN
    RETURN '/';
  END IF;
  SELECT REGEXP_REPLACE(@res, '^[/ ]+|\<.*\>|[/ ]+$', '') INTO @res;
  SELECT CONCAT('/', REGEXP_REPLACE(@res, '( *)(/+)( *)', '/'), '/') INTO @res;
  SELECT REGEXP_REPLACE(@res, '/+', '/') INTO @res;
  RETURN REGEXP_REPLACE(@res, '^ +| +$', '');
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP FUNCTION IF EXISTS `parent_permission` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE FUNCTION `parent_permission`(_uid VARCHAR(16) CHARACTER SET ascii,
  _node_id VARCHAR(16) CHARACTER SET ascii
) RETURNS tinyint(2)
    DETERMINISTIC
BEGIN
  DECLARE _perm TINYINT(4) DEFAULT 0;

    WITH RECURSIVE parent_media AS 
      (
        SELECT m.id,m.parent_id ,CASE WHEN p.assign_via = 'root' THEN 0  ELSE IFNULL(p.permission,0) END permission , p.assign_via
        FROM media m 
        LEFT JOIN permission p ON 
          p.resource_id=m.parent_id AND p.entity_id IN(_uid, '*') 
        WHERE m.id = _node_id  
          UNION ALL
        SELECT  m.id, m.parent_id,CASE WHEN p.assign_via = 'root' THEN 0  ELSE IFNULL(p.permission,0) END permission, p.assign_via
        FROM media m
        LEFT JOIN permission p ON 
          p.resource_id=m.parent_id AND  p.entity_id IN(_uid, '*') 
        INNER JOIN parent_media AS t ON 
          m.id = t.parent_id  AND m.parent_id <> '0'  AND t.permission = 0 
          AND IFNULL(t.assign_via,0) NOT IN ('no_traversal','root')
      )
      SELECT max(permission) FROM parent_media WHERE permission <> 0  INTO  _perm ;

      RETURN IFNULL(_perm,0);
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP FUNCTION IF EXISTS `parent_permission_old` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE FUNCTION `parent_permission_old`(_uid VARCHAR(16),
  _node_id VARCHAR(16)
) RETURNS tinyint(2)
    DETERMINISTIC
BEGIN

  DECLARE _pid VARCHAR(16);
  DECLARE _perm TINYINT(4) DEFAULT 0;
  DECLARE _res VARCHAR(16);
  DECLARE _depth SMALLINT DEFAULT 0;
  SELECT m.parent_id, IFNULL(p.permission,0) FROM media m LEFT JOIN permission p ON 
    p.resource_id=m.parent_id AND  p.entity_id IN(_uid, '*') WHERE m.id=_node_id  LIMIT 1
    INTO _pid, _perm;
  WHILE _depth  < 120 AND (_pid != '0' OR _pid IS NULL) AND _perm = 0 DO
    SELECT m.parent_id, IFNULL(p.permission,0) FROM media m LEFT JOIN permission p ON 
      p.resource_id=m.parent_id AND  p.entity_id IN(_uid, '*') AND p.assign_via != 'no_traversal'  WHERE  m.id=_pid 
      LIMIT 1
      INTO _pid, _perm;
      SELECT _depth + 1 INTO _depth;
  END WHILE;
  RETURN _perm;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP FUNCTION IF EXISTS `permission_tree` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE FUNCTION `permission_tree`(_id VARCHAR(16)
) RETURNS varchar(16) CHARSET utf8mb4
    DETERMINISTIC
BEGIN
  DECLARE _r VARCHAR(16) DEFAULT '*';
  DECLARE _pid VARCHAR(16);
  DECLARE _count INTEGER;
  DECLARE _max INTEGER DEFAULT 0;

  SELECT COUNT(*) FROM permission WHERE resource_id = _id INTO _count;
  IF  _count > 0 THEN
    SELECT _id INTO _r;
    SELECT 'O'  INTO _pid;
  ELSE
    SELECT parent_id FROM media WHERE id = _id INTO _pid;
  END IF;

  WHILE _pid != '0' AND _count = 0 AND _max < 100 DO 
    SELECT _max + 1 INTO _max;
    SET @prev = _pid;
    SELECT parent_id FROM media WHERE id = _pid INTO _pid;
    SELECT count(*) FROM permission WHERE resource_id = _pid INTO _count;
    IF _count > 0 THEN
      SELECT _pid INTO _r;
    END IF;
  END WHILE;
  RETURN _r;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP FUNCTION IF EXISTS `read_json_array` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE FUNCTION `read_json_array`(_json json,
  _index int(8) unsigned
) RETURNS text CHARSET utf8mb4
    DETERMINISTIC
BEGIN
  DECLARE _res text;
  SELECT TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(_json, CONCAT("$[", _index, "]"))), '')) INTO _res;
  RETURN _res;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP FUNCTION IF EXISTS `read_json_object` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE FUNCTION `read_json_object`(_json json,
  _name text
) RETURNS text CHARSET utf8mb4
    DETERMINISTIC
BEGIN
  DECLARE _res text;
  SELECT TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(_json, CONCAT("$.", _name))), '')) INTO _res;
  RETURN _res;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP FUNCTION IF EXISTS `set_env` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE FUNCTION `set_env`(_home_root VARCHAR(512),
  _date_format VARCHAR(512),
  _lc_time VARCHAR(512),
  _rows_per_page tinyint(4)
) RETURNS varchar(80) CHARSET utf8mb4
    DETERMINISTIC
BEGIN
  SET @home_root = _home_root;
  SET @dformat = _date_format;
  SET lc_time_names = _lc_time;
  SET @rows_per_page = _rows_per_page;
  
  SELECT area, area_id from yp.entity where db_name=database() INTO @area, @area_id;
  RETURN @home_root;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP FUNCTION IF EXISTS `strToBits` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE FUNCTION `strToBits`(_str VARCHAR(8)

) RETURNS bit(8)
    DETERMINISTIC
BEGIN
  DECLARE _bits BIT(8) DEFAULT NULL;
  SELECT CAST(_str AS UNSIGNED) INTO _bits;
  RETURN _bits;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP FUNCTION IF EXISTS `uniqueId` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE FUNCTION `uniqueId`() RETURNS varchar(16) CHARSET utf8mb4
    DETERMINISTIC
BEGIN
  DECLARE _res VARCHAR(16);
  SELECT CONCAT(
    SUBSTRING_INDEX(UUID(), '-', 1),
    SUBSTRING_INDEX(UUID(), '-', 1)
  ) INTO _res;
  RETURN _res;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP FUNCTION IF EXISTS `unique_filename` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE FUNCTION `unique_filename`(_pid VARCHAR(16),
  _file_name VARCHAR(200),
  _ext VARCHAR(20)
) RETURNS varchar(2000) CHARSET utf8mb4 COLLATE utf8mb4_general_ci
    DETERMINISTIC
BEGIN
  DECLARE _r VARCHAR(2000);
  DECLARE _fname VARCHAR(1024);
  DECLARE _base VARCHAR(1024);
  DECLARE _exten VARCHAR(1024);
  
    SELECT _file_name INTO _fname;
    SELECT _fname INTO _base;
    SELECT '' INTO   _exten;

    IF _fname regexp '\\\([0-9]+\\\)$'  THEN 
      SELECT SUBSTRING_INDEX(_fname, '(', 1) INTO _base;
      SELECT  SUBSTRING_INDEX(_fname, ')', -1) INTO _exten;
    END IF;

    WITH RECURSIVE chk as
      (
        SELECT @de:=0 as n ,  _fname fname,
        (SELECT COUNT(1) FROM media WHERE parent_id = _pid 
          AND user_filename = _fname AND extension=IFNULL(_ext, '')
        ) cnt
      UNION ALL 
        SELECT @de:= n+1 n , CONCAT(_base, "(", n+1, ")", _exten) fname ,
        (SELECT COUNT(1) FROM media WHERE parent_id = _pid 
          AND user_filename = CONCAT(_base, "(", n+1, ")", _exten)
          AND extension=IFNULL(_ext, '') 
        ) cnt
        FROM chk c 
        WHERE n<1000 AND cnt >=1
      )
    SELECT fname FROM chk WHERE n =@de  INTO _r ;
  RETURN _r;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP FUNCTION IF EXISTS `unique_filenamex` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE FUNCTION `unique_filenamex`(_pid VARCHAR(16) CHARACTER SET ascii,
  _file_name VARCHAR(200),
  _ext VARCHAR(20)
) RETURNS varchar(2000) CHARSET utf8mb4
    DETERMINISTIC
BEGIN
  DECLARE _r VARCHAR(2000);
  DECLARE _fname VARCHAR(1024);
  DECLARE _base VARCHAR(1024);
  DECLARE _exten VARCHAR(1024);
  
    SELECT _file_name INTO _fname;
    SELECT _fname INTO _base;
    SELECT '' INTO   _exten;

    IF _fname regexp '\\\([0-9]+\\\)$'  THEN 
      SELECT SUBSTRING_INDEX(_fname, '(', 1) INTO _base;
      SELECT  SUBSTRING_INDEX(_fname, ')', -1) INTO _exten;
    END IF;

    WITH RECURSIVE chk as
      (
        SELECT @de:=0 as n ,  _fname fname,
        (SELECT COUNT(1) FROM media WHERE parent_id = _pid AND user_filename = _fname) cnt
      UNION ALL 
        SELECT @de:= n+1 n , CONCAT(_base, "(", n+1, ")", _exten) fname ,
        (SELECT COUNT(1) FROM media WHERE parent_id = _pid  AND user_filename = CONCAT(_base, "(", n+1, ")", _exten)) cnt
        FROM chk c 
        WHERE n<1000 AND cnt >=1
      )
    SELECT fname FROM chk WHERE n =@de  INTO _r ;

  RETURN _r;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP FUNCTION IF EXISTS `unique_filename_next` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE FUNCTION `unique_filename_next`(_pid VARCHAR(16),
  _file_name VARCHAR(200),
  _ext VARCHAR(20)
) RETURNS varchar(1024) CHARSET utf8mb4
    DETERMINISTIC
BEGIN
  DECLARE _r VARCHAR(1024);
  DECLARE _fname VARCHAR(1024);
  DECLARE _count INT(8) DEFAULT 0;
  DECLARE _depth TINYINT(4) DEFAULT 0;

  SELECT TRIM('/' FROM _file_name) INTO _fname;
  
  SELECT count(*) FROM media WHERE 
    parent_id=_pid AND (TRIM('/' FROM user_filename) = _fname) AND 
    extension=_ext INTO _count;
  IF _count = 0 THEN 
    SELECT _fname INTO _r;
  ELSEIF _fname regexp '\\\([0-9]+\\\)$' THEN 
    WHILE _depth  < 1000 AND _count > 0 DO 
      SELECT _depth + 1 INTO _depth;
      
      
      SELECT SUBSTRING_INDEX(_fname, '(', 1) INTO @base;
      SELECT SUBSTRING_INDEX(_fname, ')', -1) INTO @ext;
      SELECT CONCAT(@base, "(", _depth, ")", @ext) INTO _r;
      SELECT count(*) FROM media WHERE 
        parent_id=_pid AND TRIM('/' FROM user_filename) = _r
        INTO _count;
    END WHILE;
  ELSE 
    SELECT CONCAT(_fname, "(1)") INTO _r;
    SELECT count(*) FROM media WHERE 
      parent_id=_pid AND TRIM('/' FROM user_filename) = _r
      INTO _count;
    WHILE _depth  < 1000 AND _count > 0 DO 
      SELECT _depth + 1 INTO _depth;
      
      
      SELECT SUBSTRING_INDEX(_r, '(', 1) INTO @base;
      SELECT SUBSTRING_INDEX(_r, ')', -1) INTO @ext;
      SELECT CONCAT(@base, "(", _depth, ")", @ext) INTO _r;
      SELECT count(*) FROM media WHERE 
        parent_id=_pid AND TRIM('/' FROM user_filename) = _r
        INTO _count;
    END WHILE;
  END IF;
  SELECT SUBSTRING_INDEX(_r, '/', -1) INTO _r;
  RETURN _r;
  
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP FUNCTION IF EXISTS `unique_filename_trash` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE FUNCTION `unique_filename_trash`(_pid VARCHAR(16),
  _file_name VARCHAR(200),
  _ext VARCHAR(20)
) RETURNS varchar(2000) CHARSET utf8mb4
    DETERMINISTIC
BEGIN
  DECLARE _r VARCHAR(2000);
  DECLARE _fname VARCHAR(1024);
  DECLARE _path VARCHAR(2000);
  DECLARE _parent_path VARCHAR(2000);
  DECLARE _count INT(8) DEFAULT 0;
  DECLARE _depth TINYINT(4) DEFAULT 0;

  
  SELECT REGEXP_REPLACE(_file_name, '^/| +$', '') INTO _fname;
  SELECT REGEXP_REPLACE(_fname, '/+', '-') INTO _r;

  
  SELECT CONCAT(parent_path(id), user_filename) FROM trash_media 
    WHERE id=_pid INTO _parent_path;

  SELECT REGEXP_REPLACE(_parent_path, '/+', '/') INTO _parent_path;
  SELECT REGEXP_REPLACE(_parent_path, '\<.*\>|/+$', '') INTO _parent_path;

  IF(_ext IS NULL OR _ext IN('', 'folder')) THEN
    SELECT CONCAT(_parent_path, '/', _file_name) INTO _path;
  ELSE
    SELECT CONCAT(_parent_path, '/', _file_name, '.', _ext) INTO _path;
  END IF;

  SELECT count(*) FROM trash_media WHERE file_path = _path INTO _count;
  SELECT _count + count(*) FROM trash_media WHERE 
    parent_id=_pid AND user_filename=_file_name AND extension=_ext INTO _count;

  IF _count < 1 THEN 
    SELECT _fname INTO _r;
  ELSEIF _fname regexp '\\\([0-9]+\\\)$' THEN 
    WHILE _depth  < 1000 AND _count > 0 DO 
      SELECT _depth + 1 INTO _depth;
      SELECT SUBSTRING_INDEX(_fname, '(', 1) INTO @base;
      SELECT SUBSTRING_INDEX(_fname, ')', -1) INTO @ext;
      SELECT CONCAT(@base, "(", _depth, ")", @ext) INTO _r;
      SELECT count(*) FROM trash_media WHERE 
        parent_id=_pid AND TRIM('/' FROM user_filename) = _r
        INTO _count;
    END WHILE;
  ELSE 
    SELECT CONCAT(_fname, "(1)") INTO _r;
    SELECT count(*) FROM trash_media WHERE 
      parent_id=_pid AND TRIM('/' FROM user_filename) = _r
      INTO _count;
    WHILE _depth  < 1000 AND _count > 0 DO 
      SELECT _depth + 1 INTO _depth;
      SELECT SUBSTRING_INDEX(_r, '(', 1) INTO @base;
      SELECT SUBSTRING_INDEX(_r, ')', -1) INTO @ext;
      SELECT CONCAT(@base, "(", _depth, ")", @ext) INTO _r;
      SELECT count(*) FROM trash_media WHERE 
        parent_id=_pid AND TRIM('/' FROM user_filename) = _r
        INTO _count;
    END WHILE;
  END IF;
  SELECT SUBSTRING_INDEX(_r, '/', -1) INTO _r;
  RETURN _r;
  
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP FUNCTION IF EXISTS `user_expiry` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE FUNCTION `user_expiry`(_uid VARCHAR(16) CHARACTER SET ascii,
  _rid VARCHAR(16) CHARACTER SET ascii
) RETURNS int(11)
    DETERMINISTIC
BEGIN
  DECLARE _expiry INT(11);
  DECLARE _db_name VARCHAR(60);
  DECLARE _category VARCHAR(60);
  DECLARE _file_path VARCHAR(1024);
  
  SET _expiry = NULL;
  SELECT category FROM media WHERE id=_rid INTO _category;
  SELECT IF(_uid IN ('nobody', 'ffffffffffffffff', '*'), '*', _uid) INTO _uid;
  SELECT expiry_time FROM media LEFT JOIN permission ON 
      resource_id=media.id WHERE entity_id=_uid AND media.id=_rid INTO _expiry;

  IF _expiry IS NULL THEN 
      SELECT expiry_time FROM permission WHERE (entity_id=_uid AND resource_id='*') INTO _expiry;
  END IF;
  IF _expiry IS NULL THEN 
      SELECT file_path FROM media WHERE id=_rid INTO _file_path;
      SELECT IFNULL(expiry_time, 0) FROM media LEFT JOIN permission ON 
        resource_id=media.id AND entity_id= _uid WHERE  REPLACE(_file_path, '(',')')  REGEXP  REPLACE(user_filename, '(',')')  AND permission 
        IS NOT NULL
        ORDER BY (LENGTH(parent_path)-LENGTH(REPLACE(parent_path, '/', '')))  DESC LIMIT 1 
        INTO _expiry;
  END IF;
  
  SELECT IFNULL(_expiry, 0) INTO _expiry;
  RETURN _expiry;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP FUNCTION IF EXISTS `user_permission` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE FUNCTION `user_permission`(_uid VARCHAR(512) CHARACTER SET ascii,
  _rid VARCHAR(16)  CHARACTER SET ascii
) RETURNS tinyint(2)
    DETERMINISTIC
BEGIN
  DECLARE _perm TINYINT(2) DEFAULT 0;
  DECLARE _db_name VARCHAR(60);
  DECLARE _category VARCHAR(60);
  DECLARE _file_path VARCHAR(1024);
  DECLARE _token VARCHAR(1024);
  DECLARE _parent_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _parent_perm TINYINT(4);

  SELECT category FROM media WHERE id=_rid INTO _category;
  SELECT IF(_uid IN ('*', 'ffffffffffffffff', 'nobody'), '*', _uid) INTO _uid;

  IF _category = "hub" THEN
    SELECT permission FROM permission 
      WHERE resource_id=_rid AND entity_id=_uid INTO _perm;
  ELSE
    SELECT IFNULL(permission, 0) FROM permission WHERE 
      (entity_id=_uid AND _uid != '*' AND resource_id='*') 
      ORDER BY permission DESC LIMIT 1
      INTO _perm;

    IF _perm THEN 
      RETURN _perm;
    ELSE 
      SELECT IFNULL(permission, 0) FROM permission WHERE
        (entity_id IN (_uid, '*', 'ffffffffffffffff', 'nobody')) AND resource_id=_rid 
      ORDER BY permission DESC LIMIT 1
      INTO _perm;
    END IF;

    IF _perm THEN 
      RETURN _perm;
    ELSE 
      SELECT IFNULL(parent_permission(_uid, _rid), 0) INTO _perm;
    END IF;

    IF _perm THEN 
      RETURN _perm;
    ELSE 
      SELECT IFNULL(permission, 0) FROM permission WHERE 
        (entity_id= '*' AND resource_id=_rid) 
        ORDER BY permission DESC LIMIT 1
        INTO _perm;
    END IF;

    IF _perm THEN 
      RETURN _perm;
    ELSE 
      SELECT MAX(permission) FROM permission WHERE 
        (entity_id IN ('*', 'ffffffffffffffff', 'nobody') AND 
        (resource_id='*' OR resource_id=_rid) ) 
        ORDER BY permission DESC LIMIT 1
        INTO _perm;
    END IF;
    
  END IF;
  SELECT IFNULL(_perm, 0) INTO _perm;
  RETURN _perm;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP FUNCTION IF EXISTS `user_perm_msg` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE FUNCTION `user_perm_msg`(_uid VARCHAR(16),
  _rid VARCHAR(16)
) RETURNS text CHARSET utf8mb4
    DETERMINISTIC
BEGIN
  DECLARE _msg MEDIUMTEXT;
  DECLARE _db_name VARCHAR(60);
  DECLARE _category VARCHAR(60);
  DECLARE _file_path VARCHAR(1024);
  
  SET _msg = NULL;
  SELECT category FROM media WHERE id=_rid INTO _category;

  SELECT IFNULL(message, '') FROM media LEFT JOIN permission ON 
      resource_id=media.id WHERE entity_id=_uid AND media.id=_rid INTO _msg;

  IF _msg IS NULL THEN 
      SELECT message FROM permission WHERE (entity_id=_uid AND resource_id='*') INTO _msg;
  END IF;
  IF _msg IS NULL THEN 
    SELECT file_path FROM media WHERE id=_rid INTO _file_path;
    SELECT IFNULL(message, '') FROM media LEFT JOIN permission ON 
      resource_id=media.id AND entity_id= _uid WHERE  REPLACE(_file_path  , '(',')')  REGEXP  REPLACE(user_filename  , '(',')')  AND permission 
      IS NOT NULL 
      ORDER BY (LENGTH(parent_path)-LENGTH(REPLACE(parent_path, '/', '')))  DESC LIMIT 1 
      INTO _msg;
  END IF;
  
  SELECT IFNULL(_msg, '') INTO _msg;
  RETURN _msg;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `acknowledge_message` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `acknowledge_message`(
  IN _message_id VARCHAR(16),
  IN  _uid VARCHAR(16)
)
BEGIN
  DECLARE _ticket_id  int(11) ;
  DECLARE _ref_sys_id int(11) unsigned default 0 ;
  DECLARE _old_ref_sys_id int(11) unsigned default 0 ;

  SELECT sys_id FROM channel WHERE message_id=_message_id INTO _ref_sys_id;

  SELECT ref_sys_id FROM read_channel WHERE  uid = _uid INTO _old_ref_sys_id;

  SELECT CASE WHEN _ref_sys_id < IFNULL(_old_ref_sys_id,0) THEN IFNULL(_old_ref_sys_id,0)  ELSE _ref_sys_id END INTO _ref_sys_id;

  INSERT INTO read_channel(uid,ref_sys_id,ctime) SELECT _uid,_ref_sys_id,UNIX_TIMESTAMP() 
  ON DUPLICATE KEY UPDATE ref_sys_id= _ref_sys_id , ctime =UNIX_TIMESTAMP();


  UPDATE channel SET  metadata = JSON_SET(metadata,CONCAT("$._seen_.", _uid), UNIX_TIMESTAMP())
  WHERE sys_id <= _ref_sys_id   AND 
  JSON_EXISTS(metadata, CONCAT("$._seen_.", _uid))= 0;
 
    SELECT ticket_id FROM map_ticket WHERE message_id = _message_id INTO _ticket_id;

    IF _ticket_id IS NOT NULL THEN 
      UPDATE channel c INNER JOIN map_ticket mt ON mt.message_id = c.message_id
      SET  c.metadata = JSON_SET(metadata,CONCAT("$._seen_.", _uid), UNIX_TIMESTAMP())
      WHERE c.sys_id <= _ref_sys_id   AND mt.ticket_id = _ticket_id AND
      JSON_EXISTS(metadata, CONCAT("$._seen_.", _uid))= 0;

      INSERT INTO yp.read_ticket_channel(uid,ticket_id , ref_sys_id,ctime) SELECT _uid,_ticket_id,_ref_sys_id,UNIX_TIMESTAMP() 
      ON DUPLICATE KEY UPDATE ref_sys_id= _ref_sys_id , ctime =UNIX_TIMESTAMP();
    END IF;


  SELECT * FROM channel WHERE sys_id = _ref_sys_id;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `acl_array_check` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `acl_array_check`(
  IN _key VARCHAR(16),
  IN _permission TINYINT(4),
  IN _nodes JSON
)
BEGIN

  DECLARE _uid VARCHAR(16);
  DECLARE _owner_id VARCHAR(16);
  DECLARE _area VARCHAR(16);
  DECLARE _src_db_name VARCHAR(255);
  DECLARE _mfs_root VARCHAR(512);

  DECLARE _rid VARCHAR(16);
  DECLARE _i INT(8) DEFAULT 0;
  DECLARE _j INT(8) DEFAULT 0;

  SELECT id FROM yp.entity WHERE id=_key or ident=_key INTO _uid;

  DROP TABLE IF EXISTS __tmp_ids;
  CREATE TEMPORARY TABLE __tmp_ids(
    `id` varchar(16) DEFAULT NULL,
    db_name varchar(90) DEFAULT NULL,
    expiry tinyint(4) unsigned,
    asked  tinyint(4) unsigned,
    privilege int(11) 
  ); 

  WHILE _i < JSON_LENGTH(_nodes) DO 
    SELECT JSON_UNQUOTE(JSON_EXTRACT(_nodes, CONCAT("$[", _i, "]"))) INTO @_node;
    SELECT JSON_UNQUOTE(JSON_EXTRACT(@_node, "$.nid")) INTO @_nids;
    SELECT 0 INTO  _j;
    WHILE _j < JSON_LENGTH(@_nids) DO 
      SELECT JSON_UNQUOTE(JSON_EXTRACT(@_nids,CONCAT("$[", _j, "]"))) INTO _rid;
      SELECT db_name, area, owner_id, concat(home_dir, "__storage__/")
        FROM yp.entity LEFT JOIN yp.hub USING(id) WHERE 
        id = yp.hub_id(JSON_UNQUOTE(JSON_EXTRACT(@_node, "$.hub_id")))
        INTO _src_db_name, _area, _owner_id, _mfs_root; 
      
      SET @s = CONCAT(
        "SELECT " ,_src_db_name,".user_permission (", QUOTE(_uid),",",QUOTE(_rid), ") INTO @resperm");
      PREPARE stmt FROM @s;
      EXECUTE stmt;
      DEALLOCATE PREPARE stmt; 

      SET @s = CONCAT(
        "SELECT " ,_src_db_name,".user_expiry (", QUOTE(_uid),",",QUOTE(_rid), ") INTO @resexpiry");
      PREPARE stmt FROM @s;
      EXECUTE stmt;
      DEALLOCATE PREPARE stmt;
      SELECT IF(_area='public', GREATEST(7, @resperm), @resperm) INTO @resperm;
      
      
      
      
      
      INSERT INTO __tmp_ids SELECT 
        _rid, _src_db_name, @resexpiry, _permission, CAST(@resperm AS UNSIGNED); 
        
      SELECT _j + 1 INTO _j;
    END WHILE;
    SELECT _i + 1 INTO _i;
  END WHILE;
  
  SELECT * FROM  __tmp_ids WHERE 
    (expiry = 0 OR expiry > UNIX_TIMESTAMP());

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `acl_array_check_next` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `acl_array_check_next`(
  IN _key VARCHAR(16),
  IN _permission TINYINT(4),
  IN _nodes JSON
)
BEGIN

  DECLARE _uid VARCHAR(16);
  DECLARE _owner_id VARCHAR(16);
  DECLARE _hub_id VARCHAR(16);
  DECLARE _area VARCHAR(16);
  DECLARE _src_db_name VARCHAR(255);
  DECLARE _mfs_root VARCHAR(512);

  DECLARE _rid VARCHAR(16);
  DECLARE _i INT(8) DEFAULT 0;
  DECLARE _j INT(8) DEFAULT 0;

  SELECT id FROM yp.entity WHERE id=_key INTO _uid;

  DROP TABLE IF EXISTS __tmp_ids;
  CREATE TEMPORARY TABLE __tmp_ids(
    `id` varchar(16) DEFAULT NULL,
    `hub_id` varchar(16) DEFAULT NULL,
    db_name varchar(90) DEFAULT NULL,
    expiry tinyint(4) unsigned,
    asked  tinyint(4) unsigned DEFAULT 1,
    privilege int(11) 
  ); 

  IF _permission IS NULL OR _permission=0 THEN 
    SET _permission = 1;
  END IF;

  WHILE _i < JSON_LENGTH(_nodes) DO 
    
    SELECT get_json_array(_nodes, _i) INTO @_node;
    
    SELECT get_json_object(@_node, "nid") INTO @_nids;

    SELECT 0 INTO  _j;
    WHILE _j < JSON_LENGTH(@_nids) DO 
      
      SELECT get_json_array(@_nids, _j) INTO _rid;
      SELECT id, db_name, area, owner_id, concat(home_dir, "__storage__/")
        FROM yp.entity LEFT JOIN yp.hub USING(id) WHERE 
        
        id = yp.hub_id(get_json_object(@_node, "hub_id"))
        INTO _hub_id, _src_db_name, _area, _owner_id, _mfs_root; 
      

      IF _src_db_name IS NOT NULL THEN 
        SET @s = CONCAT(
          "SELECT " ,_src_db_name,".user_permission (", QUOTE(_uid),",",QUOTE(_rid), ") INTO @resperm");
        PREPARE stmt FROM @s;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt; 

        SET @s = CONCAT(
          "SELECT " ,_src_db_name,".user_expiry (", QUOTE(_uid),",",QUOTE(_rid), ") INTO @resexpiry");
        PREPARE stmt FROM @s;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
        SELECT IF(_area='public', GREATEST(7, @resperm), GREATEST(1, @resperm)) INTO @resperm;
        INSERT INTO __tmp_ids SELECT 
          _rid, _hub_id, _src_db_name, @resexpiry, _permission, CAST(@resperm AS UNSIGNED); 
      END IF;          
      SELECT _j + 1 INTO _j;
    END WHILE;
    SELECT _i + 1 INTO _i;
  END WHILE;
  
  SELECT * FROM  __tmp_ids WHERE 
    (expiry = 0 OR expiry > UNIX_TIMESTAMP());

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `acl_check` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `acl_check`(
  IN _uid VARCHAR(255) CHARACTER SET ascii,
  IN _permission TINYINT(4),
  IN _nodes JSON
)
BEGIN

  
  DECLARE _hub_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _area VARCHAR(16);
  DECLARE _src_db_name VARCHAR(255);
  DECLARE _mfs_root VARCHAR(512);
  

  DECLARE _rid VARCHAR(16) CHARACTER SET ascii;
  DECLARE _i INT(4) DEFAULT 0;

  
  

  DROP TABLE IF EXISTS __tmp_ids;
  CREATE TEMPORARY TABLE __tmp_ids(
    `id` varchar(16) CHARACTER SET ascii DEFAULT NULL ,
    `hub_id` varchar(16) CHARACTER SET ascii DEFAULT NULL,
    db_name varchar(90) DEFAULT NULL,
    expiry int(11) ,
    asked  tinyint(4) unsigned DEFAULT 0,
    privilege int(11) 
  ); 

  IF _permission IS NULL OR _permission='' THEN 
    SET _permission = 0;
  END IF;

  WHILE _i < JSON_LENGTH(_nodes) DO 
    SELECT get_json_array(_nodes, _i) INTO @_node;
    SELECT JSON_VALUE(@_node, "$.nid") INTO _rid;
    
    
    SELECT id, db_name, area, concat(home_dir, "__storage__/")
      FROM yp.entity WHERE 
      
      id = JSON_VALUE(@_node, "$.hub_id")
      INTO _hub_id, _src_db_name, _area, _mfs_root; 
    
    
    
    

    IF _src_db_name IS NOT NULL THEN 
      SET @s = CONCAT(
        "SELECT " ,_src_db_name,".user_permission (?, ?) INTO @resperm");
      PREPARE stmt FROM @s;
      EXECUTE stmt USING _uid, _rid;
      DEALLOCATE PREPARE stmt; 

      SET @s = CONCAT(
        "SELECT " ,_src_db_name,".user_expiry (?, ?) INTO @resexpiry");
      PREPARE stmt FROM @s;
      EXECUTE stmt USING _uid, _rid;
      DEALLOCATE PREPARE stmt;
      SELECT IF(_area='public', GREATEST(3, @resperm), IFNULL(@resperm, 1)) INTO @resperm;

      INSERT INTO __tmp_ids SELECT 
        _rid, _hub_id, _src_db_name, @resexpiry, _permission, CAST(@resperm AS UNSIGNED); 
    END IF;

    SELECT _i + 1 INTO _i;
  END WHILE;
  
  SELECT * FROM  __tmp_ids WHERE 
    (expiry = 0 OR expiry > UNIX_TIMESTAMP());

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `acl_check_next` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `acl_check_next`(
  IN _key VARCHAR(16),
  IN _permission TINYINT(4),
  IN _nodes JSON
)
BEGIN

  DECLARE _uid VARCHAR(16);
  DECLARE _owner_id VARCHAR(16);
  DECLARE _area VARCHAR(16);
  DECLARE _src_db_name VARCHAR(255);
  DECLARE _mfs_root VARCHAR(512);

  DECLARE _rid VARCHAR(16);
  DECLARE _i INT(4) DEFAULT 0;

  SELECT id FROM yp.entity WHERE id=_key or ident=_key INTO _uid;

  DROP TABLE IF EXISTS __tmp_ids;
  CREATE TEMPORARY TABLE __tmp_ids(
    `id` varchar(16) DEFAULT NULL,
    db_name varchar(90) DEFAULT NULL,
    expiry tinyint(4) unsigned,
    asked  tinyint(4) unsigned,
    privilege int(11) 
  ); 

  WHILE _i < JSON_LENGTH(_nodes) DO 
    SELECT JSON_UNQUOTE(JSON_EXTRACT(_nodes, CONCAT("$[", _i, "]"))) INTO @_node;
    SELECT JSON_UNQUOTE(JSON_EXTRACT(@_node, "$.nid")) INTO _rid;
    SELECT db_name, area, owner_id, concat(home_dir, "__storage__/")
      FROM yp.entity LEFT JOIN yp.hub USING(id) WHERE 
      
      id = yp.hub_id(JSON_UNQUOTE(JSON_EXTRACT(@_node, "$.hub_id")))
      INTO _src_db_name, _area, _owner_id, _mfs_root; 
    
    IF _src_db_name IS NOT NULL THEN 
      SET @s = CONCAT(
        "SELECT " ,_src_db_name,".user_permission (", QUOTE(_uid),",",QUOTE(_rid), ") INTO @resperm");
      PREPARE stmt FROM @s;
      EXECUTE stmt;
      DEALLOCATE PREPARE stmt; 

      SET @s = CONCAT(
        "SELECT " ,_src_db_name,".user_expiry (", QUOTE(_uid),",",QUOTE(_rid), ") INTO @resexpiry");
      PREPARE stmt FROM @s;
      EXECUTE stmt;
      DEALLOCATE PREPARE stmt;
      SELECT IF(_area='public', GREATEST(7, @resperm), @resperm) INTO @resperm;
      INSERT INTO __tmp_ids SELECT 
        _rid, _src_db_name, @resexpiry, _permission, CAST(@resperm AS UNSIGNED); 
    END IF;

    SELECT _i + 1 INTO _i;
  END WHILE;
  
  SELECT * FROM  __tmp_ids WHERE 
    (expiry = 0 OR expiry > UNIX_TIMESTAMP());

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `acl_revoke` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `acl_revoke`(
  IN _rid VARCHAR(16),
  IN _eid VARCHAR(16)
)
BEGIN

  IF _eid != '' THEN
    DELETE FROM acl WHERE resource_id=_rid AND entity_id=_eid;
  ELSE
    DELETE FROM acl WHERE resource_id=_rid;
  END IF;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `acl_show_users` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `acl_show_users`(
  IN _resouce_id VARCHAR(16)
)
BEGIN
  DECLARE _node_permission VARCHAR(16);
  DECLARE _level VARCHAR(16);

  SELECT permission_tree(_resouce_id) INTO _node_permission;
  SELECT 
    CASE 
      WHEN _node_permission = '*' THEN 'hub'
      WHEN _node_permission = _resouce_id THEN 'node'
      ELSE 'parent'
    END
  INTO _level;

  SELECT 
    entity_id AS uid, 
    firstname,
    lastname,
    _level AS level,
    IF(expiry_time > 0, expiry_time - UNIX_TIMESTAMP(), 0) AS ttl,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.email')), '')) AS email,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.avatar')), 'default')) AS avatar,
    permission AS privilege
  FROM permission INNER JOIN (yp.drumate) ON drumate.id=entity_id 
  WHERE resource_id = _node_permission

  UNION

  SELECT 
    entity_id AS uid, 
    firstname,
    lastname,
    'hub' AS level,
    IF(expiry_time > 0, expiry_time - UNIX_TIMESTAMP(), 0) AS ttl,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.email')), '')) AS email,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.avatar')), 'default')) AS avatar,
    permission AS privilege
  FROM permission INNER JOIN (yp.drumate) ON drumate.id=entity_id 
  WHERE resource_id = '*';

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `add_huber` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `add_huber`(
  IN _key  VARCHAR(80),
  IN _privilege INT(8),
  IN _expiry_time INT(11)
)
BEGIN
  DECLARE _db VARCHAR(30);
  DECLARE _hid VARCHAR(16);
  DECLARE _uid VARCHAR(16);
  DECLARE _ts INT(11) DEFAULT 0;
  SELECT UNIX_TIMESTAMP() INTO _ts;
  SELECT id FROM yp.entity WHERE db_name=database() INTO _hid;
  SELECT id FROM yp.drumate WHERE email=_key INTO _uid;
  SELECT db_name, id FROM yp.entity WHERE id=_key OR
    (IFNULL(_uid, '') <> "" AND id = _uid) INTO _db, _uid;

  IF (IFNULL(_uid, '') = "") THEN
    SELECT 1 AS non_drumate;
  ELSE
    INSERT into huber values(null, _uid, _privilege, IF(IFNULL(_expiry_time, 0) = 0, 0,
      UNIX_TIMESTAMP(TIMESTAMPADD(HOUR,_expiry_time, FROM_UNIXTIME(_ts)))), _ts, _ts)
      ON DUPLICATE KEY UPDATE privilege=_privilege,
      expiry_time = IF(IFNULL(_expiry_time, 0) = 0, 0,
      UNIX_TIMESTAMP(TIMESTAMPADD(HOUR,_expiry_time, FROM_UNIXTIME(_ts)))),
      utime = _ts;

    SET @s = CONCAT("CALL `", _db, "`.join_hub(", quote(_hid), ");");
    

    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    SELECT
      0 AS non_drumate,
      entity.id,
      entity.ident,
      entity.area_id,
      entity.area,
      entity.vhost,
      drumate.dmail,
      drumate.email,
      drumate.firstname,
      drumate.lastname,
      drumate.remit,
      drumate.fullname,
      privilege
    FROM yp.entity INNER JOIN (yp.drumate, huber) ON (drumate.id=entity.id AND huber.id=entity.id)
    WHERE entity.id=_uid;
  END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `add_member` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `add_member`(
  IN _member_id  VARCHAR(512),
  IN _privilege TINYINT(2),
  IN _expiry_time INT(11)
)
BEGIN
  DECLARE _member_db VARCHAR(30);
  DECLARE _hub_db VARCHAR(30);
  DECLARE _area VARCHAR(30);
  DECLARE _hid VARCHAR(16);
  DECLARE _uid VARCHAR(16);
  DECLARE _guest_id VARCHAR(16);
  DECLARE _ts INT(11) DEFAULT 0;
  DECLARE _tx INT(11) DEFAULT 0;
  DECLARE _ui_privilege TINYINT(4);

  SELECT UNIX_TIMESTAMP() INTO _ts;
  SELECT IF(IFNULL(_expiry_time, 0) = 0, 0,
    UNIX_TIMESTAMP(TIMESTAMPADD(HOUR,_expiry_time, FROM_UNIXTIME(_ts)))) INTO _tx;

  SELECT id, db_name FROM yp.entity WHERE id = _member_id 
    
    INTO _uid, _member_db;

  SELECT id, area FROM yp.entity WHERE db_name = database() INTO _hid, _area;
  SELECT id FROM yp.guest WHERE id = _member_id OR email = _member_id INTO _guest_id;
  
  IF _member_db IS NOT NULL THEN 
    REPLACE INTO permission 
      VALUES(null, '*', _uid, '', _tx, _ts, _ts, _privilege, 'share');

    SET @s = CONCAT("CALL `", _member_db, "`.join_hub(", quote(_hid), ");");
    

    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    SELECT IF(_privilege < 15, 15, _privilege) INTO _ui_privilege;
    SET @s = CONCAT("REPLACE INTO  `", _member_db, "`.permission VALUES(null, ", 
      "'"  , _hid         , "'," ,
      "'"  , _uid         , "'," ,
      "'"  , "---"        , "'," ,
      "'"  , _expiry_time , "'," ,
      "'"  , _ts          , "'," ,
      "'"  , _ts          , "'," ,
      "'"  , _ui_privilege, "'," ,
      "'"  , 'share'      , "')" 
    );
      
    
    
    

    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    SELECT
      entity.id,
      entity.ident,
      entity.area_id,
      entity.area,
      entity.db_name,
      entity.vhost,
      drumate.dmail,
      drumate.email,
      drumate.firstname,
      drumate.lastname,
      drumate.remit,
      CONCAT(firstname, ' ', lastname) as `fullname`,
      permission AS permission
    FROM yp.entity INNER JOIN (yp.drumate, permission) ON (drumate.id=entity.id AND 
    permission.entity_id=entity.id)
    WHERE entity.id=_uid;
  ELSEIF _area = 'restricted' AND _guest_id IS NOT NULL THEN
    REPLACE INTO permission 
      VALUES(null, '*', _guest_id, '', _tx, _ts, _ts, _privilege, 'share');
    SELECT
      guest.id,
      guest.email,
      guest.firstname,
      guest.lastname,
      CONCAT(firstname, ' ', lastname) as `fullname`,
      permission AS permission
    FROM yp.guest INNER JOIN (permission) ON guest.id=entity.id WHERE guest.id=_guest_id;
  ELSE
    SELECT _member_db AS db_name, _area AS area, 0 AS permission ;
  END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `block_add_history` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `block_add_history`(
   IN _id        VARCHAR(512),
   IN _hashtag   VARCHAR(512),
   IN _device    VARCHAR(16),
   IN _lang      VARCHAR(20),
   IN _status    VARCHAR(20),
   IN _isonline  INT(4),
   IN _author_id VARBINARY(16)
)
BEGIN
    DECLARE _ts   INT(11) DEFAULT 0;
    SELECT UNIX_TIMESTAMP() INTO _ts;
    INSERT INTO block_history (`author_id`, `master_id`, `lang`, `device`, `meta`, `status`, `isonline`, `ctime`)
      VALUES(_author_id, _id, _lang, _device, _hashtag, _status, _isonline, _ts);
    SELECT LAST_INSERT_ID() as history_id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `block_copy` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `block_copy`(
   IN _key    VARCHAR(16),
   IN _author  VARCHAR(160)
)
BEGIN
   DECLARE _id VARBINARY(16) DEFAULT '';
   DECLARE _hashtag VARCHAR(512);
   DECLARE _version TINYINT(4);
   DECLARE _tag VARCHAR(512);
   DECLARE _ident VARCHAR(512);

   SELECT id, hashtag FROM block WHERE (id=_key OR hashtag=_key) INTO _id, _hashtag;
   SELECT COUNT(*) FROM block WHERE hashtag LIKE concat(_hashtag, '-v%') INTO _version;
   SET _hashtag = CONCAT(_hashtag, '-v', _version);
   SELECT COUNT(*) FROM block WHERE hashtag = _hashtag INTO _version;
   WHILE _version > 0 DO
      SET _version = _version + 1;
      SET _hashtag = CONCAT(_hashtag, '-v', _version);
      SELECT COUNT(*) FROM block WHERE hashtag = _hashtag INTO _version;
   END WHILE;
   INSERT INTO block
      SELECT null, uniqueId(), serial, active, _author, _hashtag, `type`, editor, status, ctime, mtime, version
      FROM block WHERE id=_id;
   SELECT *, @vhost AS vhost, _id as src_id FROM block WHERE hashtag=_hashtag;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `block_copy_new` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `block_copy_new`(
   IN _history_id     VARCHAR(16),
   IN _author         VARCHAR(160),
   IN _to_lang        VARCHAR(20),
   IN _hashtag        VARCHAR(512),
   IN _new_page       VARCHAR(10)
)
BEGIN
   DECLARE _id VARBINARY(16) DEFAULT '';
   DECLARE _new_id VARBINARY(16) DEFAULT '';
   DECLARE _version TINYINT(4);
   DECLARE _tag VARCHAR(512);
   DECLARE _ident VARCHAR(512);
   DECLARE _lang varchar(10);
   DECLARE _device varchar(100);
   DECLARE _ts INT(11) DEFAULT 0;
   DECLARE _last INT(11) DEFAULT 0;
   DECLARE _block_exist INT(4) DEFAULT 0;

   SELECT UNIX_TIMESTAMP() INTO _ts;

   START TRANSACTION;
   SELECT master_id, lang, device FROM block_history WHERE serial = _history_id INTO _id, _lang, _device;
   
   SELECT EXISTS (SELECT serial FROM block_history WHERE master_id = _id AND lang = _to_lang AND device = _device) INTO _block_exist;
   IF _lang <> _to_lang AND _block_exist = 1 AND _new_page = "0" THEN
      SELECT 1 AS confirm_copy;
   ELSE
      IF _lang = _to_lang OR (_block_exist = 1 AND _lang <> _to_lang AND _new_page = "1") THEN
        SELECT UNIQUEID() INTO _new_id;
        IF IFNULL(_hashtag, '') = "" THEN
          SELECT hashtag FROM block WHERE id = _id INTO _hashtag;
          
          
          
          
          
          
          
          
          SELECT IFNULL(MAX(SUBSTRING_INDEX(hashtag, '-v', -1)),-1) as d FROM block
            WHERE hashtag REGEXP CONCAT(_hashtag, '-v[0-9]*$') INTO _version;
          SET _hashtag = CONCAT(_hashtag, '-v', _version + 1);

        END IF;
      ELSE
          SELECT _id INTO _new_id;
      END IF;

      UPDATE block_history SET status = 'history' WHERE master_id = _new_id AND lang = _to_lang AND device = _device;
      INSERT INTO block_history (`author_id`, `master_id`, `lang`, `device`, `status`, `isonline`, `meta`, `ctime`)
          VALUES(_author, _new_id, _to_lang, _device, 'draft', 0, _hashtag, _ts);
      SELECT LAST_INSERT_ID() INTO _last;

      IF _lang = _to_lang OR (_block_exist = 1 AND _lang <> _to_lang AND _new_page = "1") THEN
          INSERT INTO block (sys_id, id, serial, active, author_id, hashtag, `type`, editor, status, ctime, mtime, version)
              SELECT null, _new_id, _last, _last, _author, _hashtag, `type`, editor, status, _ts, _ts, version
              FROM block WHERE id=_id;
      END IF;
      COMMIT;
      SELECT *, _hashtag AS hashtag, @vhost AS vhost, _id as src_id, 0 AS confirm_copy FROM block_history WHERE serial=_last;
   END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `block_delete_by_id_lang` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `block_delete_by_id_lang`(
   IN _id           VARCHAR(512),
   IN _locale       VARCHAR(100),
   IN _device       VARCHAR(16)
)
BEGIN
  
  DECLARE _eid VARCHAR (16);

  DELETE FROM block_history WHERE master_id = _id AND lang = _locale AND device = _device;
  DELETE block FROM block WHERE id = _id AND id NOT IN (SELECT master_id
    FROM block_history WHERE master_id = _id);
  
  SELECT id FROM yp.entity WHERE db_name = DATABASE() INTO _eid;
  


END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `block_delete_by_lang` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `block_delete_by_lang`(
   IN _locale       VARCHAR(100)
)
BEGIN
  DELETE FROM block_history WHERE lang=_locale;
  DELETE block FROM block WHERE id NOT IN (SELECT master_id FROM block_history);
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `block_exists` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `block_exists`(
  IN _hashtag        VARCHAR(512)
)
BEGIN
  SELECT id FROM block WHERE hashtag = _hashtag;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `block_get` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `block_get`(
   IN _tag VARCHAR(512),
   IN _device  VARCHAR(16),
   IN _lang  VARCHAR(16)
)
BEGIN
   DECLARE _existence INT(4);
   SELECT EXISTS (
    SELECT master_id FROM block LEFT JOIN block_history 
      ON master_id = block.id 
      WHERE block.id=_tag OR hashtag=_tag
      AND lang = _lang AND device = _device
   ) INTO _existence;
          
  IF _existence THEN
   SELECT 
    block.id, 
    active, 
    hashtag, 
    `type`, 
    editor, 
    block.status, 
    firstname, 
    lastname,
    ctime, 
    mtime, 
    version
      FROM block LEFT JOIN yp.drumate ON block.author_id=drumate.id
      WHERE (block.id=_tag OR hashtag=_tag);
      
      
      
      
  ELSE
    SELECT id, status FROM block WHERE id=_tag OR hashtag=_tag;
  END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `block_get_base_by_lang` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `block_get_base_by_lang`(
   IN _base_lang       VARCHAR(100)
)
BEGIN
  SELECT serial AS history_id, master_id AS block_id, lang, device, status, isonline, meta
    FROM block_history WHERE (lang = _base_lang AND isonline=1)
    OR (lang = _base_lang AND status='draft' AND isonline=0);
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `block_get_by_id` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `block_get_by_id`(
   IN _key VARCHAR(512)
)
BEGIN
  SELECT block.id, active, hashtag, `type`, editor, status, firstname, lastname ctime, mtime, version
    FROM block LEFT JOIN yp.drumate ON author_id=drumate.id WHERE block.id = _key OR hashtag= _key;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `block_get_by_type` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `block_get_by_type`(
   IN _tag VARCHAR(512),
   IN _device  VARCHAR(16),
   IN _lang  VARCHAR(16),
   IN _type  VARCHAR(16)

)
BEGIN
   SELECT block.id, active, hashtag, `type`, editor, status, firstname, lastname ctime, mtime, version
         FROM block LEFT JOIN yp.drumate ON author_id=drumate.id WHERE `type`=_type;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `block_get_draft_publish` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `block_get_draft_publish`(
   IN _locale       VARCHAR(100),
   IN _published    INT(4),
   IN _hashtag      VARCHAR(500),
   IN _sort_by      VARCHAR(100),
   IN _sort         VARCHAR(100),
   IN _page         INT(11)
)
BEGIN
  DECLARE _range int(6);
  DECLARE _offset int(6);
  CALL pageToLimits(_page, _offset, _range);
  SELECT bh.serial AS history_id, id AS block_id, lang, device, bh.status,
    isonline, hashtag  FROM block b INNER JOIN block_history bh ON b.id = bh.master_id
    WHERE lang = _locale AND hashtag LIKE CONCAT('%', TRIM(IFNULL(_hashtag,'')), '%')
    AND CASE WHEN _published = 1 OR _published = 2 THEN 
      CASE WHEN _published = 2 THEN (bh.status = 'draft' OR isonline=1)
      ELSE isonline = 1 END
    ELSE bh.status = 'draft' END
    ORDER BY
    CASE WHEN LCASE(_sort_by) = 'date' and LCASE(_sort) = 'asc' THEN b.mtime END ASC,
    CASE WHEN LCASE(_sort_by) = 'date' and LCASE(_sort) = 'desc' THEN b.mtime END DESC,
    CASE WHEN LCASE(_sort) = 'desc' THEN hashtag END DESC,
    CASE WHEN LCASE(_sort) <> 'desc' THEN hashtag END ASC
    LIMIT _offset, _range;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `block_get_thread` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `block_get_thread`(
  IN _key VARCHAR(500),
  IN _criteria VARCHAR(16),
  IN _page TINYINT(4)
)
BEGIN
  DECLARE _range int(6);
  DECLARE _offset int(6);
  DECLARE _head int(6);
  DECLARE _hashtag VARCHAR(500);
  DECLARE _id VARBINARY(16);
  DECLARE _status VARCHAR(16);

  CALL pageToLimits(_page, _offset, _range);

  SELECT id, status, active, hashtag FROM block WHERE id=_key OR hashtag=_key
     INTO _id, _status, _head, _hashtag;

  IF _criteria LIKE "D%" THEN
    SELECT serial, author_id, master_id, lang, device, _hashtag as hashtag,
          master_id as id, firstname, lastname, ctime, _head as head
    FROM block_history LEFT JOIN yp.drumate on author_id=drumate.id
      WHERE master_id=_id ORDER BY ctime DESC LIMIT _offset, _range;
  ELSE
    SELECT serial, author_id, master_id, lang, device, _hashtag as hashtag,
          master_id as id, firstname, lastname, ctime, _head as head
    FROM block_history LEFT JOIN yp.drumate on author_id=drumate.id
      WHERE master_id=_id ORDER BY ctime ASC LIMIT _offset, _range;
  END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `block_get_used_languages` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `block_get_used_languages`(
  IN _hashtag  varchar(256)
)
BEGIN
  SELECT lang FROM block LEFT JOIN block_history ON block.id=master_id 
  WHERE hashtag=_hashtag or master_id=_hashtag GROUP BY lang;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `block_history_check_published` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `block_history_check_published`(
   IN _id           VARCHAR(512),
   IN _locale       VARCHAR(100),
   IN _device       VARCHAR(16)
)
BEGIN
  SELECT EXISTS (SELECT serial FROM block_history WHERE master_id = _id AND isonline = 1
    AND lang = _locale AND device = _device) AS IS_PUBLISHED;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `block_history_log` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `block_history_log`(
  IN _tag VARCHAR(400),
  IN _device VARCHAR(16),
  IN _lang VARCHAR(16),
  IN _page TINYINT(4),
  IN _month INT(4),
  IN _year INT(4),
  IN _criteria VARCHAR(16)
)
BEGIN
  DECLARE _range int(6);
  DECLARE _offset int(6);
  DECLARE _active int(8);
  DECLARE _id   VARBINARY(16) DEFAULT '';
  DECLARE _hashtag   varchar(400);

  SELECT id, hashtag, active FROM block WHERE id=_tag OR hashtag=_tag INTO _id, _hashtag, _active;
  CALL pageToLimits(_page, _offset, _range);

  IF _criteria LIKE "D%" THEN
    SELECT _hashtag AS hashtag, author_id, _id AS id,
       serial, ctime, firstname, lastname,lang, device, IF(serial=_active, 1, 0) AS active,
       FROM_UNIXTIME(ctime) AS created_date, status, isonline
       FROM block_history LEFT JOIN (yp.drumate)
       ON author_id=drumate.id
       WHERE master_id=_id AND lang=_lang AND device=_device
       AND CASE WHEN IFNULL(_month,0) <> 0 AND IFNULL(_year,0) <> 0 THEN
       MONTH(FROM_UNIXTIME(ctime)) = _month ELSE true END
       AND CASE WHEN IFNULL(_year,0) <> 0 THEN
       YEAR(FROM_UNIXTIME(ctime)) = _year ELSE true END
       ORDER BY ctime DESC LIMIT _offset, _range;
  ELSE
    SELECT _hashtag AS hashtag, author_id, _id AS id,
       serial, ctime, firstname, lastname,lang, device, IF(serial=_active, 1, 0) AS active,
       FROM_UNIXTIME(ctime) AS created_date, status, isonline
       FROM block_history LEFT JOIN (yp.drumate)
       ON author_id=drumate.id
       WHERE master_id=_id AND lang=_lang AND device=_device
       AND CASE WHEN IFNULL(_month,0) <> 0 AND IFNULL(_year,0) <> 0 THEN
       MONTH(FROM_UNIXTIME(ctime)) = _month ELSE true END
       AND CASE WHEN IFNULL(_year,0) <> 0 THEN
       YEAR(FROM_UNIXTIME(ctime)) = _year ELSE true END
       ORDER BY ctime ASC LIMIT _offset, _range;
  END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `block_home` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `block_home`(
)
BEGIN
  DECLARE _languages VARCHAR(512);
  SELECT
    area, concat(TRIM(TRAILING '/' FROM home_dir), '/Block/'), id from yp.entity where db_name=database()
  INTO @area, @root, @entity_id;
  SELECT GROUP_CONCAT(DISTINCT `base` SEPARATOR ':' ) FROM `language` WHERE `state`='active'
    INTO _languages;

  SELECT 
    @area as area, 
    @entity_id as eid, 
    @root AS block_root,
   _languages AS languages;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `block_id_get_by_lang` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `block_id_get_by_lang`(
   IN _locale       VARCHAR(100)
)
BEGIN
  SELECT master_id as block_id FROM block_history WHERE lang=_locale GROUP BY master_id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `block_index` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `block_index`(
   IN _hashtag  varchar(256),
   IN _lang  VARCHAR(6),
   IN _content  MEDIUMTEXT
)
BEGIN
   DECLARE _key  VARCHAR(25);
   SELECT CONCAT(id, '-', _lang) FROM block WHERE hashtag=_hashtag INTO _key;
   REPLACE INTO seo
     (`key`, `hashtag`, `lang`, `content`)
     VALUES(_key, _hashtag, _lang, _content);
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `block_info` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `block_info`(
  IN _hashtag      VARCHAR(500)
)
BEGIN
  SELECT * FROM block WHERE hashtag=_hashtag;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `block_list` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `block_list`(
  IN _page TINYINT(4),
  IN _editor VARCHAR(10),
  IN _criteria VARCHAR(16)
)
BEGIN
  DECLARE _range int(6);
  DECLARE _offset int(6);
  CALL pageToLimits(_page, _offset, _range);

  IF _criteria LIKE "D%" THEN
    SELECT
      block.id, serial, active, hashtag, `type`, `status`, `ctime`, `mtime`, `version`,
      remit, firstname, lastname
    FROM block LEFT JOIN yp.drumate on author_id=drumate.id
      WHERE editor=_editor AND (`type`='page' OR `type`= 'block')
      ORDER BY mtime DESC LIMIT _offset, _range;
  ELSE
    SELECT
      block.id, serial, active, hashtag, `type`, `status`, `ctime`, `mtime`, `version`,
      remit, firstname, lastname
    FROM block LEFT JOIN yp.drumate on author_id=drumate.id
      WHERE editor=_editor AND (`type`='page' OR `type`= 'block')
      ORDER BY mtime ASC LIMIT _offset, _range;
  END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `block_purge` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `block_purge`(
   IN _tag      varchar(400)
)
BEGIN
   DECLARE _id   VARBINARY(16) DEFAULT '';
   DECLARE _hashtag   varchar(400);

   SELECT id, hashtag FROM block WHERE id=_tag OR hashtag=_tag INTO _id, _hashtag;

   DELETE FROM block_history WHERE master_id=_id;
   DELETE FROM block WHERE id=_id;
   SELECT _id as id, _hashtag as hashtag;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `block_remove_item` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `block_remove_item`(
   IN _id      VARBINARY(16)
)
BEGIN
   DELETE FROM block WHERE id=_id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `block_remove_thread` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `block_remove_thread`(
   IN _id      VARBINARY(16)
)
BEGIN
   DELETE FROM block WHERE id=_id;
   DELETE FROM thread WHERE mester_id=_id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `block_rename` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `block_rename`(
   IN _key     VARCHAR(512),
   IN _hashtag VARCHAR(512)
)
BEGIN

   UPDATE block SET hashtag=_hashtag WHERE (id=_key OR hashtag=_key);
   SELECT
     *,
     @vhost AS vhost
   FROM block WHERE hashtag=_hashtag;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `block_rename_new` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `block_rename_new`(
   IN _id             VARCHAR(16),
   IN _hashtag        VARCHAR(512)
)
BEGIN
   DECLARE _hash_exist INT(4) DEFAULT 0;
   DECLARE _eid VARCHAR (16);

   SELECT EXISTS (SELECT id FROM block WHERE id <> _id AND hashtag = _hashtag) INTO _hash_exist;

   IF _hash_exist = 0 THEN
    UPDATE block SET hashtag=_hashtag WHERE id=_id;
    UPDATE block_history SET meta=_hashtag WHERE master_id=_id;
   END IF;
  
  SELECT id FROM yp.entity WHERE db_name = DATABASE() INTO _eid;
  


   SELECT
      *,
      @vhost AS vhost, _hash_exist AS hash_exist
   FROM block WHERE id=_id;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `block_save` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `block_save`(
   IN _inId      VARCHAR(16),
   IN _hashtag   VARCHAR(512),
   IN _editor    VARCHAR(16),
   IN _type      VARCHAR(20),
   IN _device    VARCHAR(16),
   IN _lang      VARCHAR(20),
   IN _author_id VARBINARY(16),
   IN _vesrion   VARCHAR(16)
)
BEGIN
   DECLARE _id   VARBINARY(16) DEFAULT '';
   DECLARE _ts   INT(11) DEFAULT 0;
   DECLARE _last INT(11) DEFAULT 0;

   SELECT UNIX_TIMESTAMP() INTO _ts;

   IF CAST(_inId as CHAR(16))='0' OR _inId='0' THEN
     SELECT yp.uniqueId() INTO _id;
   ELSE
     SELECT _inId INTO _id;
   END IF;

   START TRANSACTION;

   INSERT INTO block_history (`author_id`, `master_id`, `lang`, `device`, `meta`, `ctime`)
         VALUES(_author_id, _id, _lang, _device, _hashtag, _ts);
   SELECT LAST_INSERT_ID() INTO _last;

   INSERT INTO block
     (`id`, `hashtag`, `author_id`, `editor`, `type`, `serial`, `active`, `status`, `ctime`, `mtime`, `version`)
     VALUES(_id, _hashtag, _author_id, _editor, _type, _last, _last, 'offline', _ts, _ts, _vesrion)
     ON DUPLICATE KEY UPDATE serial=_last, active=_last, mtime=_ts;

   COMMIT;

   SELECT _id as id, _last as active, _hashtag as hashtag;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `block_save_int` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `block_save_int`(
   IN _inId      VARCHAR(16),
   IN _hashtag   VARCHAR(512),
   IN _editor    VARCHAR(16),
   IN _type      VARCHAR(20),
   IN _device    VARCHAR(16),
   IN _lang      VARCHAR(20),
   IN _isonline  INT(4),
   IN _author_id VARBINARY(16),
   IN _vesrion   VARCHAR(16)
)
BEGIN
   DECLARE _id   VARBINARY(16) DEFAULT '';
   DECLARE _ts   INT(11) DEFAULT 0;
   DECLARE _last INT(11) DEFAULT 0;
   DECLARE _hash_exist INT(4) DEFAULT 0;
   DECLARE _eid VARCHAR (16);

   SELECT UNIX_TIMESTAMP() INTO _ts;

   IF CAST(_inId as CHAR(16))='0' OR _inId='0' THEN
     SELECT yp.uniqueId() INTO _id;
   ELSE
     SELECT _inId INTO _id;
   END IF;

   SELECT EXISTS (SELECT id FROM block WHERE id <> _id AND hashtag = _hashtag) INTO _hash_exist;
   SELECT IFNULL(max(serial) + 1,1) FROM block_history INTO _last;
   IF _hash_exist = 0 THEN
    START TRANSACTION;

    INSERT INTO block_history (`serial`, `author_id`, `master_id`, `lang`, `device`, `meta`, `ctime`)
        VALUES(_last, _author_id, _id, _lang, _device, _hashtag, _ts);
    

    UPDATE block_history SET status = 'history' WHERE master_id=_id AND lang = _lang;
    UPDATE block_history SET status = 'draft' WHERE master_id=_id AND lang = _lang AND serial=_last;

    IF _isonline = 1 THEN
        UPDATE block_history SET isonline = 0 WHERE master_id=_id AND lang = _lang;
        UPDATE block_history SET isonline = 1 WHERE master_id=_id AND lang = _lang AND serial=_last;
    END IF;
    INSERT INTO block
      (`id`, `hashtag`, `author_id`, `editor`, `type`, `serial`, `active`, `status`, `ctime`, `mtime`, `version`)
      VALUES(_id, _hashtag, _author_id, _editor, _type, _last, _last, 'offline', _ts, _ts, _vesrion)
      ON DUPLICATE KEY UPDATE serial=_last, active=_last, mtime=_ts;
    
    SELECT id FROM yp.entity WHERE db_name = DATABASE() INTO _eid;
    CALL yp.set_default_homepage(_eid);
   
    
    COMMIT;

    SELECT _id as id, _last as active, _hashtag as hashtag, _hash_exist AS hash_exist;
   ELSE
    SELECT _id as id, _hashtag as hashtag, _hash_exist AS hash_exist;
   END IF;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `block_save_int_default_page` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `block_save_int_default_page`(
   IN _inId      VARCHAR(16),
   IN _hashtag   VARCHAR(512),
   IN _editor    VARCHAR(16),
   IN _type      VARCHAR(20),
   IN _device    VARCHAR(16),
   IN _lang      VARCHAR(20),
   IN _isonline  INT(4),
   IN _author_id VARBINARY(16),
   IN _vesrion   VARCHAR(16)
)
BEGIN
  DECLARE _id   VARCHAR(16) DEFAULT '';
  DECLARE _ts   INT(11) DEFAULT 0;
  DECLARE _last INT(11) DEFAULT 0;
  DECLARE _hash_exist INT(4) DEFAULT 0;
  DECLARE _src_path VARCHAR(512);

  SELECT UNIX_TIMESTAMP() INTO _ts;

  CALL yp.default_page(_hashtag, _lang, _src_path);

  IF CAST(_inId as CHAR(16))='0' OR _inId='0' THEN
    SELECT yp.uniqueId() INTO _id;
  ELSE
    SELECT _inId INTO _id;
  END IF;

  
  
  
  

  SELECT active FROM `block` LEFT JOIN block_history ON block_history.`serial` = `block`.`serial`  
  WHERE `hashtag` = _hashtag AND block_history.lang = _lang INTO _last;


  
  IF _last IS NULL THEN
    START TRANSACTION;

    INSERT INTO block_history (`author_id`, `master_id`, `lang`, `device`, `meta`, `ctime`)
        VALUES(_author_id, _id, _lang, _device, _hashtag, _ts);
    

    
    SELECT MAX(`serial`)+1 FROM block_history INTO _last;
    UPDATE block_history SET status = 'history' WHERE master_id=_id AND lang = _lang;
    UPDATE block_history SET status = 'draft' 
      WHERE master_id=_id AND lang = _lang AND serial=_last;

    IF _isonline = 1 THEN
      UPDATE block_history SET isonline = 0 WHERE master_id=_id AND lang = _lang;
      UPDATE block_history SET isonline = 1 WHERE master_id=_id AND lang = _lang AND serial=_last;
    END IF;
    
    
    
    

    REPLACE INTO block
      (`id`, `hashtag`, `author_id`, `editor`, `type`, `serial`, 
      `active`, `status`, `ctime`, `mtime`, `version`)
      VALUES(_id, _hashtag, _author_id, _editor, _type, _last, 
      _last, 'offline', _ts, _ts, _vesrion);

    COMMIT;

    SELECT _id as id, _lang AS lang, _last as active, 
      _hashtag as hashtag, _hash_exist AS hash_exist, _src_path AS src_path;
  ELSE
    SELECT _id as id, _lang AS lang, _hashtag as hashtag, _last AS active,
      _hash_exist AS hash_exist, _src_path AS src_path;
  END IF;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `block_save_menu` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `block_save_menu`(
   IN _device  VARCHAR(16),
   IN _lang  VARCHAR(16)
)
BEGIN
   SELECT block.id, active, hashtag, `type`, editor, status, firstname, lastname ctime, mtime, version
         FROM block LEFT JOIN yp.drumate ON author_id=drumate.id WHERE `type`=_type;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `block_search` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `block_search`(
  IN _pattern VARCHAR(84),
  IN _page TINYINT(4)
)
BEGIN

  DECLARE _range int(6);
  DECLARE _offset int(6);
  CALL pageToLimits(_page, _offset, _range);

  SELECT
    content as text,
    @vhost AS vhost,
    SUBSTRING(`key`, 1, 16) as id,
    hashtag,
    hashtag as `name`,
    MATCH(content) against(_pattern IN NATURAL LANGUAGE MODE WITH QUERY EXPANSION) as s1,
    MATCH(hashtag) against(concat('*', _pattern, '*') IN BOOLEAN MODE) as s2
  FROM seo HAVING s1 > 0 or s2 > 0 ORDER BY s2 DESC, s1 DESC LIMIT _offset, _range;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `block_status` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `block_status`(
   IN _id      VARBINARY(16),
   IN _status  VARCHAR(16)
)
BEGIN
   UPDATE block SET status=_status WHERE id=_id;
   SELECT *, tag as hashtag FROM block WHERE id=_id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `block_store` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `block_store`(
   IN _inId      VARCHAR(16),
   IN _hashtag   VARCHAR(512),
   IN _editor    VARCHAR(16),
   IN _type      VARCHAR(20),
   IN _device    VARCHAR(16),
   IN _lang      VARCHAR(20),
   IN _author_id VARBINARY(16),
   IN _vesrion   VARCHAR(16)
)
BEGIN
   DECLARE _id   VARBINARY(16) DEFAULT '';
   DECLARE _ts   INT(11) DEFAULT 0;
   DECLARE _last INT(11) DEFAULT 0;

   SELECT UNIX_TIMESTAMP() INTO _ts;

   IF CAST(_inId as CHAR(16))='0' OR _inId='0' OR _inId='' THEN
     SELECT yp.uniqueId() INTO _id;
   ELSE
     SELECT _inId INTO _id;
   END IF;

   START TRANSACTION;

   INSERT INTO block_history (`author_id`, `master_id`, `lang`, `device`, `meta`, `ctime`)
         VALUES(_author_id, _id, _lang, _device, _hashtag, _ts);
   SELECT LAST_INSERT_ID() INTO _last;

   REPLACE INTO block
     (`id`, `hashtag`, `author_id`, `editor`, `type`, `serial`, `active`, `status`, `ctime`, `mtime`, `version`)
     VALUES(_id, _hashtag, _author_id, _editor, _type, _last, _last, 'offline', _ts, _ts, _vesrion);
     

   COMMIT;

   SELECT _id as id, _last as active, _hashtag as hashtag;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `block_unpublish` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `block_unpublish`(
   IN _id           VARCHAR(512),
   IN _locale       VARCHAR(100),
   IN _device       VARCHAR(16)
)
BEGIN
   DECLARE _history_id   INT(11) DEFAULT 0;
   DECLARE _ts INT(11) DEFAULT 0;
   SELECT serial INTO _history_id FROM block_history WHERE master_id = _id AND isonline = 1 AND lang = _locale AND device = _device;
   SELECT UNIX_TIMESTAMP() INTO _ts;
   UPDATE block_history SET status = 'history', isonline = 0 WHERE master_id=_id AND lang = _locale AND device = _device;
   UPDATE block_history SET status = 'draft' WHERE serial=_history_id;
   UPDATE block SET serial=_history_id, active=_history_id,mtime=_ts WHERE id=_id;
   SELECT id, active, hashtag, _history_id AS history_id FROM block WHERE id=_id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `block_update` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `block_update`(
   IN _id      VARCHAR(16),
   IN _tag     VARCHAR(512),
   IN _author  VARCHAR(160),
   IN _lang    VARCHAR(20),
   IN _device  VARCHAR(20),
   IN _comment TEXT
)
BEGIN
   DECLARE _mtime INT(11) DEFAULT 0;
   DECLARE _url_key   VARCHAR(1000) DEFAULT '';
   SELECT UNIX_TIMESTAMP() INTO _mtime;
   UPDATE block SET hash=block_ident(_tag, _lang, _device),  tag=_tag,
     author=_author, comment=_comment, mtime=_mtime WHERE id=_id;
   SELECT
     *,
     @vhost AS vhost,
     tag as hashtag
   FROM block WHERE id=_id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `block_update_new` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `block_update_new`(
   IN _id           VARCHAR(512),
   IN _history_id   INT(11),
   IN _lang         VARCHAR(20),
   IN _isonline     INT(4)
)
BEGIN
   DECLARE _ts INT(11) DEFAULT 0;
   SELECT UNIX_TIMESTAMP() INTO _ts;
   UPDATE block_history SET status = 'history' WHERE master_id=_id AND lang = _lang;
   UPDATE block_history SET status = 'draft' WHERE master_id=_id AND lang = _lang AND serial=_history_id;

   IF _isonline = 1 THEN
      UPDATE block_history SET isonline = 0 WHERE master_id=_id AND lang = _lang;
      UPDATE block_history SET isonline = 1 WHERE master_id=_id AND lang = _lang AND serial=_history_id;
   END IF;
   
   UPDATE block SET serial=_history_id, active=_history_id,mtime=_ts WHERE id=_id;
   SELECT id, active, hashtag FROM block WHERE id=_id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `change_history` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `change_history`(
  IN _drumate_id  VARBINARY(16),
  IN _key         VARBINARY(80),
  IN _from        INT(11) UNSIGNED,
  IN _to          INT(11) UNSIGNED,
  IN _page        TINYINT(8)
)
BEGIN
  DECLARE _range int(6);
  DECLARE _offset int(6);
  CALL pageToLimits(_page, _offset, _range);
  set @type = '';
  set @num  = 1;
  SELECT bh.serial AS history_id, master_id AS item_id, drumate.email, lang, device, bh.status,
    isonline, meta AS hashtag, bh.ctime, 'block' AS `type`, remit, firstname, lastname,
    "saved" AS modification, bh.author_id AS `user_id`, CONCAT('v',bh2.version) AS `version`
    FROM block_history bh JOIN block b ON b.id = bh.master_id
    JOIN (SELECT serial, @num := if(@type = master_id, @num + 1, 1) as `version`,
    @type := master_id as page FROM block_history ORDER BY master_id) AS bh2
    ON bh.serial = bh2.serial
    JOIN yp.drumate ON bh.author_id=drumate.id AND drumate.email LIKE CONCAT(IFNULL(_key,""), "%")
    WHERE ((bh.author_id=drumate.id AND IFNULL(_drumate_id,"") = "")
    OR (bh.author_id = _drumate_id AND IFNULL(_drumate_id,"") <> ""))
    AND CASE WHEN _from > 0 THEN bh.ctime >= _from  ELSE true END
    AND CASE WHEN _to > 0 THEN bh.ctime <= _to  ELSE true END
  UNION ALL
  SELECT m.sys_id AS history_id, m.id AS item_id, drumate.email, '', '', '', 0, user_filename AS hashtag,
    upload_time AS ctime, m.category AS `type`, remit, firstname, lastname,
    "uploaded" AS modification, origin_id AS `user_id`, "v1" AS `version`
    FROM media m JOIN yp.drumate ON origin_id=drumate.id AND drumate.email LIKE CONCAT(IFNULL(_key,""), "%")
    WHERE ((origin_id=drumate.id AND IFNULL(_drumate_id,"") = "")
    OR (origin_id = _drumate_id AND IFNULL(_drumate_id,"") <> ""))
    AND CASE WHEN _from > 0 THEN upload_time >= _from  ELSE true END
    AND CASE WHEN _to > 0 THEN upload_time <= _to  ELSE true END
  ORDER BY ctime DESC LIMIT _offset, _range;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `change_owner` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `change_owner`(
  IN _uid VARCHAR(16)
)
BEGIN
  DECLARE _db_name VARCHAR(30);
  DECLARE _hub_id VARCHAR(16);
  DECLARE _ts INT(11);
  DECLARE _finished INTEGER DEFAULT 0;

  SELECT UNIX_TIMESTAMP() INTO _ts;
  SELECT id FROM yp.entity WHERE db_name=DATABASE() INTO _hub_id;

  DROP TABLE IF EXISTS  _mid_tmp;  
  CREATE TEMPORARY TABLE `_mid_tmp` (db_name   VARCHAR(50));
  INSERT INTO _mid_tmp SELECT db_name FROM permission 
    LEFT JOIN yp.entity e ON entity_id=e.id WHERE permission&32>0 AND resource_id='*';

  BEGIN 
    DECLARE dbcursor CURSOR FOR SELECT db_name FROM _mid_tmp;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET _finished = 1;
    OPEN dbcursor;
    WHILE NOT _finished DO 
      FETCH dbcursor INTO _db_name;
      SET @s = CONCAT(
        "UPDATE `" ,_db_name,"`.permission SET permission=31, ", 
        "utime = UNIX_TIMESTAMP() WHERE resource_id=", QUOTE(_hub_id));
      
      PREPARE stmt FROM @s;
      EXECUTE stmt;
      DEALLOCATE PREPARE stmt;
    END WHILE;
  END;

  
  UPDATE permission SET permission=31, utime = UNIX_TIMESTAMP()
    WHERE permission&32>0 AND resource_id='*';

  
  REPLACE INTO permission VALUES(NULL, '*', _uid, '', 0, _ts, _ts, 63, 'share');

  SELECT db_name FROM yp.entity WHERE id=_uid INTO _db_name;
  SET @s = CONCAT(
    "UPDATE `" ,_db_name,"`.permission SET permission=63, ", 
    "utime = UNIX_TIMESTAMP() WHERE resource_id=", QUOTE(_hub_id));
  
  PREPARE stmt FROM @s;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;

  
  UPDATE yp.hub SET owner_id=_uid WHERE id=_hub_id;

  SELECT 
    entity_id AS uid, 
    firstname,
    lastname,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.email')), '')) AS email,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.avatar')), 'default')) AS avatar,
    permission AS privilege
  FROM permission INNER JOIN (yp.drumate) ON drumate.id=entity_id 
  WHERE entity_id = _uid;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `channel_clear_notifications` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `channel_clear_notifications`(
  IN _uid VARCHAR(16)
)
BEGIN
  UPDATE channel SET 
    metadata=JSON_SET(metadata, CONCAT("$._seen_.", _uid), UNIX_TIMESTAMP()) WHERE 
    JSON_EXISTS(metadata, "$._seen_") AND 
    NOT JSON_EXISTS(metadata, CONCAT("$._seen_.", _uid));
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `channel_delete` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `channel_delete`(
  IN _uid VARCHAR(16),
  IN _option VARCHAR(16),
  IN _messages JSON
)
BEGIN
  DECLARE _message_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _hub_id  VARCHAR(16) CHARACTER SET ascii;
  DECLARE _drumate_hub_id  VARCHAR(16) CHARACTER SET ascii;
  DECLARE _drumate_id  VARCHAR(16) CHARACTER SET ascii;
  DECLARE _nid  VARCHAR(16) CHARACTER SET ascii;
  DECLARE _node json;
  DECLARE _attachment  JSON;
  DECLARE _cnt INT(6) DEFAULT 0;
  DECLARE _idx_node INT(4) DEFAULT 0; 
  DECLARE _idx_attachment INT(4) DEFAULT 0; 
  DECLARE _sbx_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _sbx_db_name VARCHAR(255);
  DECLARE _type VARCHAR(16);
  DECLARE _entity_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _entity_db VARCHAR(255);  
  DECLARE _delete_nid VARCHAR(16) CHARACTER SET ascii;
  DECLARE _delete_attachment  JSON;
  DECLARE _ref_sys_id INT;
  DECLARE _read_cnt INT ;
  DECLARE _read_sys_id BIGINT default 0;  

    SELECT id, type FROM yp.entity WHERE db_name=DATABASE() INTO _hub_id,_type;

    DROP TABLE IF EXISTS _show_node;
    CREATE TEMPORARY TABLE _show_node AS SELECT * FROM channel WHERE 1=2;
    ALTER TABLE _show_node ADD `delete_attachment` JSON;

    DROP TABLE IF EXISTS _list_uid;

    CREATE TEMPORARY TABLE _list_uid (
      id VARCHAR(16) CHARACTER SET ascii , 
      hub_id VARCHAR(16) CHARACTER SET ascii
      );

    ALTER TABLE _list_uid ADD `is_checked` boolean default 0 ;
    INSERT INTO _list_uid (id,hub_id) SELECT _uid,_hub_id;

    IF _type <> 'hub' THEN
      SELECT get_json_array(_messages, 0) INTO _message_id;
      SELECT entity_id FROM channel WHERE 
      message_id = _message_id INTO _entity_id;
    END IF;
   
    
    IF _type = 'hub' AND _option = 'all'  THEN
      INSERT INTO _list_uid (id, hub_id) SELECT  d.id, _hub_id FROM .permission p 
      INNER JOIN yp.drumate d on p.entity_id=d.id 
      WHERE p.resource_id='*' AND  d.id <> _uid;
    END IF;
    
    IF _type <> 'hub' AND _option = 'all'  THEN
      SELECT db_name FROM yp.entity WHERE id = _entity_id INTO _entity_db; 
      INSERT INTO _list_uid (id,hub_id) SELECT _entity_id,_entity_id;
    END IF; 



    WHILE _idx_node < JSON_LENGTH(_messages) DO 
      SELECT get_json_array(_messages, _idx_node) INTO _message_id;
    
      INSERT INTO _show_node SELECT  *, NULL FROM channel WHERE message_id = _message_id;
      SELECT attachment,sys_id FROM channel WHERE message_id = _message_id INTO _attachment,_ref_sys_id;
      
      
      
     
      
      
      
      

      
        
      
      
            
      
      
      
      
   
      
            
      
      
    
      

      
      
     
      
      
 
      IF _entity_db IS NOT NULL THEN

        SET @st = CONCAT('
        DELETE FROM ', _entity_db ,'.time_channel WHERE entity_id = ?');
        PREPARE stamt FROM @st;
        EXECUTE stamt USING  _uid;
        DEALLOCATE PREPARE stamt;


        SET @st = CONCAT('
        INSERT INTO ', _entity_db ,'.time_channel(entity_id, ref_sys_id,message,ctime)
        SELECT c.entity_id, c.sys_id,c.message, c.ctime FROM ', _entity_db ,'.channel c
        WHERE c.entity_id = ( SELECT  entity_id FROM ', _entity_db ,'.channel WHERE message_id = ?)  
        AND message_id <> ?
        ORDER BY c.sys_id DESC LIMIT 1
        ON DUPLICATE KEY UPDATE ref_sys_id= c.sys_id, ctime =c.ctime ,message=c.message');
        PREPARE stamt FROM @st;
        EXECUTE stamt USING _message_id,_message_id ;
        DEALLOCATE PREPARE stamt;


        SET @st = CONCAT('DELETE FROM ', _entity_db ,'.channel WHERE message_id= ?');
        PREPARE stamt FROM @st;
        EXECUTE stamt USING _message_id ;
        DEALLOCATE PREPARE stamt;
      END IF;

      IF _type <> 'hub' THEN
        DELETE FROM time_channel WHERE entity_id = _entity_id;
        INSERT INTO time_channel(entity_id, ref_sys_id,message,ctime)
        SELECT c.entity_id, c.sys_id,c.message, c.ctime FROM channel c
        WHERE c.entity_id = ( SELECT  entity_id FROM channel WHERE message_id = _message_id)  
        AND message_id <> _message_id
        ORDER BY c.sys_id DESC LIMIT 1
        ON DUPLICATE KEY UPDATE ref_sys_id= c.sys_id, ctime =c.ctime ,message=c.message;
        DELETE FROM channel WHERE message_id = _message_id;

      END IF;

      IF _type = 'hub' THEN
        INSERT INTO  delete_channel (uid,ref_sys_id,ctime)  
        SELECT id ,_ref_sys_id,UNIX_TIMESTAMP()  FROM _list_uid  ON DUPLICATE KEY UPDATE  ctime =UNIX_TIMESTAMP();
        SELECT 0 INTO _cnt;
        SELECT count(id)
        FROM permission p 
        INNER JOIN yp.drumate d ON  p.entity_id=d.id 
        WHERE p.resource_id='*'
        AND NOT EXISTS( SELECT 1 FROM delete_channel WHERE uid = d.id AND ref_sys_id = _ref_sys_id) INTO _cnt;

        DELETE FROM delete_channel WHERE ref_sys_id = _ref_sys_id AND  _cnt= 0 ; 
        DELETE FROM channel WHERE message_id = _message_id AND  _cnt= 0; 

      END IF;

      SELECT _idx_node + 1 INTO _idx_node;
    END WHILE;

    

    DROP TABLE IF EXISTS `_last_node`;
    CREATE TEMPORARY TABLE `_last_node` (
      `uid` VARCHAR(16) CHARACTER SET ascii NOT NULL,  
      `entity_id` VARCHAR(16) CHARACTER SET ascii NOT NULL,
      `message`     VARCHAR(100) ,
      `attachment`  longtext,  
      `room_count` INT DEFAULT 0,
      `ctime` int(11)  NULL,
      UNIQUE KEY `id` (`uid`)
    ) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 ;

    IF _type = 'hub' THEN
      SELECT id , hub_id FROM _list_uid WHERE is_checked =0  LIMIT 1 INTO _drumate_id , _drumate_hub_id;
        WHILE _drumate_id IS NOT NULL DO
      
          SELECT NULL INTO _ref_sys_id; 
          SELECT 0 INTO _read_cnt;
          SELECT NULL INTO _read_sys_id;

          SELECT max(sys_id) 
          FROM  channel c 
          LEFT JOIN delete_channel dc  
              ON dc.ref_sys_id = sys_id AND uid = _drumate_id
          WHERE  ref_sys_id IS NULL INTO _ref_sys_id;

          SELECT  ref_sys_id FROM read_channel WHERE uid = _drumate_id INTO _read_sys_id; 

          SELECT 
            COUNT(sys_id)
          FROM 
            channel c  WHERE  c.sys_id > _read_sys_id INTO _read_cnt ;

          INSERT INTO _last_node
          SELECT _drumate_id, _drumate_hub_id, LEFT(message, 100)  , attachment ,_read_cnt, ctime FROM channel  WHERE sys_id = _ref_sys_id ;

          INSERT INTO _last_node
          SELECT _drumate_id, _drumate_hub_id, NULL , NULL ,_read_cnt, NULL  WHERE  _ref_sys_id IS NULL;

          UPDATE _list_uid SET is_checked = 1 WHERE id = _drumate_id ;
          SELECT NULL,NULL INTO _drumate_id,_drumate_hub_id;
          SELECT id , hub_id FROM _list_uid WHERE is_checked =0  LIMIT 1 INTO _drumate_id , _drumate_hub_id;
        END WHILE;
    END IF;

    IF _type <> 'hub' THEN

     SELECT NULL INTO _ref_sys_id; 
     SELECT ref_sys_id FROM  time_channel WHERE  entity_id = _entity_id INTO  _ref_sys_id;
     INSERT INTO _last_node
     SELECT _uid, _entity_id, LEFT(message, 100)  , attachment ,0, ctime FROM channel  WHERE sys_id = _ref_sys_id ;

     INSERT INTO _last_node
     SELECT _uid, _entity_id, NULL , NULL ,0, NULL  WHERE  _ref_sys_id IS NULL;


    END IF;

    IF _entity_db IS NOT NULL THEN

      SELECT NULL INTO @ref_sys_id;

      SET @s = CONCAT(" SELECT ref_sys_id  FROM ",_entity_db , ".time_channel WHERE entity_id =? INTO @ref_sys_id");
      PREPARE stmt FROM @s;
      EXECUTE stmt USING _uid;
      DEALLOCATE PREPARE stmt;


      SET @s = CONCAT(" SELECT ref_sys_id  FROM ",_entity_db , ".read_channel WHERE  entity_id =? AND uid =? INTO @read_sys_id");
      PREPARE stmt FROM @s;
      EXECUTE stmt USING _uid , _entity_id;
      DEALLOCATE PREPARE stmt;


      SELECT 0 INTO @room_count ;
      SET @s = CONCAT(" SELECT  COUNT(sys_id)  FROM ",_entity_db , ".channel c WHERE c.entity_id = ? AND  c.sys_id > ? INTO @room_count");
      PREPARE stmt FROM @s;
      EXECUTE stmt USING _uid, @read_sys_id; 
      DEALLOCATE PREPARE stmt;

      INSERT INTO _last_node
      SELECT _entity_id,_uid, NULL , NULL ,@room_count , NULL  WHERE  @ref_sys_id IS NULL;

      SET @s = CONCAT(" INSERT INTO _last_node  
      SELECT ?,?, LEFT(message, 100)  , attachment ,?, ctime  FROM ",_entity_db , ".channel WHERE sys_id =? ");
      PREPARE stmt FROM @s;
      EXECUTE stmt USING _entity_id,_uid,@room_count, @ref_sys_id;
      DEALLOCATE PREPARE stmt;

    END IF;
    
    SELECT * FROM _show_node;
    SELECT * FROM _last_node;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `channel_delete_hub_all` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `channel_delete_hub_all`(
  IN _uid VARCHAR(16) CHARACTER SET ascii,
  IN _option VARCHAR(16),
  IN _messages JSON
)
BEGIN

  DECLARE _hub_id  VARCHAR(16) CHARACTER SET ascii;
  DECLARE _memeber_cnt INT ;

  DECLARE _message_id VARCHAR(16) CHARACTER SET ascii; 
  DECLARE _ref_sys_id BIGINT default 0;
  DECLARE _attachment  JSON;
  DECLARE _idx_node INT(4) DEFAULT 0;
  DECLARE _cnt INT ;
  DECLARE _idx_attachment INT(4) DEFAULT 0;
  DECLARE _node json;
  DECLARE _nid  VARCHAR(16) CHARACTER SET ascii;

  DECLARE _drumate_hub_id  VARCHAR(16) CHARACTER SET ascii;
  DECLARE _drumate_id  VARCHAR(16) CHARACTER SET ascii;

  DECLARE _max_sys_id BIGINT;
  DECLARE _max_ref_sys_id BIGINT;
  DECLARE _read_cnt INT ;
  DECLARE _read_sys_id BIGINT default 0;

  SELECT id FROM yp.entity WHERE db_name=DATABASE() INTO _hub_id;
  DROP TABLE IF EXISTS _show_node;
  CREATE TEMPORARY TABLE _show_node AS SELECT * FROM channel WHERE 1=2;
  ALTER TABLE _show_node ADD `delete_attachment` JSON;
  
  DROP TABLE IF EXISTS _list_uid;
  CREATE TEMPORARY TABLE _list_uid (
    id VARCHAR(16) CHARACTER SET ascii , 
    hub_id VARCHAR(16) CHARACTER SET ascii,
    `is_checked` boolean default 0 
  );

  INSERT INTO _list_uid (id) 
  SELECT  d.id
  FROM permission p 
  INNER JOIN yp.drumate d ON  p.entity_id=d.id 
  WHERE p.resource_id='*' ;

  SELECT count(id)
  FROM _list_uid p 
  INTO _memeber_cnt;

  WHILE _idx_node < JSON_LENGTH(_messages) DO 
    SELECT get_json_array(_messages, _idx_node) INTO _message_id;
    INSERT INTO _show_node SELECT  *, NULL FROM channel WHERE message_id = _message_id;
    SELECT attachment,sys_id FROM channel WHERE message_id = _message_id INTO _attachment,_ref_sys_id;
   
    INSERT INTO  delete_channel (uid,ref_sys_id,ctime)  
    SELECT id ,_ref_sys_id,UNIX_TIMESTAMP()  FROM _list_uid  ON DUPLICATE KEY UPDATE  ctime =UNIX_TIMESTAMP();
    SELECT 0 INTO _cnt;

    SELECT COUNT(1) FROM delete_channel WHERE ref_sys_id = _ref_sys_id INTO _cnt;
    DELETE FROM delete_channel WHERE ref_sys_id = _ref_sys_id AND  _cnt= _memeber_cnt ; 
    DELETE FROM channel WHERE message_id = _message_id AND  _cnt= _memeber_cnt; 


    IF _cnt = _memeber_cnt THEN 

      WHILE _idx_attachment < JSON_LENGTH(_attachment) DO 
        SELECT JSON_QUERY(_attachment, CONCAT("$[", _idx_attachment, "]") ) INTO _node;
        SELECT JSON_VALUE(_node, '$.hub_id') INTO _hub_id;
        SELECT JSON_VALUE(_node, '$.nid') INTO _nid;
        SELECT _idx_attachment + 1 INTO _idx_attachment;

        UPDATE yp.disk_usage SET size = IFNULL(size,0) - 
        (SELECT IFNULL(SUM(filesize),0) FROM  media  WHERE id  =_nid ) 
        WHERE hub_id =_hub_id;
        DELETE FROM  media WHERE id = _nid;
      END WHILE;

      UPDATE _show_node SET delete_attachment = _attachment WHERE message_id = _message_id; 

    END IF;

    SELECT _idx_node + 1 INTO _idx_node;
  END WHILE;

  DROP TABLE IF EXISTS `_last_node`;
  CREATE TEMPORARY TABLE `_last_node` (
      `uid` VARCHAR(16) CHARACTER SET ascii NOT NULL,  
      `entity_id` VARCHAR(16) CHARACTER SET ascii NOT NULL,
      `message`     VARCHAR(100) ,
      `attachment`  longtext,  
      `room_count` INT DEFAULT 0,
      `ctime` int(11)  NULL,
      UNIQUE KEY `id` (`uid`)
  ) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 ;

  SELECT  max(sys_id)  FROM  channel c  INTO _max_sys_id; 


  SELECT id  FROM _list_uid WHERE is_checked =0  LIMIT 1 INTO _drumate_id;

    WHILE _drumate_id IS NOT NULL DO

      SELECT NULL INTO _ref_sys_id; 
      SELECT 0 INTO _read_cnt;
      SELECT 0 INTO _read_sys_id;

      SELECT  sys_id FROM  (SELECT sys_id  FROM channel c 
      WHERE NOT EXISTS( SELECT 1 FROM delete_channel WHERE uid =_drumate_id AND ref_sys_id = c.sys_id) 
      ORDER BY c.sys_id  DESC ) a ORDER BY sys_id  DESC LIMIT 1 INTO _ref_sys_id;

      SELECT  ref_sys_id FROM read_channel WHERE uid = _drumate_id INTO _read_sys_id; 
      SELECT 
         COUNT(sys_id)
      FROM 
      channel c  WHERE  c.sys_id > _read_sys_id INTO _read_cnt ;

      INSERT INTO _last_node
      SELECT _drumate_id, _hub_id, LEFT(message, 100)  , attachment ,_read_cnt, ctime 
      FROM channel  WHERE sys_id = _ref_sys_id ;

      INSERT INTO _last_node
      SELECT _drumate_id, _hub_id, NULL , NULL ,_read_cnt , NULL  WHERE  _ref_sys_id IS NULL;


      UPDATE _list_uid SET is_checked = 1 WHERE id = _drumate_id ;
      SELECT NULL INTO _drumate_id;
      SELECT id  FROM _list_uid WHERE is_checked =0  LIMIT 1 INTO _drumate_id;
    END WHILE;

  SELECT * FROM _show_node;
  SELECT * FROM _last_node;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `channel_delete_hub_me` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `channel_delete_hub_me`(
  IN _uid VARCHAR(16) CHARACTER SET ascii,
  IN _option VARCHAR(16),
  IN _messages JSON
)
BEGIN
  DECLARE _idx_node INT(4) DEFAULT 0;
  DECLARE _message_id VARCHAR(16) CHARACTER SET ascii; 
  DECLARE _ref_sys_id BIGINT default 0;
  DECLARE _cnt INT ;
  DECLARE _memeber_cnt INT ;
  DECLARE _attachment  JSON;
  DECLARE _node json;
  DECLARE _delete_attachment  JSON;
  DECLARE _idx_attachment INT(4) DEFAULT 0; 
  DECLARE _read_cnt INT ;
  DECLARE _read_sys_id BIGINT default 0; 
  DECLARE _hub_id  VARCHAR(16) CHARACTER SET ascii;
  DECLARE _nid  VARCHAR(16) CHARACTER SET ascii;
  DECLARE _max_sys_id BIGINT;
  DECLARE _max_ref_sys_id BIGINT;
 
  SELECT id FROM yp.entity WHERE db_name=DATABASE() INTO _hub_id;
   DROP TABLE IF EXISTS _show_node;
   CREATE TEMPORARY TABLE _show_node AS SELECT * FROM channel WHERE 1=2;
   ALTER TABLE _show_node ADD `delete_attachment` JSON;

  SELECT count(id)
  FROM permission p 
  INNER JOIN yp.drumate d ON  p.entity_id=d.id 
  WHERE p.resource_id='*' INTO _memeber_cnt;

  WHILE _idx_node < JSON_LENGTH(_messages) DO 
    SELECT get_json_array(_messages, _idx_node) INTO _message_id;
    INSERT INTO _show_node SELECT  *, NULL FROM channel WHERE message_id = _message_id;
    SELECT attachment,sys_id FROM channel WHERE message_id = _message_id INTO _attachment,_ref_sys_id;

     
    INSERT INTO  delete_channel (uid,ref_sys_id,ctime)  
    SELECT _uid ,_ref_sys_id,UNIX_TIMESTAMP() ON DUPLICATE KEY UPDATE  ctime =UNIX_TIMESTAMP(); 
    SELECT 0 INTO _cnt;

    SELECT COUNT(1) FROM delete_channel WHERE ref_sys_id = _ref_sys_id INTO _cnt;
    DELETE FROM delete_channel WHERE ref_sys_id = _ref_sys_id AND  _cnt= _memeber_cnt ; 
    DELETE FROM channel WHERE message_id = _message_id AND  _cnt= _memeber_cnt; 

    IF _cnt = _memeber_cnt THEN 

      WHILE _idx_attachment < JSON_LENGTH(_attachment) DO 
        SELECT JSON_QUERY(_attachment, CONCAT("$[", _idx_attachment, "]") ) INTO _node;
        SELECT JSON_VALUE(_node, '$.hub_id') INTO _hub_id;
        SELECT JSON_VALUE(_node, '$.nid') INTO _nid;
        SELECT _idx_attachment + 1 INTO _idx_attachment;
        UPDATE yp.disk_usage SET size = IFNULL(size,0) - (SELECT IFNULL(SUM(filesize),0) FROM  
        media  WHERE id  =_nid ) WHERE hub_id =_hub_id;

        DELETE FROM  media WHERE id = _nid;
      END WHILE;

     UPDATE _show_node SET delete_attachment = _attachment WHERE message_id = _message_id; 

    END IF;

    SELECT _idx_node + 1 INTO _idx_node;
  END WHILE;


  
    DROP TABLE IF EXISTS `_last_node`;
    CREATE TEMPORARY TABLE `_last_node` (
      `uid` VARCHAR(16) CHARACTER SET ascii NOT NULL,  
      `entity_id` VARCHAR(16) CHARACTER SET ascii NOT NULL,
      `message`     VARCHAR(100) ,
      `attachment`  longtext,  
      `room_count` INT DEFAULT 0,
      `ctime` int(11)  NULL,
      UNIQUE KEY `id` (`uid`)
    ) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 ;

    SELECT NULL INTO _ref_sys_id; 
    SELECT 0 INTO _read_cnt;
    SELECT NULL INTO _read_sys_id;


    SELECT  sys_id FROM  (SELECT sys_id  FROM channel c 
    WHERE NOT EXISTS( SELECT 1 FROM delete_channel WHERE uid =_uid AND ref_sys_id = c.sys_id) 
    ORDER BY c.sys_id  DESC ) a ORDER BY sys_id  DESC LIMIT 1 INTO _ref_sys_id; 



    INSERT INTO _last_node
    SELECT _uid, _hub_id, LEFT(message, 100)  , attachment ,_read_cnt, ctime 
    FROM channel  WHERE sys_id = _ref_sys_id ;

    INSERT INTO _last_node
    SELECT _uid, _hub_id, NULL , NULL ,_read_cnt , NULL  WHERE  _ref_sys_id IS NULL;

   
    SELECT * FROM _show_node;
    SELECT * FROM _last_node;


END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `channel_delete_next` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `channel_delete_next`(
  IN _uid VARCHAR(16) CHARACTER SET ascii,
  IN _option VARCHAR(16),
  IN _messages JSON
)
BEGIN
  DECLARE _message_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _hub_id  VARCHAR(16) CHARACTER SET ascii;
  DECLARE _drumate_hub_id  VARCHAR(16) CHARACTER SET ascii;
  DECLARE _drumate_id  VARCHAR(16) CHARACTER SET ascii;
  DECLARE _nid  VARCHAR(16) CHARACTER SET ascii;
  DECLARE _node json;
  DECLARE _attachment  JSON;
  DECLARE _cnt INT(6) DEFAULT 0;
  DECLARE _idx_node INT(4) DEFAULT 0; 
  DECLARE _idx_attachment INT(4) DEFAULT 0; 
  DECLARE _sbx_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _sbx_db_name VARCHAR(255);
  DECLARE _type VARCHAR(16);
  DECLARE _entity_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _entity_db VARCHAR(255);  
  DECLARE _delete_nid VARCHAR(16) CHARACTER SET ascii;
  DECLARE _delete_attachment  JSON;
  DECLARE _ref_sys_id INT;



    SELECT id, type FROM yp.entity WHERE db_name=DATABASE() INTO _hub_id,_type;

    DROP TABLE IF EXISTS _show_node;
    CREATE TEMPORARY TABLE _show_node AS SELECT * FROM channel WHERE 1=2;
    ALTER TABLE _show_node ADD `delete_attachment` JSON;

    DROP TABLE IF EXISTS _list_uid;

    CREATE TEMPORARY TABLE _list_uid (
      id VARCHAR(16) CHARACTER SET ascii , 
      hub_id VARCHAR(16) CHARACTER SET ascii
      );

    ALTER TABLE _list_uid ADD `is_checked` boolean default 0 ;
    INSERT INTO _list_uid (id,hub_id) SELECT _uid,_hub_id;

    IF _type <> 'hub' THEN
      SELECT get_json_array(_messages, 0) INTO _message_id;
      SELECT entity_id FROM channel WHERE 
      message_id = _message_id INTO _entity_id;
    END IF;
   
    
    IF _type = 'hub' AND _option = 'all'  THEN
      INSERT INTO _list_uid (id, hub_id) SELECT  d.id, _hub_id FROM .permission p 
      INNER JOIN yp.drumate d on p.entity_id=d.id 
      WHERE p.resource_id='*' AND  d.id <> _uid;
    END IF;
    
    IF _type <> 'hub' AND _option = 'all'  THEN
      SELECT db_name FROM yp.entity WHERE id = _entity_id INTO _entity_db; 
      INSERT INTO _list_uid (id,hub_id) SELECT _entity_id,_entity_id;
    END IF; 



    WHILE _idx_node < JSON_LENGTH(_messages) DO 
      SELECT get_json_array(_messages, _idx_node) INTO _message_id;
    
      INSERT INTO _show_node SELECT  *, NULL FROM channel WHERE message_id = _message_id;
      SELECT attachment,sys_id FROM channel WHERE message_id = _message_id INTO _attachment,_ref_sys_id;
      
      
      
     
      
      
      
      

      
        
      
      
            
      
      
      
      
   
      
            
      
      
    
      

      
      
     
      
      
 
      IF _entity_db IS NOT NULL THEN

        SET @st = CONCAT('
        DELETE FROM ', _entity_db ,'.time_channel WHERE entity_id = ?');
        PREPARE stamt FROM @st;
        EXECUTE stamt USING  _uid;
        DEALLOCATE PREPARE stamt;


        SET @st = CONCAT('
        INSERT INTO ', _entity_db ,'.time_channel(entity_id, ref_sys_id,message,ctime)
        SELECT c.entity_id, c.sys_id,c.message, c.ctime FROM ', _entity_db ,'.channel c
        WHERE c.entity_id = ( SELECT  entity_id FROM ', _entity_db ,'.channel WHERE message_id = ?)  
        AND message_id <> ?
        ORDER BY c.sys_id DESC LIMIT 1
        ON DUPLICATE KEY UPDATE ref_sys_id= c.sys_id, ctime =c.ctime ,message=c.message');
        PREPARE stamt FROM @st;
        EXECUTE stamt USING _message_id,_message_id ;
        DEALLOCATE PREPARE stamt;


        SET @st = CONCAT('DELETE FROM ', _entity_db ,'.channel WHERE message_id= ?');
        PREPARE stamt FROM @st;
        EXECUTE stamt USING _message_id ;
        DEALLOCATE PREPARE stamt;
      END IF;

      IF _type <> 'hub' THEN
        DELETE FROM time_channel WHERE entity_id = _entity_id;
        INSERT INTO time_channel(entity_id, ref_sys_id,message,ctime)
        SELECT c.entity_id, c.sys_id,c.message, c.ctime FROM channel c
        WHERE c.entity_id = ( SELECT  entity_id FROM channel WHERE message_id = _message_id)  
        AND message_id <> _message_id
        ORDER BY c.sys_id DESC LIMIT 1
        ON DUPLICATE KEY UPDATE ref_sys_id= c.sys_id, ctime =c.ctime ,message=c.message;
        DELETE FROM channel WHERE message_id = _message_id;

      END IF;

      IF _type = 'hub' THEN
        INSERT INTO  delete_channel (uid,ref_sys_id,ctime)  
        SELECT id ,_ref_sys_id,UNIX_TIMESTAMP()  FROM _list_uid  ON DUPLICATE KEY UPDATE  ctime =UNIX_TIMESTAMP();
        SELECT 0 INTO _cnt;
        SELECT count(id)
        FROM permission p 
        INNER JOIN yp.drumate d ON  p.entity_id=d.id 
        WHERE p.resource_id='*'
        AND NOT EXISTS( SELECT 1 FROM delete_channel WHERE uid = d.id AND ref_sys_id = _ref_sys_id) INTO _cnt;

        DELETE FROM delete_channel WHERE ref_sys_id = _ref_sys_id AND  _cnt= 0 ; 
        DELETE FROM channel WHERE message_id = _message_id AND  _cnt= 0; 

      END IF;

      SELECT _idx_node + 1 INTO _idx_node;
    END WHILE;

    

    DROP TABLE IF EXISTS `_last_node`;
    CREATE TEMPORARY TABLE `_last_node` (
      `uid` VARCHAR(16) CHARACTER SET ascii NOT NULL,  
      `entity_id` VARCHAR(16) CHARACTER SET ascii NOT NULL,
      `message`     VARCHAR(100) ,
      `attachment`  longtext,  
      `ctime` int(11)  NULL,
      UNIQUE KEY `id` (`uid`)
    ) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 ;

    IF _type = 'hub' THEN
      SELECT id , hub_id FROM _list_uid WHERE is_checked =0  LIMIT 1 INTO _drumate_id , _drumate_hub_id;
        WHILE _drumate_id IS NOT NULL DO
      
          SELECT NULL INTO _ref_sys_id; 

          SELECT max(sys_id) 
          FROM  channel c 
          LEFT JOIN delete_channel dc  
              ON dc.ref_sys_id = sys_id AND uid = _drumate_id
          WHERE  ref_sys_id IS NULL INTO _ref_sys_id;

          INSERT INTO _last_node
          SELECT _drumate_id, _drumate_hub_id, message , attachment , ctime FROM channel  WHERE sys_id = _ref_sys_id ;

          INSERT INTO _last_node
          SELECT _drumate_id, _drumate_hub_id, NULL , NULL , NULL  WHERE  _ref_sys_id IS NULL;

          UPDATE _list_uid SET is_checked = 1 WHERE id = _drumate_id ;
          SELECT NULL,NULL INTO _drumate_id,_drumate_hub_id;
          SELECT id , hub_id FROM _list_uid WHERE is_checked =0  LIMIT 1 INTO _drumate_id , _drumate_hub_id;
        END WHILE;
    END IF;

    IF _type <> 'hub' THEN

     SELECT NULL INTO _ref_sys_id; 
     SELECT ref_sys_id FROM  time_channel WHERE  entity_id = _entity_id INTO  _ref_sys_id;
     INSERT INTO _last_node
     SELECT _uid, _entity_id, message , attachment , ctime FROM channel  WHERE sys_id = _ref_sys_id ;

     INSERT INTO _last_node
     SELECT _uid, _entity_id, NULL , NULL , NULL  WHERE  _ref_sys_id IS NULL;


    END IF;

    IF _entity_db IS NOT NULL THEN

      SELECT NULL INTO @ref_sys_id;

      SET @s = CONCAT(" SELECT ref_sys_id  FROM ",_entity_db , ".time_channel WHERE entity_id =? INTO @ref_sys_id");
      PREPARE stmt FROM @s;
      EXECUTE stmt USING _uid;
      DEALLOCATE PREPARE stmt;

      INSERT INTO _last_node
      SELECT _entity_id,_uid, NULL , NULL , NULL  WHERE  @ref_sys_id IS NULL;

      SET @s = CONCAT(" INSERT INTO _last_node  
      SELECT ?,?, message , attachment , ctime  FROM ",_entity_db , ".channel WHERE sys_id =? ");
      PREPARE stmt FROM @s;
      EXECUTE stmt USING _entity_id,_uid,  @ref_sys_id;
      DEALLOCATE PREPARE stmt;

    END IF;
    
    SELECT * FROM _show_node;
    

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `channel_get` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `channel_get`(
  IN _message_id VARCHAR(16)  CHARACTER SET ascii
)
BEGIN
DECLARE _type VARCHAR(16);
 
 SELECT type FROM yp.entity WHERE db_name=DATABASE() INTO _type;
  IF _type = 'hub' THEN
    SELECT *, 
   CASE WHEN JSON_LENGTH(metadata , '$._seen_')  >=  JSON_LENGTH(metadata , '$._delivered_') 
   THEN  1 ELSE 0 END is_seen 
   FROM channel WHERE message_id = _message_id;
  ELSE 
    SELECT * , 1 is_seen  FROM channel ch
    WHERE message_id = _message_id;
  END IF ;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `channel_get_last` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `channel_get_last`(
  IN _uid VARCHAR(16)  CHARACTER SET ascii
)
BEGIN
  DECLARE _type VARCHAR(16);
  DECLARE _sys_id int(11);
  
    SELECT type FROM yp.entity WHERE db_name=DATABASE() INTO _type;
    IF _type = 'hub' THEN
      SELECT max(ref_sys_id) FROM read_channel INTO _sys_id; 
    ELSE 
      SELECT ref_sys_id FROM read_channel WHERE uid = _uid INTO _sys_id; 
    END IF ;

    SELECT * ,1 is_seen FROM channel ch
    WHERE sys_id = _sys_id;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `channel_list_messages` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `channel_list_messages`(
  IN _uid VARCHAR(16),
  IN _sort_by VARCHAR(20),
  IN _order   VARCHAR(20),
  IN _page    TINYINT(4)
)
BEGIN
  DECLARE _recipient_db VARCHAR(255); 
  DECLARE _msg_id VARCHAR(16);
  DECLARE _timestamp int(11) unsigned;
  DECLARE _range bigint;
  DECLARE _offset bigint;
  DECLARE _ref_sys_id int(11) unsigned default 0 ;
  DECLARE _old_ref_sys_id int(11) unsigned default 0 ;

  CALL pageToLimits(_page, _offset, _range);  



  SELECT  sys_id FROM  (SELECT sys_id  FROM channel c 
  WHERE NOT EXISTS( SELECT 1 FROM delete_channel WHERE uid =_uid AND ref_sys_id = c.sys_id) 
  ORDER BY c.sys_id  DESC  LIMIT _offset, _range) a ORDER BY sys_id  DESC LIMIT 1 INTO _ref_sys_id; 

  SELECT ref_sys_id FROM read_channel WHERE  uid = _uid INTO _old_ref_sys_id;

  IF ( _ref_sys_id > IFNULL(_old_ref_sys_id,0)) THEN  

     UPDATE channel SET  metadata = JSON_SET(metadata,CONCAT("$._seen_.", _uid), UNIX_TIMESTAMP())
     WHERE sys_id <= _ref_sys_id   AND 
     JSON_EXISTS(metadata, CONCAT("$._seen_.", _uid))= 0;

    INSERT INTO read_channel(uid,ref_sys_id,ctime) SELECT _uid,_ref_sys_id,UNIX_TIMESTAMP() 
    ON DUPLICATE KEY UPDATE ref_sys_id= _ref_sys_id , ctime =UNIX_TIMESTAMP();
  END IF; 


  SELECT 
   _page as `page`,
    c.sys_id,
    c.author_id,  
    c.message,   
    c.message_id, 
    c.thread_id, 
    c.is_forward, 
    c.attachment, 
    CASE WHEN LTRIM(RTRIM(c.attachment))='' OR  c.attachment IS NULL THEN 0 ELSE 1 END is_attachment, 
    c.status,     
    c.ctime,      
    c.metadata,
    firstname, lastname, CONCAT(firstname, ' ', lastname) fullname,
    CASE WHEN _old_ref_sys_id  <  c.sys_id THEN 1 ELSE 0 END is_notify,  
    CASE WHEN JSON_EXISTS(metadata, CONCAT("$._seen_.", _uid))= 1 THEN 1 ELSE 0 END is_readed,
    CASE WHEN JSON_LENGTH(metadata , '$._seen_')  >=  JSON_LENGTH(metadata , '$._delivered_') 
    THEN  1 ELSE 0 END is_seen
  FROM 
    (SELECT sys_id FROM channel c  
      WHERE NOT EXISTS( SELECT 1 FROM delete_channel WHERE uid =_uid AND ref_sys_id = c.sys_id) 
    ORDER BY c.sys_id  DESC LIMIT _offset, _range) s
  INNER JOIN channel c  on c.sys_id = s.sys_id
  INNER JOIN(yp.drumate d)
  ON author_id=d.id
 
  ORDER BY c.sys_id DESC;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `channel_notify_messages` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `channel_notify_messages`(
  IN _uid VARCHAR(16)
)
BEGIN
  SELECT 
    COUNT(1)  read_cnt
  FROM channel WHERE 
  JSON_EXISTS(metadata, "$._seen_") AND  
  NOT JSON_EXISTS(metadata, CONCAT("$._seen_.", _uid)); 
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `channel_post_attachment` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `channel_post_attachment`(
  IN _message_id VARCHAR(16),
  IN _entity_id VARCHAR(16),
  IN _attachment json
)
BEGIN
  DECLARE _sbx_id VARCHAR(16); 

  DECLARE _nid VARCHAR(16); 
  DECLARE _sbx_db_name VARCHAR(255);
  DECLARE _idx_attachment INT(4) DEFAULT 0; 
  DECLARE _node JSON;
  DECLARE _type VARCHAR(16);
  DECLARE _hub_db_name VARCHAR(255);
  DECLARE _uid VARCHAR(255);

    DROP TABLE IF EXISTS _show_node;
    CREATE TEMPORARY TABLE _show_node (uid VARCHAR(16));
    ALTER TABLE _show_node ADD `is_checked` boolean default 0 ;

    SELECT type,db_name FROM yp.entity WHERE id= _entity_id INTO _type,_hub_db_name;

    IF _type = 'hub' THEN
      
      SET @s = CONCAT(" INSERT INTO _show_node (uid) SELECT  d.id FROM ",_hub_db_name , 
       ".permission p 
        INNER JOIN yp.drumate d on p.entity_id=d.id 
        WHERE 
        p.resource_id='*'");
      PREPARE stmt FROM @s;
      EXECUTE stmt ;
      DEALLOCATE PREPARE stmt;      
    ELSE  
       INSERT INTO _show_node (uid) SELECT _entity_id;
    END IF;

    WHILE _idx_attachment < JSON_LENGTH(_attachment) DO 
      SELECT JSON_QUERY(_attachment, CONCAT("$[", _idx_attachment, "]") ) INTO _node;
      SELECT JSON_VALUE(_node, '$.hub_id') INTO _sbx_id;
      SELECT JSON_VALUE(_node, '$.nid') INTO _nid;
      SELECT db_name FROM yp.entity WHERE id=_sbx_id INTO _sbx_db_name;


      UPDATE _show_node SET is_checked = 0;
      SELECT uid FROM _show_node WHERE is_checked =0  LIMIT 1 INTO _uid;
      WHILE _uid IS NOT NULL DO

        SET @s = CONCAT(" CALL ",_sbx_db_name , ".permission_grant(?,?,?,?,?,?)");
        PREPARE stmt FROM @s;
        EXECUTE stmt USING _nid,_uid,0,15,'system','chatpermission';
        DEALLOCATE PREPARE stmt;


        SET @s = CONCAT(" INSERT INTO  ",_sbx_db_name , ".attachment (message_id,hub_id,rid,uid) select ?,?,?,?");
        PREPARE stmt FROM @s;
        EXECUTE stmt USING _message_id,_entity_id,_nid,_uid;
        DEALLOCATE PREPARE stmt;


        UPDATE _show_node SET is_checked = 1 WHERE uid = _uid ;
        SELECT NULL INTO _uid;
        SELECT uid FROM _show_node WHERE is_checked =0  LIMIT 1 INTO _uid;
        
      END WHILE;

      SELECT _idx_attachment + 1 INTO _idx_attachment;
    END WHILE;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `channel_post_message_next` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `channel_post_message_next`(
  IN _in JSON ,
  IN _message text
)
BEGIN
 DECLARE _hub_id VARCHAR(16) CHARACTER SET ascii;  
 DECLARE _thread_id  VARCHAR(16) CHARACTER SET ascii;
 DECLARE _forward_message_id VARCHAR(16) CHARACTER SET ascii;
 DECLARE _attachment JSON;
 DECLARE _metadata JSON;
 DECLARE _author_id VARCHAR(16) CHARACTER SET ascii;
 DECLARE _entity_id VARCHAR(16) CHARACTER SET ascii;

 DECLARE _message_id VARCHAR(16) CHARACTER SET ascii;
 DECLARE _ctime int(11) unsigned;
 DECLARE _ref_sys_id int(11) unsigned;
 DECLARE _type VARCHAR(16);
 DECLARE _nid  VARCHAR(16) CHARACTER SET ascii;
 DECLARE _finished  INTEGER DEFAULT 0; 
 DECLARE _ticket_id  INTEGER DEFAULT NULL; 

DECLARE _is_duplicate INTEGER DEFAULT 0; 




 DECLARE _db_err JSON;
 DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
    GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE,@errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
    SELECT JSON_OBJECT('MSG',@text,'STATE',@sqlstate ) INTO _db_err;
    SELECT JSON_OBJECT( 'SUCCESS' ,0 , 'ERROR' , _db_err) INTO _db_err;
    SELECT _db_err;
  END;


  SELECT type FROM yp.entity WHERE db_name=DATABASE() INTO _type;
 
  SELECT JSON_VALUE(_in, "$.author_id") INTO _author_id;
  SELECT JSON_VALUE(_in, "$.entity_id") INTO _entity_id;
  SELECT JSON_VALUE(_in, "$.ticket_id") INTO _ticket_id; 

  SELECT JSON_VALUE(_in, "$.thread_id") INTO _thread_id; 
  SELECT JSON_VALUE(_in, "$.forward_message_id") INTO _forward_message_id; 
  SELECT JSON_QUERY(_in, "$.attachment") INTO _attachment; 
  SELECT JSON_VALUE(_in, "$.message_id") INTO _message_id;
  SELECT JSON_QUERY(_in, "$.metadata") INTO _metadata; 

  SELECT  1  FROM channel WHERE message_id =_message_id INTO _is_duplicate;

  SELECT UNIX_TIMESTAMP() INTO _ctime; 
  IF _message = '' THEN 
    SELECT NULL INTO _message;
  END IF ;
  
  IF _type = 'hub' THEN
    INSERT INTO channel (message_id,author_id,message,thread_id,ctime,attachment, metadata)
    SELECT _message_id,_author_id,_message,_thread_id,_ctime,_attachment,_metadata
      ON DUPLICATE KEY UPDATE  message_id =_message_id;
  ELSE 
    INSERT INTO channel (message_id,author_id,entity_id,message,thread_id,ctime,attachment,metadata)
    SELECT _message_id,_author_id,_entity_id,_message,_thread_id,_ctime,_attachment,_metadata
     ON DUPLICATE KEY UPDATE  message_id =_message_id;
  END IF ;


  UPDATE channel SET metadata=JSON_MERGE(
      IFNULL(metadata, '{}'), 
      JSON_OBJECT('_seen_', JSON_OBJECT(_author_id, 1)) ,    
      JSON_OBJECT('_delivered_',   JSON_OBJECT(_author_id,_ctime))
    )
  WHERE message_id=_message_id AND _is_duplicate = 0;

  UPDATE channel SET 
  is_forward =1, 
  metadata=JSON_MERGE(
                        IFNULL(metadata, '{}'), 
                        JSON_OBJECT('forward_message_id',   _forward_message_id),
                        JSON_OBJECT('forward_hub_id',   JSON_UNQUOTE(JSON_EXTRACT(_in, "$.hub_id")))
                       )
  WHERE message_id=_message_id AND _forward_message_id is NOT NULL AND _is_duplicate = 0;


  IF _entity_id <> _author_id THEN 
    UPDATE channel SET metadata=JSON_MERGE(IFNULL(metadata, '{}'), JSON_OBJECT('_delivered_',   JSON_OBJECT(_entity_id,_ctime)))
    WHERE message_id=_message_id AND _is_duplicate = 0 ;
  END IF;

  SELECT sys_id FROM channel WHERE message_id = _message_id   INTO _ref_sys_id;
  
  IF _type = 'hub' THEN
  


    SET _finished = 0;
      BEGIN
        DECLARE db_cursor CURSOR FOR SELECT  d.id 
          FROM permission p 
          INNER JOIN yp.drumate d on p.entity_id=d.id 
          WHERE 
            p.resource_id='*' AND d.id <> _author_id ;

        DECLARE CONTINUE HANDLER FOR NOT FOUND SET _finished = 1; 
        OPEN db_cursor;
          WHILE NOT _finished DO FETCH db_cursor INTO _nid;
          
            UPDATE channel SET  metadata = JSON_SET(metadata,CONCAT("$._delivered_.", _nid), _ctime)
            WHERE message_id = _message_id  AND _nid IS NOT NULL AND _is_duplicate = 0;

          END WHILE;
        CLOSE db_cursor;
      END; 
 
    INSERT INTO read_channel(uid,ref_sys_id,ctime) 
    SELECT _author_id,_ref_sys_id,_ctime
    ON DUPLICATE KEY UPDATE ref_sys_id= _ref_sys_id , ctime =_ctime;

    SELECT ticket_id FROM map_ticket WHERE message_id = _message_id INTO _ticket_id; 
    IF  _ticket_id IS NOT NULL THEN 

      UPDATE channel c INNER JOIN map_ticket mt ON mt.message_id = c.message_id
      SET  c.metadata = JSON_SET(metadata,CONCAT("$._seen_.", _author_id), UNIX_TIMESTAMP())
      WHERE c.sys_id <= _ref_sys_id   AND mt.ticket_id = _ticket_id AND
      JSON_EXISTS(metadata, CONCAT("$._seen_.", _author_id))= 0 AND _is_duplicate = 0;

      INSERT INTO yp.read_ticket_channel(uid,ticket_id , ref_sys_id,ctime) SELECT _author_id,_ticket_id,_ref_sys_id,UNIX_TIMESTAMP() 
      ON DUPLICATE KEY UPDATE ref_sys_id= _ref_sys_id , ctime =UNIX_TIMESTAMP() ;

      UPDATE yp.ticket SET last_sys_id =  _ref_sys_id WHERE  ticket_id =_ticket_id AND _is_duplicate = 0;
    ELSE 
      UPDATE channel SET  metadata = JSON_SET(metadata,CONCAT("$._seen_.", _author_id), _ctime)
      WHERE sys_id <= _ref_sys_id  AND 
      JSON_EXISTS(metadata, CONCAT("$._seen_.", _author_id))= 0 AND _is_duplicate = 0;  
    END IF;

    SELECT id FROM yp.entity WHERE db_name= DATABASE() INTO _hub_id; 
    SELECT 
      c.sys_id,     
      c.author_id,  
      c.message,   
      c.message_id, 
      c.thread_id,  
      c.is_forward,
      c.attachment, 
      c.status,     
      c.ctime,      
      c.metadata,  
      CASE WHEN JSON_EXISTS(c.metadata, CONCAT("$._seen_.", _author_id))= 1 THEN 1 ELSE 0 END is_readed,
      CASE WHEN JSON_LENGTH(c.metadata , '$._seen_')  >=  JSON_LENGTH(c.metadata , '$._delivered_') 
      THEN  1 ELSE 0 END is_seen,
      IFNULL(read_json_object(c.metadata, "message_type"),'chat')   message_type,
      CASE WHEN  t.message_id IS NOT NULL THEN 1 ELSE 0 END is_ticket,
      _hub_id hub_id,
      read_json_object(c.metadata, "call_status") call_status  
    FROM channel c 
    LEFT JOIN map_ticket mt ON mt.message_id= c.message_id
    LEFT JOIN yp.ticket t ON t.message_id= c.message_id
    WHERE c.message_id = _message_id ;

  ELSE 
    INSERT INTO time_channel(entity_id, ref_sys_id,message,ctime)
    SELECT _entity_id, _ref_sys_id,_message, _ctime ON DUPLICATE KEY UPDATE ref_sys_id= _ref_sys_id, ctime =_ctime ,message=_message;
  
    SELECT 
      sys_id,     
      author_id, 
      entity_id,  
      message,   
      message_id, 
      thread_id,  
      is_forward,
      attachment, 
      status,     
      ctime,      
      metadata,  
      CASE WHEN JSON_EXISTS(metadata, CONCAT("$._seen_.", _author_id))= 1 THEN 1 ELSE 0 END is_readed,
      CASE WHEN JSON_LENGTH(metadata , '$._seen_')  >=  JSON_LENGTH(metadata , '$._delivered_') 
      THEN  1 ELSE 0 END is_seen,
      IFNULL(read_json_object(metadata, "message_type"),'chat')   message_type, 
      0 is_ticket ,
      read_json_object(metadata, "call_status") call_status,
      read_json_object(metadata, "duration") call_duration  
      FROM channel WHERE message_id = _message_id;
  END IF ;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `channel_post_message_next1` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `channel_post_message_next1`(
  IN _in JSON ,
  IN _message text
)
BEGIN

 DECLARE _thread_id  VARCHAR(16);
 DECLARE _forward_message_id VARCHAR(16);
 DECLARE _attachment JSON;
 DECLARE _author_id VARCHAR(16);
 DECLARE _entity_id VARCHAR(16);

 DECLARE _message_id VARCHAR(16);
 DECLARE _ctime int(11) unsigned;
 DECLARE _ref_sys_id int(11) unsigned;
 DECLARE _type VARCHAR(16);
 DECLARE _nid  VARCHAR(16);
 DECLARE _finished  INTEGER DEFAULT 0; 

  SELECT type FROM yp.entity WHERE db_name=DATABASE() INTO _type;
 
  SELECT JSON_VALUE(_in, "$.author_id") INTO _author_id;
  SELECT JSON_VALUE(_in, "$.entity_id") INTO _entity_id;
  

  SELECT JSON_VALUE(_in, "$.thread_id") INTO _thread_id; 
  SELECT JSON_VALUE(_in, "$.forward_message_id") INTO _forward_message_id; 
  SELECT JSON_QUERY(_in, "$.attachment") INTO _attachment; 
  SELECT JSON_VALUE(_in, "$.message_id") INTO _message_id;

  SELECT UNIX_TIMESTAMP() INTO _ctime; 
  
  IF _type = 'hub' THEN
    INSERT INTO channel (message_id,author_id,message,thread_id,ctime,attachment)
    SELECT _message_id,_author_id,_message,_thread_id,_ctime,_attachment;
  ELSE 
    INSERT INTO channel (message_id,author_id,entity_id,message,thread_id,ctime,attachment)
    SELECT _message_id,_author_id,_entity_id,_message,_thread_id,_ctime,_attachment;
  END IF ;

  UPDATE channel SET metadata=JSON_MERGE(
      IFNULL(metadata, '{}'), 
      JSON_OBJECT('_seen_', JSON_OBJECT(_author_id, 1)) ,    
      JSON_OBJECT('_delivered_',   JSON_OBJECT(_author_id,_ctime))
    )
  WHERE message_id=_message_id;

  UPDATE channel SET 
  is_forward =1, 
  metadata=JSON_MERGE(
                        IFNULL(metadata, '{}'), 
                        JSON_OBJECT('forward_message_id',   _forward_message_id),
                        JSON_OBJECT('forward_hub_id',   JSON_UNQUOTE(JSON_EXTRACT(_in, "$.hub_id")))
                       )
  WHERE message_id=_message_id AND _forward_message_id is NOT NULL;


  IF _entity_id <> _author_id THEN 
    UPDATE channel SET metadata=JSON_MERGE(IFNULL(metadata, '{}'), JSON_OBJECT('_delivered_',   JSON_OBJECT(_entity_id,_ctime)))
    WHERE message_id=_message_id;
  END IF;

  SELECT sys_id FROM channel WHERE message_id = _message_id   INTO _ref_sys_id;
  
  IF _type = 'hub' THEN
    UPDATE channel SET  metadata = JSON_SET(metadata,CONCAT("$._seen_.", _author_id), _ctime)
    WHERE sys_id <= _ref_sys_id  AND 
    JSON_EXISTS(metadata, CONCAT("$._seen_.", _author_id))= 0;


    SET _finished = 0;
      BEGIN
        DECLARE db_cursor CURSOR FOR SELECT  d.id 
          FROM permission p 
          INNER JOIN yp.drumate d on p.entity_id=d.id 
          WHERE 
            p.resource_id='*' AND d.id <> _author_id ;

        DECLARE CONTINUE HANDLER FOR NOT FOUND SET _finished = 1; 
        OPEN db_cursor;
          WHILE NOT _finished DO FETCH db_cursor INTO _nid;
          
            UPDATE channel SET  metadata = JSON_SET(metadata,CONCAT("$._delivered_.", _nid), _ctime)
            WHERE message_id = _message_id ;

          END WHILE;
        CLOSE db_cursor;
      END; 
 
    INSERT INTO read_channel(uid,ref_sys_id,ctime) 
    SELECT _author_id,_ref_sys_id,_ctime
    ON DUPLICATE KEY UPDATE ref_sys_id= _ref_sys_id , ctime =_ctime;


    SELECT 
      sys_id,     
      author_id,  
      message,   
      message_id, 
      thread_id,  
      is_forward,
      attachment, 
      status,     
      ctime,      
      metadata,  
      CASE WHEN JSON_EXISTS(metadata, CONCAT("$._seen_.", _author_id))= 1 THEN 1 ELSE 0 END is_readed,
      CASE WHEN JSON_LENGTH(metadata , '$._seen_')  >=  JSON_LENGTH(metadata , '$._delivered_') 
      THEN  1 ELSE 0 END is_seen
    FROM channel WHERE message_id = _message_id ;

  ELSE 
    INSERT INTO time_channel(entity_id, ref_sys_id,message,ctime)
    SELECT _entity_id, _ref_sys_id,_message, _ctime ON DUPLICATE KEY UPDATE ref_sys_id= _ref_sys_id, ctime =_ctime ,message=_message;
  
    SELECT 
      sys_id,     
      author_id, 
      entity_id,  
      message,   
      message_id, 
      thread_id,  
      is_forward,
      attachment, 
      status,     
      ctime,      
      metadata,  
      CASE WHEN JSON_EXISTS(metadata, CONCAT("$._seen_.", _author_id))= 1 THEN 1 ELSE 0 END is_readed,
      CASE WHEN JSON_LENGTH(metadata , '$._seen_')  >=  JSON_LENGTH(metadata , '$._delivered_') 
      THEN  1 ELSE 0 END is_seen
    FROM channel WHERE message_id = _message_id;
  END IF ;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `check_huber` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `check_huber`(
  IN _uid  VARCHAR(16)
)
BEGIN

  SELECT
    entity.id,
    entity.ident,
    entity.area_id,
    entity.area,
    entity.vhost,
    drumate.dmail,
    drumate.email,
    drumate.firstname,
    drumate.lastname,
    drumate.remit,
    CONCAT(firstname, ' ', lastname) as `fullname`,
    privilege
  FROM yp.entity INNER JOIN (yp.drumate, huber) ON (drumate.id=entity.id AND huber.id=entity.id) WHERE id=_uid;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `conference_enter` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `conference_enter`(
  IN _socket_id VARCHAR(32),
  IN _status VARCHAR(32)
)
BEGIN
  DECLARE _master VARCHAR(16) DEFAULT '0';

  INSERT IGNORE INTO conference (`ctime`, `socket_id`, `status`) 
    SELECT UNIX_TIMESTAMP(), _socket_id, _status;

  
  
  
  

  SELECT s.uid FROM conference INNER JOIN yp.socket s ON socket_id=s.id 
    WHERE status='started'
    LIMIT 1 INTO _master;

  
  
  

  SELECT `uid`, `uid` AS id, firstname, lastname, fullname, 
    permission, c.ctime, 0 page, status, socket_id, s.server, _master master_id
    FROM conference c INNER JOIN (permission p, yp.socket s, yp.drumate d) 
    ON p.entity_id=s.uid AND s.uid=d.id AND c.socket_id=s.id 
    WHERE resource_id="*"
    GROUP BY socket_id
    ORDER BY c.ctime ASC;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `conference_enter_next` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `conference_enter_next`(
  IN _socket_id VARCHAR(32)
)
BEGIN
  DECLARE _master VARCHAR(16) DEFAULT '0';

  DELETE FROM conference WHERE 
    (SELECT id FROM yp.socket s WHERE s.id=socket_id) IS NULL;

  REPLACE INTO conference (`ctime`, `socket_id`, `status`) 
    SELECT UNIX_TIMESTAMP(), _socket_id, 'ready';

  SELECT `uid`, `uid` AS id, firstname, lastname, fullname, 
    permission, c.ctime, 0 page, status, socket_id, s.server
    FROM conference c INNER JOIN (permission p, yp.socket s, yp.drumate d) 
    ON p.entity_id=s.uid AND s.uid=d.id AND c.socket_id=s.id 
    WHERE resource_id="*"
    GROUP BY socket_id
    ORDER BY c.ctime ASC;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `conference_join` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `conference_join`(
  IN _args JSON,
  IN _metadata JSON 
)
BEGIN
  DECLARE _hub_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _socket_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _owner_id VARCHAR(16) CHARACTER SET ascii DEFAULT NULL;
  DECLARE _uid VARCHAR(16) CHARACTER SET ascii DEFAULT NULL;
  DECLARE _status VARCHAR(16) CHARACTER SET ascii DEFAULT 'waiting';
  DECLARE _permission TINYINT(2) DEFAULT 0;
  DECLARE _org_perm TINYINT(4) DEFAULT 0b0010000;
  DECLARE _role VARCHAR(128) DEFAULT 'attendee';  
  DECLARE _area VARCHAR(128) DEFAULT NULL;  

  SELECT JSON_VALUE(_args, "$.hub_id") INTO _hub_id;
  SELECT JSON_VALUE(_args, "$.socket_id") INTO _socket_id;

  IF JSON_VALUE(_args, "$.id") IS NULL THEN 
    SELECT id FROM yp.conference WHERE hub_ìd=_hub_id AND `type` = JSON_VALUE(_metadata, "$.type") INTO _id;
  ELSE 
    SELECT JSON_VALUE(_args, "$.id") INTO _id;
  END IF;

  SELECT IFNULL(_id, uniqueId()) INTO _id;


  SELECT area, id FROM yp.entity WHERE db_name = DATABASE() INTO _area, _hub_id;
  SELECT `uid` FROM yp.socket WHERE id=_socket_id AND `state`='active' LIMIT 1 INTO _uid;

  SELECT user_permission(_uid, _id) INTO _permission;


  IF _permission = 0 THEN 
    SELECT 0 permission;
  ELSE  
    IF _area IN('personal', 'private') THEN
      SELECT 'started' INTO _status;
    ELSE 
      SELECT IF(_uid = owner_id, 'started', 'waiting') FROM media WHERE id = _id INTO _status;
      IF _status = 'waiting' THEN 
        SELECT IF(_uid = JSON_VALUE(message, "$.owner_id"), 'started', 'waiting') FROM permission 
          WHERE resource_id=_id INTO _status;
      END IF;
      SELECT IF(_status = 'started', 'host', 'attendee') INTO _role;
      SELECT JSON_MERGE_PATCH(_metadata, JSON_OBJECT(
        'role', _role, 
        'permission', _permission
        )) INTO _metadata;

      REPLACE INTO yp.conference (id, socket_id, privilege, metadata) 
        VALUES(_id ,_socket_id, _permission, _metadata);

    END IF;
    SELECT 
      u.id,
      participant,
      participant attendee_id,
      c.uid,
      audio, 
      video, 
      screen, 
      _area area,
      _status `status`,
      permission,
      `role`, 
      coalesce(guest_name, firstname) firstname, 
      coalesce(guest_name, firstname) username, 
      coalesce(lastname, '') lastname,
      s.id socket_id,
      s.server
      FROM conference u 
        INNER JOIN socket s ON u.uid=s.id 
        INNER JOIN room r ON r.id=u.id
        INNER JOIN cookie c ON s.cookie=c.id
        LEFT JOIN drumate d on c.uid=d.id
      WHERE u.id =_id AND s.state='active';
  END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `conference_leave` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `conference_leave`(
  IN _socket_id VARCHAR(32)
)
BEGIN
  DECLARE _master VARCHAR(16);
  DECLARE _uid VARCHAR(16);

  SELECT s.uid
    FROM conference c INNER JOIN (permission p, yp.socket s, yp.drumate d) 
    ON p.entity_id=s.uid AND s.uid=d.id AND c.socket_id=s.id 
    WHERE permission & 0b0010000 AND resource_id='*' ORDER BY c.ctime ASC 
    LIMIT 1 INTO _master;
  SELECT `uid` FROM conference c INNER JOIN yp.socket s ON c.socket_id = s.id 
    WHERE `socket_id`=_socket_id INTO _uid;

  DELETE FROM conference WHERE `socket_id`=_socket_id;
  SELECT IF(_uid=_master, 'stopped', status) AS `status`, 
    `uid`, firstname, lastname, fullname, 
    permission, c.ctime, 0 page, socket_id, s.server
    FROM conference c INNER JOIN (permission p, yp.socket s, yp.drumate d) 
    ON p.entity_id=s.uid AND s.uid=d.id AND c.socket_id=s.id 
    WHERE resource_id="*"
    GROUP BY socket_id
    ORDER BY c.ctime, permission ASC;
  
  
  
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `conference_show_peers` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `conference_show_peers`(
  IN _socket_id VARCHAR(32)
)
BEGIN
  DECLARE _status VARCHAR(16);

  SELECT `uid`, firstname, lastname, fullname, 
    permission, c.ctime,  socket_id, s.server
    FROM conference c INNER JOIN (permission p, yp.socket s, yp.drumate d) 
    ON p.entity_id=s.uid AND s.uid=d.id AND c.socket_id=s.id
    WHERE socket_id <> _socket_id AND resource_id="*" GROUP BY socket_id
    ORDER BY c.ctime ASC;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `conference_start` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `conference_start`(
  IN _uid VARCHAR(16)
)
BEGIN
  DECLARE _status VARCHAR(255);
  SELECT IF(permission & 0b0010000, 'started', 'waiting')
    FROM permission 
    WHERE resource_id='*' AND entity_id=_uid INTO _status;

  UPDATE conference SET `status`=_status;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `conference_stop` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `conference_stop`(
)
BEGIN
  DELETE FROM conference;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `copy_media` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `copy_media`(
  IN _src_id VARCHAR(16),
  IN _dest_pid VARCHAR(16),
  IN _des_entity_id VARCHAR(16),
  IN _option  SMALLINT   
  )
BEGIN
  DECLARE _id varchar(16);
  DECLARE _temp_filename varchar(1024);
  DECLARE _lvl int;
  DECLARE _des_db   VARCHAR(255);
  
  DECLARE _area VARCHAR(25);
  DECLARE _vhost VARCHAR(255);
  DECLARE _home_dir VARCHAR(500);
  DECLARE _hub_id VARCHAR(16);
  DECLARE _origin_sb_db VARCHAR(255);
  DECLARE src_home_dir VARCHAR(500);

  DECLARE _is_src_folder boolean; 
  SELECT 0 INTO _is_src_folder;
  SELECT 1 FROM media m WHERE category ='folder' AND  m.id =_src_id INTO  _is_src_folder;  
  
  
  SELECT utils.vhost(ident), home_dir, id,db_name FROM yp.entity WHERE id=_des_entity_id
  INTO _vhost, _home_dir, _hub_id,_des_db;
  
  
  
    DROP TABLE IF EXISTS  _src_media;
    CREATE TEMPORARY TABLE `_src_media` (
    `id` varchar(16) DEFAULT NULL,
    `origin_id` varchar(16) DEFAULT NULL,
    `owner_id` varchar(16) NOT NULL,
    `host_id` varchar(16) NOT NULL,
    `file_path` varchar(512) DEFAULT NULL,
    `user_filename` varchar(128) DEFAULT NULL,
    `parent_id` varchar(16)  NULL DEFAULT '',
    `parent_path` varchar(1024) NOT NULL,
    `extension` varchar(100) NOT NULL DEFAULT '',
    `mimetype` varchar(100) NOT NULL,
    `category`  varchar(16) NOT NULL,
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
	  `lvl` int default 0,
    `is_checked` boolean default 0,
    `is_matched` boolean default 0,
    `is_delete` boolean default 0,
    `is_update` boolean default 0,
    `update_file_path`   varchar(1024)  NULL,
    `update_parent_path`   varchar(1024)  NULL,
    `new_id` varchar(16) DEFAULT NULL,
    `new_parent_id` varchar(16) DEFAULT NULL,
    `new_file_path`   varchar(1024)  NULL
    );

    DROP TABLE IF EXISTS  _des_media;
    CREATE TEMPORARY TABLE _des_media as select * from _src_media where 1=2;
    
    DROP TABLE IF EXISTS  _final_media;
    CREATE TEMPORARY TABLE _final_media as select * from _src_media where 1=2;
    
    ALTER table _src_media ADD `flg` char(1) DEFAULT 'S';
    ALTER table _des_media ADD `flg` char(1) DEFAULT 'D';
    ALTER table _final_media ADD `flg` char(1);

    SELECT db_name FROM yp.entity WHERE id =( 
        SELECT host_id FROM media WHERE id=_src_id AND file_path LIKE CONCAT("/__Inbound__","%") ) 
        INTO  _origin_sb_db ;


    
    IF _origin_sb_db IS NULL  then 
      
      INSERT INTO _src_media (id,file_path,user_filename,parent_id,parent_path,category,
      origin_id,owner_id,host_id,extension,mimetype,isalink,filesize,geometry,publish_time,upload_time,
      last_download,download_count,metadata,caption,status,approval,rank,
      is_checked,relative_path,lvl)
      SELECT id,file_path,user_filename,parent_id ,parent_path,category,
      origin_id,owner_id,host_id,extension,mimetype,isalink,filesize,geometry,publish_time,upload_time,
      last_download,download_count,metadata,caption,status,approval,rank,
      0, user_filename,0
      FROM media m WHERE m.id =_src_id;
    


      SELECT  id ,relative_path ,lvl FROM _src_media WHERE is_checked =0 LIMIT 1 INTO _id ,_temp_filename  ,_lvl;
      SET  _temp_filename =IFNULL(_temp_filename,'');

      WHILE _id is not null DO
        
          INSERT INTO _src_media (id,file_path,user_filename,parent_id ,parent_path,category,
          origin_id,owner_id,host_id,extension,mimetype,isalink,filesize,geometry,publish_time,upload_time,
          last_download,download_count,metadata,caption,status,approval,rank,
          is_checked,relative_path,lvl)
          SELECT  
            id,file_path,user_filename,parent_id,parent_path,category,
            origin_id,owner_id,host_id,extension,mimetype,isalink,filesize,geometry,publish_time,upload_time,
            last_download,download_count,metadata,caption,status,approval,rank,
            0,CONCAT(_temp_filename,"/",user_filename ) ,_lvl+1
          FROM media WHERE  parent_id =_id;
          
          UPDATE _src_media SET is_checked = 1 WHERE id = _id;
          SELECT NULL INTO _id;
          SELECT id ,relative_path ,lvl FROM _src_media WHERE is_checked =0 LIMIT 1 INTO _id,_temp_filename ,_lvl ;
          SET  _temp_filename =IFNULL(_temp_filename,"");
      END WHILE;
  ELSE 
    SET @sql = CONCAT('
      INSERT INTO _src_media 
        (id,file_path,user_filename,parent_id ,parent_path,category,
        origin_id,owner_id,host_id,extension,mimetype,isalink,filesize,geometry,publish_time,upload_time,
        last_download,download_count,metadata,caption,status,approval,rank,
        is_checked,relative_path,lvl)
      SELECT
        m.id,m.file_path,m.user_filename,m.parent_id ,m.parent_path,m.category,
        origin_id,owner_id,host_id,extension,mimetype,isalink,filesize,geometry,publish_time,upload_time,
        last_download,download_count,metadata,caption,status,approval,rank,
        0, m.user_filename,0
      FROM ' ,_origin_sb_db ,'.media m
      WHERE 
        m.id ="', _src_id ,'"');

      PREPARE stmt FROM @sql ;
      EXECUTE stmt;
      DEALLOCATE PREPARE stmt;

    
      SELECT  id ,relative_path,lvl FROM _src_media WHERE is_checked =0 LIMIT 1 INTO _id ,_temp_filename,_lvl; 
      SET  _temp_filename =IFNULL(_temp_filename,'''');

      WHILE _id is not null DO
          SET @sql = CONCAT('
          INSERT INTO _src_media (id,file_path,user_filename,parent_id ,parent_path,category,
          origin_id,owner_id,host_id,extension,mimetype,isalink,filesize,geometry,publish_time,upload_time,
          last_download,download_count,metadata,caption,status,approval,rank,
          is_checked,relative_path,lvl)
          SELECT  
            id,file_path,user_filename,parent_id,parent_path,category,
            origin_id,owner_id,host_id,extension,mimetype,isalink,filesize,geometry,publish_time,upload_time,
            last_download,download_count,metadata,caption,status,approval,rank,
            0,','CONCAT("',_temp_filename,'","/",user_filename ) ,',_lvl+1,
                  ' FROM ' ,_origin_sb_db,'.media WHERE  parent_id ="',_id,'"');
          PREPARE stmt FROM @sql ;
          EXECUTE stmt;
          DEALLOCATE PREPARE stmt;
          UPDATE _src_media SET is_checked = 1 WHERE id = _id;
          SELECT NULL INTO _id;
          SELECT id ,relative_path,lvl FROM _src_media WHERE is_checked =0 LIMIT 1 INTO _id,_temp_filename,_lvl ;
          SET  _temp_filename =IFNULL(_temp_filename,"");
    END WHILE;

  END IF;



    
    SELECT NULL,NULL INTO _id,_temp_filename;
    SET @sql = CONCAT('
    INSERT INTO _des_media 
      (id,file_path,user_filename,parent_id ,parent_path,category,
      origin_id,owner_id,host_id,extension,mimetype,isalink,filesize,geometry,publish_time,upload_time,
      last_download,download_count,metadata,caption,status,approval,rank,
      is_checked,relative_path,lvl)
    SELECT
      m.id,m.file_path,m.user_filename,m.parent_id ,m.parent_path,m.category,
      origin_id,owner_id,host_id,extension,mimetype,isalink,filesize,geometry,publish_time,upload_time,
      last_download,download_count,metadata,caption,status,approval,rank,
      0, m.user_filename,0
    FROM ' ,_des_db ,'.media m
    WHERE 
      parent_id ="', _dest_pid ,'" AND 
      category = ', CASE WHEN _is_src_folder =1 THEN "'folder'" ELSE "category" END ,'     AND 
      user_filename  = ( SELECT  user_filename  FROM _src_media sm WHERE sm.id ="', _src_id,'")');

    PREPARE stmt FROM @sql ;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

  
    SELECT  id ,relative_path,lvl FROM _des_media WHERE is_checked =0 LIMIT 1 INTO _id ,_temp_filename,_lvl; 
    SET  _temp_filename =IFNULL(_temp_filename,'''');

    WHILE _id is not null DO
         SET @sql = CONCAT('
        INSERT INTO _des_media (id,file_path,user_filename,parent_id ,parent_path,category,
        origin_id,owner_id,host_id,extension,mimetype,isalink,filesize,geometry,publish_time,upload_time,
        last_download,download_count,metadata,caption,status,approval,rank,
        is_checked,relative_path,lvl)
        SELECT  
          id,file_path,user_filename,parent_id,parent_path,category,
          origin_id,owner_id,host_id,extension,mimetype,isalink,filesize,geometry,publish_time,upload_time,
          last_download,download_count,metadata,caption,status,approval,rank,
          0,','CONCAT("',_temp_filename,'","/",user_filename ) ,',_lvl+1,
                ' FROM ' ,_des_db,'.media WHERE  parent_id ="',_id,'"');
        PREPARE stmt FROM @sql ;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
        UPDATE _des_media SET is_checked = 1 WHERE id = _id;
        SELECT NULL INTO _id;
        SELECT id ,relative_path,lvl FROM _des_media WHERE is_checked =0 LIMIT 1 INTO _id,_temp_filename,_lvl ;
        SET  _temp_filename =IFNULL(_temp_filename,"");
    END WHILE;
    
    
    UPDATE _des_media dm,_src_media sm SET dm.is_matched = 1 , sm.is_matched =1
	  WHERE  dm.relative_path = sm.relative_path AND dm.category=sm.category;


	  
	  UPDATE _des_media set is_delete=1 WHERE _option =0 ; 
    UPDATE _src_media set is_update=1 WHERE _option =0 ; 
	 
	  
	  UPDATE _des_media SET is_delete=1 WHERE _option =1 and is_matched= 1;  
    UPDATE _des_media SET is_update=1 WHERE _option =1 and is_matched= 0;  
    UPDATE _src_media SET is_update=1 WHERE _option =1;   


	  
	  

    SET @sql = CONCAT('SELECT file_path INTO @temp_parent_path FROM ', _des_db, '.media WHERE id = "', _dest_pid,'"');
    PREPARE stmt FROM @sql ;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
      
	  UPDATE _src_media SET update_file_path=concat(@temp_parent_path,"/",relative_path);
	  UPDATE _src_media SET update_parent_path= left(update_file_path , LENGTH(update_file_path)- LENGTH(user_filename)-1) ;	
     
     
    
	  UPDATE _des_media SET update_file_path=concat(@temp_parent_path,"/",relative_path);
	  UPDATE _des_media SET update_parent_path= left(update_file_path , LENGTH(update_file_path)- LENGTH(user_filename)-1) ;	

	  
    UPDATE _src_media SET parent_id = _dest_pid WHERE lvl=0;
   
	  
    
    UPDATE _src_media sm, _des_media dm SET dm.parent_id = sm.id 
    WHERE  dm.is_matched=0 AND dm.is_delete=0 AND dm.update_parent_path = sm.update_file_path AND dm.lvl=sm.lvl+1 AND _option = 1 ;
    
    
    UPDATE _src_media SET new_id=yp.uniqueId() WHERE is_update =1 ; 
    

    
    INSERT INTO _final_media SELECT * FROM _src_media where is_update =1;
    INSERT INTO _final_media SELECT * FROM _des_media where is_update =1;

    
    UPDATE _final_media fm,_src_media sm SET fm.new_parent_id = sm.new_id  WHERE fm.parent_id=sm.id;
    
    
    UPDATE _final_media SET 
    update_file_path =  CONCAT( update_parent_path,"/",  id ,"-orig.",extension)
    WHERE category NOT IN ("folder","hub");

    
    UPDATE _final_media SET 
    new_file_path =  CONCAT( update_parent_path,"/",  new_id ,"-orig.",extension)
    WHERE category NOT IN ("folder","hub");

    
       
    UPDATE _src_media SET is_delete =1 
    WHERE 
    _origin_sb_db IS NOT NULL
    AND id NOT IN 
    (
      SELECT id FROM media WHERE EXISTS   
      (SELECT id FROM yp.share_box WHERE id = (SELECT id FROM yp.entity WHERE db_name=DATABASE()))
    );

    
    
    SET @sql = CONCAT('DELETE FROM ', _des_db , '.media WHERE id in (SELECT  id FROM _des_media )');
    PREPARE stmt FROM @sql ;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    SET @sql = CONCAT( 'INSERT INTO ',_des_db,'.media 
    (
      id,file_path,user_filename,parent_id ,parent_path,category,
      origin_id,owner_id,host_id,extension,mimetype,isalink,filesize,geometry,publish_time,upload_time,
      last_download,download_count,metadata,caption,status,approval,rank
    )
    SELECT 
      IFNULL(new_id,id),IFNULL(new_file_path, update_file_path),user_filename,IFNULL(new_parent_id,parent_id),update_parent_path,category,
      origin_id,owner_id,host_id,extension,mimetype,isalink,filesize,geometry,UNIX_TIMESTAMP(),UNIX_TIMESTAMP(),
      last_download,download_count,metadata,caption,status,approval,rank FROM _final_media 
    WHERE id NOT IN
      (SELECT id FROM _src_media WHERE is_delete =1 )  
      ') ;
    PREPARE stmt FROM @sql ;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    
    
    
    SELECT 
      'MV' flg,
      id,
      user_filename ,
      concat(_home_dir, "/__storage__/", update_parent_path) AS  parent_path,
      concat(_home_dir, "/__storage__/", new_file_path) AS sys_new_file_path,
      concat(_home_dir, "/__storage__/", update_file_path ) AS sys_old_file_path,
      
  
      category
    FROM _final_media 
    WHERE 
      flg ='S' AND
      category NOT IN ("folder","hub") 
   
    UNION

    SELECT 
      'RM' as flg,
      id , 
      user_filename ,
      concat(_home_dir, "/__storage__/", parent_path)  parent_path ,
      NULL AS sys_new_file_path,
      NULL AS sys_old_file_path,
      category
    FROM _des_media 
    WHERE 
      category NOT IN ("folder","hub")  AND
      is_delete =1  AND
      is_matched= 1 
    
    UNION

    SELECT 
      'RMSN' as flg,   
      IFNULL(new_id,id), 
      user_filename ,
      concat(_home_dir, "/__storage__/", update_parent_path)  parent_path ,
      concat(_home_dir, "/__storage__/", new_file_path) AS sys_new_file_path,
      concat(_home_dir, "/__storage__/", update_file_path )  AS sys_old_file_path,
      category
    FROM _src_media 
    WHERE 
      is_delete =1  ;
    
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `count_download` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `count_download`(
  IN _id VARCHAR(16)
)
BEGIN

  UPDATE media SET download_count=download_count+1 WHERE id=_id;
  SELECT * from media where id=_id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `count_files` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `count_files`(
)
BEGIN

  SELECT COUNT(*) AS count FROM media WHERE media.category!='folder';

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `count_yet_read_next` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `count_yet_read_next`(
  IN _uid VARCHAR(16),
  IN _entity_id VARCHAR(16)
)
BEGIN
   
DECLARE _entity_id VARCHAR(16);
DECLARE _uid VARCHAR(16);
DECLARE _total_cnt int(11) unsigned;
DECLARE _room_cnt int(11) unsigned;
DECLARE _type VARCHAR(16);

  SELECT type FROM yp.entity WHERE db_name = DATABASE() INTO _type;
 IF _type != 'hub' THEN
 
    SELECT  
      COUNT(1)
    FROM 
      channel c 
    INNER JOIN read_channel rc ON rc.entity_id = c.entity_id  AND c.entity_id = c.author_id
    WHERE c.sys_id > rc.ref_sys_id  AND _uid = rc.uid 
    INTO  _total_cnt;

    SELECT  
      COUNT(1)
    FROM 
      channel c 
    INNER JOIN read_channel rc ON rc.entity_id = c.entity_id AND c.entity_id = c.author_id
    WHERE 
    rc.entity_id = _entity_id AND _uid = rc.uid AND
    c.sys_id > rc.ref_sys_id  INTO  _room_cnt;

  ELSE 
    SELECT  
      COUNT(1)
    FROM 
      channel c 
    INNER JOIN read_channel rc ON  c.author_id <> rc.uid
    WHERE c.sys_id > rc.ref_sys_id  AND _uid = rc.uid 
    INTO  _room_cnt;

 
  END IF; 
  
  SELECT _total_cnt total , _room_cnt room; 
 
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `creator_list` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `creator_list`(
  IN _page TINYINT(4),
  IN _criteria VARCHAR(16)
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  CALL pageToLimits(_page, _offset, _range);
  IF _criteria LIKE "D%" THEN
    SELECT
      id, author_id, hashtag, type, device, lang, firstname, laststname, comment, ctime, mtime, version, status,
      @vhost AS vhost
    FROM layout LEFT JOIN yp.drumate ON author_id=drumate.id WHERE editor='creator'
    ORDER BY mtime DESC LIMIT _offset, _range;
  ELSE
    SELECT
      id, author_id, hashtag, type, device, lang, firstname, laststname, comment, ctime, mtime, version, status,
      @vhost AS vhost
    FROM layout LEFT JOIN yp.drumate ON author_id=drumate.id WHERE editor='creator'
    ORDER BY mtime ASC LIMIT _offset, _range;
  END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `current_unique_filename` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `current_unique_filename`(
  _pid VARCHAR(16) CHARACTER SET ascii,
  _file_name VARCHAR(200),
  _ext VARCHAR(20)
)
BEGIN
  DECLARE _r VARCHAR(2000);
  DECLARE _fname VARCHAR(1024);
  DECLARE _base VARCHAR(1024);
  DECLARE _exten VARCHAR(1024);
  
    SELECT _file_name INTO _fname;
    SELECT _fname INTO _base;
    SELECT '' INTO   _exten;

    IF _fname regexp '\\\([0-9]+\\\)$'  THEN 
      SELECT SUBSTRING_INDEX(_fname, '(', 1) INTO _base;
      SELECT  SUBSTRING_INDEX(_fname, ')', -1) INTO _exten;
    END IF;

    WITH RECURSIVE chk as
      (
        SELECT @de:=0 as n ,  _fname fname,
        (SELECT COUNT(1) FROM media WHERE parent_id = _pid AND user_filename = _fname) cnt
      UNION ALL 
        SELECT @de:= n+1 n , CONCAT(_base, "(", n+1, ")", _exten) fname ,
        (SELECT COUNT(1) FROM media WHERE parent_id = _pid  AND user_filename = CONCAT(_base, "(", n+1, ")", _exten)) cnt
        FROM chk c 
        WHERE n<1000 AND cnt >=1
      )
    SELECT fname FROM chk WHERE n =@de  INTO _r ;

  SELECT  _r user_filename;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `custom_row_insert` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `custom_row_insert`(
  IN _name VARCHAR(80),
  IN _values MEDIUMTEXT
)
BEGIN
  DECLARE _id VARCHAR(16);
  DECLARE _i INTEGER DEFAULT 0;
  DECLARE _l INTEGER DEFAULT 0;

  SELECT id FROM custom WHERE `name`=_name OR id=_name INTO _id;
  SELECT JSON_LENGTH(_values) INTO _l;
  SELECT CONCAT('INSERT INTO `', _id, '` VALUES(') INTO @__row;
  
  WHILE _i < _l DO 
    IF _i + 1 = _l THEN 
      SELECT CONCAT(
        @__row,
        JSON_EXTRACT(_values, CONCAT("$[", _i, "]")), ')'
      ) INTO @__row;
    ELSE
      SELECT CONCAT(
        @__row,
        JSON_EXTRACT(_values, CONCAT("$[", _i, "]")), ','
      ) INTO @__row;
    END IF;
    SELECT _i + 1 INTO _i;
  END WHILE;

  IF _i THEN 
    PREPARE stmt FROM @__row;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;
  
  SELECT * FROM custom ORDER BY sys_id DESC LIMIT 1;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `custom_table_delete` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `custom_table_delete`(
  IN _name VARCHAR(80)
)
BEGIN
  DECLARE _id VARCHAR(16);
  DECLARE _count INTEGER;
  SELECT id FROM custom WHERE `name`=_name INTO _id;
  IF _id IS NOT NULL THEN 
    DELETE FROM  custom WHERE `id`=_id;
    SET @s = CONCAT("DROP TABLE `", _id, "`;");
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    SELECT _name AS name, _id AS id, 'deleted';
  END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `custom_table_get` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `custom_table_get`(
  IN _name VARCHAR(80)
)
BEGIN
  SELECT *, id AS table_name FROM custom WHERE `name` = _name OR id=_name;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `custom_table_register` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `custom_table_register`(
  IN _name VARCHAR(80),
  IN _uid VARCHAR(16)
)
BEGIN
  INSERT INTO custom VALUES(null, yp.uniqueId(), _name, _uid, UNIX_TIMESTAMP());
  SELECT *, id AS table_name FROM custom WHERE `name` = _name;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `dmz_add_link` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `dmz_add_link`(
  IN _share_id VARCHAR(50),
  IN _perm_id int(11) unsigned,
  IN _sender_id VARCHAR(16),
  IN _recipient_id VARCHAR(16)
)
BEGIN
  REPLACE INTO share VALUES(null, _share_id, _perm_id, _sender_id, _recipient_id, 'new');
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `dmz_check_share` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `dmz_check_share`(
  IN _sender_id VARCHAR(16),
  IN _hub_id VARCHAR(16)
)
BEGIN
  DECLARE _sid VARCHAR(255);
  SELECT id
  FROM 
  yp.share s
  WHERE s.sender_id = _sender_id AND 
  s.recipient_id = _recipient_id ; 

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `dmz_delete_share` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `dmz_delete_share`(
  IN _nid VARCHAR(16),
  IN _share_id VARCHAR(50)
)
BEGIN
  DECLARE _pid int(11);
  DECLARE _sid int(11);

  SELECT p.sys_id, s.sys_id 
  FROM 
  share s
  INNER JOIN  permission p on p.sys_id =s.permission_id
  WHERE s.id = _share_id AND p.resource_id = _nid INTO _pid, _sid;
  DELETE FROM permission WHERE sys_id = _pid;
  DELETE FROM share WHERE sys_id = _sid;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `dmz_get_meeting_members` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `dmz_get_meeting_members`(
 IN _uid  VARCHAR(16),
 IN _nid   VARCHAR(16)
)
BEGIN
  DECLARE _drumate_db VARCHAR(400);
  DECLARE _hub_id VARCHAR(16);
  DECLARE _home_id VARCHAR(16);

    SELECT db_name  FROM yp.entity WHERE id = _uid INTO _drumate_db;

    DROP TABLE IF EXISTS _contact;
    CREATE TEMPORARY TABLE _contact AS
    SELECT
      u.id  guest_id,
      d.id  drumate_id,
      u.email,
      u.email surname,
      CASE WHEN d.id IS NULL THEN 0 ELSE 1 END  is_drumate
    FROM
      permission p
      INNER JOIN yp.dmz_user u ON p.entity_id = u.id
      LEFT JOIN  yp.drumate d ON d.email = u.email
    WHERE u.id <> utils.get('guest_id') AND
      p.resource_id = _nid;


    ALTER TABLE _contact ADD contact_id  varchar(16);

    ALTER TABLE _contact ADD fullname  varchar(255);
    ALTER TABLE _contact ADD lastname  varchar(255);
    ALTER TABLE _contact ADD firstname  varchar(255);
    ALTER TABLE _contact ADD status  varchar(16);


    SET @st = CONCAT(" UPDATE ",_drumate_db, ".contact c
      INNER JOIN ",_drumate_db, ".contact_email ce ON ce.contact_id = c.id   AND ce.is_default = 1
      INNER JOIN _contact tc ON tc.drumate_id = c.uid OR tc.email = ce.email
      SET tc.contact_id  = c.id,
          tc.status = c.status,
          tc.firstname = c.firstname,
          tc.lastname  = c.lastname,
          tc.surname   = IFNULL(c.surname,IF(coalesce(c.firstname, c.lastname) IS NULL,ce.email,CONCAT( IFNULL(c.firstname, '') ,' ',  IFNULL(c.lastname, '')))) ,
          tc.fullname  = CONCAT(IFNULL(c.firstname, ''), ' ', IFNULL(c.lastname, ''))
        ");
    PREPARE stmt FROM @st;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

  SELECT * FROM _contact;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `dmz_get_members` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `dmz_get_members`(
 IN _uid  VARCHAR(16)
)
BEGIN
  DECLARE _drumate_db VARCHAR(400);
  DECLARE _hub_id VARCHAR(16);
  DECLARE _home_id VARCHAR(16);
  SELECT db_name  FROM yp.entity WHERE id = _uid INTO _drumate_db;


    DROP TABLE IF EXISTS _contact;
    CREATE TEMPORARY TABLE _contact AS
    SELECT 
      u.id  guest_id, 
      d.id  drumate_id,
      u.id  recipient_id,
      u.email,
      u.email surname, 
      CASE WHEN d.id IS NULL THEN 0 ELSE 1 END  is_drumate
    FROM 
      permission p 
    INNER JOIN yp.dmz_user u ON p.entity_id = u.id
    LEFT JOIN  yp.drumate d ON d.email = u.email
    WHERE u.id <> utils.get('guest_id');
    ALTER TABLE _contact ADD contact_id  varchar(16);
    ALTER TABLE _contact modify surname  varchar(255) CHARACTER set utf8mb4;
    ALTER TABLE _contact ADD fullname  varchar(255)  CHARACTER set utf8mb4;
    ALTER TABLE _contact ADD lastname  varchar(255)  CHARACTER set utf8mb4;
    ALTER TABLE _contact ADD firstname  varchar(255) CHARACTER set utf8mb4;
    ALTER TABLE _contact ADD status  varchar(16);
 

    SET @st = CONCAT(" UPDATE ",_drumate_db, ".contact c
      INNER JOIN ",_drumate_db, ".contact_email ce ON ce.contact_id = c.id   AND ce.is_default = 1  
      INNER JOIN _contact tc ON tc.drumate_id = c.uid OR tc.email = ce.email
      SET tc.contact_id  = c.id, 
          tc.status = c.status,
          tc.firstname = c.firstname,  
          tc.lastname  = c.lastname,
          tc.surname   = IFNULL(c.surname,IF(coalesce(c.firstname, c.lastname) IS NULL,ce.email,CONCAT( IFNULL(c.firstname, '') ,' ',  IFNULL(c.lastname, '')))) ,
          tc.fullname  = CONCAT(IFNULL(c.firstname, ''), ' ', IFNULL(c.lastname, '')) 
        "); 
    PREPARE stmt FROM @st;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

  SELECT * FROM _contact;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `dmz_notify_list` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `dmz_notify_list`(
  IN _flag   VARCHAR(50)
)
BEGIN
  DECLARE _ts INT(11);
  DECLARE _hub_id VARCHAR(16);
  
  SELECT UNIX_TIMESTAMP()INTO _ts;
  SELECT UNIX_TIMESTAMP()-43200 INTO _ts WHERE _flag = 'new' ;
  SELECT id FROM yp.entity WHERE db_name=DATABASE() INTO _hub_id;

  SELECT 
    t.id token,
    t.hub_id,
    u.id recipient_id,
    u.email,
    t.notify_at
  FROM 
    permission p 
    INNER JOIN yp.dmz_token t ON p.entity_id = t.guest_id
    INNER JOIN yp.dmz_user u ON p.entity_id = u.id
    WHERE t.notify_at <= _ts AND t.hub_id=_hub_id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `dmz_notify_list_next` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `dmz_notify_list_next`(
  IN _share_id VARCHAR(50), _flag   VARCHAR(50)
)
BEGIN
  DECLARE _ts INT(11);
  
  SELECT UNIX_TIMESTAMP()INTO _ts;
  SELECT UNIX_TIMESTAMP()-43200 INTO _ts WHERE _flag = 'new' ;
  

  SELECT 
    hub_id,
    recipient_id,
    g.email,
    s.notify_at
  FROM 
    yp.map_share s
  INNER JOIN yp.member_share  g ON g.id = s.recipient_id 
  WHERE s.share_id = _share_id AND  s.notify_at <= _ts ;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `dmz_remove_link` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `dmz_remove_link`(
  IN _rid VARCHAR(16),
  IN _eid VARCHAR(16)
)
BEGIN
  
  DELETE FROM share WHERE permission_id IN ( SELECT sys_id FROM permission WHERE resource_id=_rid AND entity_id=_eid );
  DELETE FROM share WHERE permission_id NOT IN ( SELECT sys_id FROM permission);
 
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `dmz_remove_member` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `dmz_remove_member`(
  IN _guest_id VARCHAR(50),
  IN _hub_id    VARCHAR(16),
  IN _node_id   VARCHAR(16)
)
BEGIN
  DECLARE _owner_id VARCHAR(50); 

  SELECT owner_id FROM yp.hub 
    WHERE id IN(SELECT id FROM yp.entity WHERE db_name = DATABASE())
    INTO _owner_id;

  DELETE FROM permission WHERE entity_id = _guest_id  AND entity_id <> _owner_id; 
  
  DELETE FROM yp.dmz_token WHERE hub_id = _hub_id AND 
   guest_id = _guest_id AND node_id = _node_id;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `dmz_revoke_privileges` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `dmz_revoke_privileges`(
  IN _resource_id VARCHAR(50)
)
BEGIN
  DECLARE _owner_id VARCHAR(50); 

  SELECT owner_id FROM yp.hub 
    WHERE id IN(SELECT id FROM yp.entity WHERE db_name = DATABASE())
    INTO _owner_id;

  DELETE FROM permission WHERE resource_id = _resource_id  AND entity_id <> _owner_id; 

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `dmz_revoke_user` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `dmz_revoke_user`(
  IN _resource_id VARCHAR(50)
)
BEGIN
  DECLARE _owner_id VARCHAR(50); 

  DELETE FROM  yp.dmz_token  WHERE node_id = _resource_id
  AND id  NOT IN (
  SELECT  entity_id FROM permission WHERE resource_id = _resource_id );

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `dmz_settings` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `dmz_settings`(
)
BEGIN
  DECLARE _ts INT(11);
  DECLARE _hub_id VARCHAR(16);
  DECLARE _home_id VARCHAR(16);
  DECLARE _public_token VARCHAR(60);
  DECLARE _permission INTEGER;
  DECLARE _days INTEGER;
  DECLARE _hours INTEGER;

  SELECT UNIX_TIMESTAMP() INTO _ts;


  SELECT id, home_id FROM yp.entity WHERE db_name=DATABASE() 
    INTO _hub_id, _home_id;

  SELECT t.id link,
    IF(t.fingerprint IS NULL, 0, 1) hasPaswword, 
    yp.duration_days(p.expiry_time) days,
    yp.duration_hours(p.expiry_time) hours,
    t.fingerprint,
    p.expiry_time,
    p.permission,
    CASE 
      WHEN IFNULL(p.expiry_time,0) = 0 THEN 'infinity' 
      WHEN (p.expiry_time - _ts) <= 0  THEN 'expired'
      ELSE 'active'
    END   dmz_expiry
  FROM  permission p 
    INNER JOIN yp.dmz_token t ON p.entity_id = t.guest_id
    INNER JOIN yp.dmz_user u ON p.entity_id = u.id
  WHERE t.hub_id=_hub_id AND t.node_id=_home_id AND 
    u.id = utils.get('guest_id');


  
  SELECT 
    t.id token,
    t.hub_id,
    u.id recipient_id,
    u.email,
    t.notify_at
  FROM 
    permission p 
    INNER JOIN yp.dmz_token t ON p.entity_id = t.guest_id
    INNER JOIN yp.dmz_user u ON p.entity_id = u.id
  WHERE t.hub_id=_hub_id AND t.node_id=_home_id AND 
  u.id <> utils.get('guest_id');
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `dmz_sync_grant` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `dmz_sync_grant`(
  IN _resource_id VARCHAR(50)
)
BEGIN
  DECLARE _owner_id VARCHAR(50); 

  DELETE FROM  yp.dmz_token  WHERE node_id = _resource_id
  AND guest_id  NOT IN (
  SELECT  entity_id FROM permission WHERE resource_id = _resource_id );

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `dmz_update_notify` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `dmz_update_notify`(
  IN _hub_id VARCHAR(50), 
  IN _recipient_id   VARCHAR(16)
)
BEGIN
  DECLARE _ts INT(11);
  UPDATE yp.map_share s SET notify_at = UNIX_TIMESTAMP()
  WHERE recipient_id = _recipient_id 
  AND hub_id = _hub_id; 

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `dmz_update_session_key` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `dmz_update_session_key`(
 IN _share_id VARCHAR(50),
 IN _session_key VARCHAR(16)
)
BEGIN
  IF _session_key IN ('') THEN 
    SELECT NULL INTO  _session_key;
  END IF; 
 
  UPDATE yp.share SET session_key = _session_key WHERE id = _share_id;
  CALL dmz_show_link_content(_share_id);

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `font_add` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `font_add`(
  IN _name VARCHAR(128),
  IN _variant VARCHAR(128),
  IN _url VARCHAR(1024)
)
BEGIN
  INSERT INTO font(`family`, `name`, `variant`, `url`, `ctime`, `mtime`)
            values(concat(`name`, ", ", `variant`), _name, _variant, _url, UNIX_TIMESTAMP(), UNIX_TIMESTAMP())
  ON DUPLICATE KEY UPDATE `family`=concat(`name`, ", ", `variant`),
            `name`=_name, `variant`=_variant, `url`=_url, mtime=UNIX_TIMESTAMP();
  SELECT * FROM font WHERE `name`=_name;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `font_list` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `font_list`(
  IN _page TINYINT(4)
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  CALL pageToLimits(_page, _offset, _range);

  SELECT * FROM `font` ORDER BY `name` ASC LIMIT _offset, _range;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `font_list_all` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `font_list_all`(
)
BEGIN
  SELECT * FROM `font` where status='active';
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `forward_message_get` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `forward_message_get`(IN _in JSON)
BEGIN
 DECLARE _out JSON;
 DECLARE _hub_id VARCHAR(16) CHARACTER SET ascii;
 DECLARE _message_id VARCHAR(16) CHARACTER SET ascii;
 DECLARE _hub_db VARCHAR(255);
 DECLARE _messages JSON;
 DECLARE _idx_node INT(4) DEFAULT 0; 
 DECLARE _temp_result JSON;
 DECLARE _new_nodes JSON;
 
    SELECT '[]' INTO _new_nodes ;

    SELECT get_json_object(_in, "hub_id") INTO _hub_id;
    SELECT get_json_object(_in, "messages") INTO _messages;

    SELECT db_name FROM yp.entity WHERE id=_hub_id INTO _hub_db;
    
    WHILE _idx_node < JSON_LENGTH(_messages) DO 
      
      SELECT get_json_array(_messages, _idx_node) INTO _message_id;
      
      SET @st = CONCAT('CALL ', _hub_db ,'.post_forward_message_get(?,?)');
      PREPARE stamt FROM @st;
      EXECUTE stamt USING  JSON_OBJECT('message_id', _message_id  ) , _temp_result ;
      DEALLOCATE PREPARE stamt; 
      
      SELECT JSON_MERGE ( _temp_result, JSON_OBJECT( 'hub_id', _hub_id )) INTO _temp_result ;
      SELECT JSON_ARRAY_INSERT(_new_nodes , '$[0]', _temp_result ) INTO _new_nodes;
      
      SELECT NULL INTO _temp_result ;
      SELECT _idx_node + 1 INTO _idx_node;
    END WHILE;

  SELECT JSON_UNQUOTE(_new_nodes) result;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `get_contributors` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `get_contributors`(
  IN _privilege    INT(4),
  IN _page         INT(4)
)
BEGIN
  DECLARE _range int(6);
  DECLARE _offset int(6);
  DECLARE _count int(6);
  DECLARE _hub_id VARCHAR(16);
  DECLARE _p int(4);

  CALL pageToLimits(_page, _offset, _range);
  SELECT COUNT(*) FROM member INTO _count;
  SELECT id FROM yp.entity WHERE db_name = database() INTO _hub_id;
  IF _privilege IS NULL OR _privilege = 0 THEN
    SELECT 0x3F INTO _p;
  ELSE
    SELECT _privilege INTO _p;
  END IF;

  SELECT _page as `page`,
    drumate.id, 
    permission AS privilege,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.firstname')), ''))AS firstname,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.lastname')), '')) AS lastname,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.email')), '')) AS email,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.mobile')), '')) AS mobile,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.address')), '')) AS address,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.city.content')), IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.city')), ''))) AS city,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.country.content')), IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.country')), ''))) AS country,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.country.value')), IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.country')), ''))) AS country_code,
    permission.ctime, 
    permission.utime, 
    IF(expiry_time > 0, expiry_time - UNIX_TIMESTAMP(), 0) AS ttl,
    _count as total
    FROM permission LEFT JOIN yp.drumate ON entity_id=drumate.id 
    WHERE entity_id != _hub_id AND (_p & permission > 0) AND expiry_time <>-1
    ORDER BY firstname ASC LIMIT _offset, _range;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `get_expired_huber` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `get_expired_huber`()
BEGIN
  SELECT * FROM huber WHERE (expiry_time <> 0 AND expiry_time < UNIX_TIMESTAMP());
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `get_filename` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `get_filename`(
  IN _node_id VARCHAR(16)
)
BEGIN

  SELECT TRIM(TRAILING '/' FROM file_path) as fname FROM media WHERE id=_node_id;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `get_fonts_faces` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `get_fonts_faces`(
)
BEGIN
  DECLARE _hub_id VARCHAR(16) DEFAULT 'george';
  DECLARE _hub_db VARCHAR(40);
  SELECT conf_value FROM yp.sys_conf WHERE conf_key='entry_host' INTO _hub_id;
  SELECT db_name FROM yp.entity WHERE id = _hub_id INTO _hub_db; 

    SET @sql = CONCAT("  SELECT * FROM ",_hub_db,".font_face" );
      PREPARE stmt FROM @sql;
      EXECUTE stmt;
      DEALLOCATE PREPARE stmt;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `get_fonts_links` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `get_fonts_links`(
)
BEGIN
  SELECT * FROM `font_link` where status='active';
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `get_media_comment` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `get_media_comment`(
  IN _id VARBINARY(16)
)
BEGIN
  SELECT
    comment.id AS id,
    ref_id     AS ref_id,
    owner_id   as oid,
    author_id  as author_id,
    content as comment,
    create_time as ctime,
    publish_time as ptime,
    edit_time as mtime,
    rating,
    firstname,
    lastname,
    if((UNIX_TIMESTAMP() - connexion_time)<120, 'on', 'off') as online,
    status
  FROM yp.drumate join comment on author_id=drumate.id WHERE comment.id=_id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `get_node_link` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `get_node_link`( 
   IN _src_id VARCHAR(16),
   IN _uid VARCHAR(16)
)
BEGIN
DECLARE _rid VARCHAR(16);
DECLARE _eid VARCHAR(16);
DECLARE _vhost VARCHAR(255);
  
  SELECT m.id ,p.entity_id 
  FROM permission p 
  INNER JOIN media m ON 
    m.id = p.resource_id 
  WHERE m.id =_src_id 
        AND p.entity_id = _uid
        AND p.assign_via='link' 
        INTO _rid,_eid ;

  SELECT 
    d.firstname,
    d.lastname,
    d.email,
    CONCAT ('https://',utils.vhost(e.ident),'/#/share/',_rid,'/',_eid) link
  FROM yp.entity e
  INNER JOIN yp.hub sb on sb.id = e.id
  INNER JOIN yp.drumate d on d.id = sb.owner_id
  WHERE e.db_name= DATABASE() AND _rid IS NOT NULL AND _eid IS NOT NULL ;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `get_privilege` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `get_privilege`(
  IN _uid VARBINARY(16),
  IN _area VARCHAR(12),
  OUT _priv TINYINT(2),
  OUT _hubers INT(8)
)
BEGIN
  DECLARE _tmp TINYINT(2);

  SELECT privilege FROM huber WHERE id=_uid INTO _tmp;
  SELECT count(*) FROM huber INTO _hubers;

  IF _tmp IS NULL OR _tmp='' THEN
    IF _area = 'public' THEN
      SET _priv=1;
    ELSE
      SELECT IF(_uid='ffffffffffffffff' OR _uid='nobody' OR _uid='' OR _uid IS NULL, -1, 0) INTO _priv;
    END IF;
  ELSE
    SET _priv=_tmp;
  END IF;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `get_pr_node_attr` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `get_pr_node_attr`(
   IN _node_id VARCHAR(16)
)
BEGIN

  SELECT 
      d.id entity_id ,  
      user_permission (d.id ,_node_id ) AS privilege, 
      d.email email,
      _node_id resource_id,
      yp.duration_days( user_expiry(d.id ,_node_id ))days,
      yp.duration_hours( user_expiry(d.id ,_node_id ))hours,
      read_json_object(d.profile, 'firstname') AS firstname,
      read_json_object(d.profile, 'lastname') AS lastname
  FROM
  (SELECT distinct entity_id FROM permission WHERE  expiry_time <>-1 ) p
  INNER JOIN yp.drumate d on p.entity_id=d.id 
  WHERE  user_permission (d.id ,_node_id ) > 0 ;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `get_seo` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `get_seo`(
  IN _key VARCHAR(512)
)
BEGIN
  IF _key IS NULL OR _key='' THEN
    SELECT * FROM seo limit 100;
  ELSE
    SELECT * FROM seo WHERE hashtag is NULL or hashtag='' limit 100;
  END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `get_statistics` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `get_statistics`()
BEGIN
    SELECT sys_id AS ID,
    disk_usage,
    page_count,
    visit_count
    FROM statistics ORDER BY sys_id DESC LIMIT 1;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `hub_add_action_log` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `hub_add_action_log`(
  
  IN _uid VARCHAR(16),
  IN _action VARCHAR(16),
  IN _category VARCHAR(16),
  IN _notify_to VARCHAR(16),
  IN _entity_id VARCHAR(16),
  IN  _log  VARCHAR(1000)
)
BEGIN

INSERT INTO action_log (uid, category,action,notify_to,entity_id,log,ctime )
SELECT _uid, _category,_action,_notify_to,_entity_id,_log,UNIX_TIMESTAMP();

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `hub_add_font_link` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `hub_add_font_link`(
  IN _name VARCHAR(128),
  IN _variant VARCHAR(128),
  IN _url VARCHAR(1024)
)
BEGIN
  INSERT INTO font(`family`, `name`, `variant`, `url`, `ctime`, `mtime`)
            values(concat(`name`, ", ", `variant`), _name, _variant, _url, UNIX_TIMESTAMP(), UNIX_TIMESTAMP())
  ON DUPLICATE KEY UPDATE `family`=concat(`name`, ", ", `variant`),
            `name`=_name, `variant`=_variant, `url`=_url, mtime=UNIX_TIMESTAMP();
  SELECT * FROM font WHERE `name`=_name;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `hub_clone_content` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `hub_clone_content`(
  IN _src_id VARCHAR(160)
)
BEGIN
  DECLARE _src_home_id VARCHAR(16);
  DECLARE _src_db VARCHAR(50);
  DECLARE _src_home_dir VARCHAR(120);
  DECLARE _src_name VARCHAR(120);
  DECLARE _dest_home_dir VARCHAR(120);
  DECLARE _dest_home_id VARCHAR(50);
  DECLARE _dest_id VARCHAR(50);

  SELECT home_layout, db_name, home_dir FROM yp.entity WHERE 
    id=_src_id OR ident=_src_id INTO _src_home_id, _src_db, _src_home_dir;

  SELECT id, home_dir FROM yp.entity  WHERE db_name = database() INTO _dest_id, _dest_home_dir;

  SELECT name FROM yp.hub WHERE id = _src_id INTO _src_name;
    
  IF _src_home_id IS NOT NULL THEN
    DELETE FROM media;
    SET @s = CONCAT("INSERT INTO media SELECT * FROM `", _src_db, "`.media");
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    DELETE FROM `block`;
    SET @s = CONCAT("INSERT INTO block SELECT * FROM `", _src_db, "`.block");
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    DELETE FROM `block_history`;
    SET @s = CONCAT("INSERT INTO block_history SELECT * FROM `", _src_db, "`.block_history");
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    DELETE FROM `font_face`;
    SET @s = CONCAT("INSERT INTO font_face SELECT * FROM `", _src_db, "`.font_face");
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    DELETE FROM `font`;
    SET @s = CONCAT("INSERT INTO font SELECT * FROM `", _src_db, "`.font");
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    DELETE FROM `font_link`;
    SET @s = CONCAT("INSERT INTO font_link SELECT * FROM `", _src_db, "`.font_link");
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    DELETE FROM `style`;
    SET @s = CONCAT("INSERT INTO style SELECT * FROM `", _src_db, "`.style");
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    CALL yp.hub_update_name(_dest_id, CONCAT(_src_name, " (copy)"));
    
    SELECT 
      _src_home_dir AS src_home_dir, 
      _src_home_id AS src_home_id, 
      _dest_home_dir AS dest_home_dir, 
      _dest_home_id as dest_home_id;
  END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `hub_get_action_log` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `hub_get_action_log`(
 IN _uid VARCHAR(16),
 IN _page TINYINT(4)
)
BEGIN

  DECLARE _is_admin int(10);
  DECLARE _range bigint;
  DECLARE _offset bigint;
    
    CALL pageToLimits(_page, _offset, _range);
    SELECT 0 INTO _is_admin; 

    SELECT 1 FROM permission p WHERE  resource_id='*'  and  p.entity_id= _uid  and permission&16 > 0 INTO _is_admin;


    SELECT 
        a.category,
        CASE WHEN a.category = 'media' THEN  CONCAT( a.log ,' by ',  d.firstname, ' ', d.lastname)  ELSE a.log END log,
        a.ctime
    FROM 
       (
        SELECT * FROM action_log where notify_to ='member' and entity_id = _uid
            UNION 
        SELECT * FROM action_log where notify_to = 'all' 
            UNION 
        SELECT * FROM action_log where notify_to ='admin'  and _is_admin =1 
       ) a
  INNER JOIN yp.drumate d ON a.uid=d.id 
   ORDER BY ctime desc LIMIT _offset, _range;  

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `hub_get_members_by_type` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `hub_get_members_by_type`(
  IN _uid  VARCHAR(16),
  IN _member_type enum('all', 'owner', 'not_owner', 'admin', 'other'),
  IN _page INT(6) 
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  DECLARE _drumate_db VARCHAR(400);
    CALL pageToLimits(_page, _offset, _range);

    SELECT db_name  FROM yp.entity WHERE id = _uid INTO _drumate_db;

    DROP TABLE IF EXISTS _contact;
    CREATE TEMPORARY TABLE _contact AS
    SELECT  
      _page as `page`, 
      d.id,
      permission AS privilege,
      d.email,
      d.firstname  firstname,
      d.lastname  lastname,
      d.fullname  fullname,
      d.fullname  surname ,
      
      
      JSON_VALUE(d.profile, "$.connected") `online`
    FROM permission p 
    INNER JOIN yp.drumate d on p.entity_id=d.id 
    LEFT JOIN yp.socket s on s.uid=d.id
    WHERE 
      resource_id='*'  AND 
      CASE 
        WHEN _member_type ='owner' THEN permission&32 > 0 
        WHEN _member_type ='admin' THEN permission&16 > 0 
        WHEN _member_type ='not_owner' THEN permission&32 = 0 
        WHEN _member_type ='other' THEN permission&16 = 0 
        ELSE 1
      END = 1;

     
       ALTER TABLE _contact ADD contact_id  varchar(16);
       ALTER TABLE _contact ADD status  varchar(16);



    SET @st = CONCAT(" UPDATE ",_drumate_db, ".contact c
      INNER JOIN ",_drumate_db, ".contact_email ce ON ce.contact_id = c.id   AND ce.is_default = 1  
      INNER JOIN _contact tc ON tc.id = c.uid OR tc.id = c.entity OR tc.email = ce.email
      SET tc.contact_id  = c.id, 
          tc.status = c.status,
          tc.firstname = c.firstname,  
          tc.lastname  = c.lastname,
          tc.surname   = IFNULL(c.surname,IF(coalesce(c.firstname, c.lastname) IS NULL,ce.email,CONCAT( IFNULL(c.firstname, '') ,' ',  IFNULL(c.lastname, '')))) ,
          tc.fullname  = CONCAT(IFNULL(c.firstname, ''), ' ', IFNULL(c.lastname, '')) 
        "); 
    PREPARE stmt FROM @st;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    SELECT page,id,privilege,email,lastname,fullname,surname, `online`,firstname, 1 as is_drumate, status, contact_id
    
    
    FROM _contact
    GROUP BY email
    ORDER BY firstname ASC, id ASC; 

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `hub_get_member_with_push_token` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `hub_get_member_with_push_token`()
BEGIN
  SELECT  
    d.id,
    d.email,
    dr.push_token,
    dr.device_id
    FROM permission p 
    INNER JOIN yp.drumate d on p.entity_id = d.id
    INNER JOIN yp.device_registation dr on d.id = dr.uid
    WHERE resource_id="*";
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `hub_get_member_with_push_token_next` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `hub_get_member_with_push_token_next`( 
IN  _exclude_id VARCHAR(16) CHARACTER SET ascii )
BEGIN

    IF rtrim(ltrim(_exclude_id)) IN ('',  '0') THEN 
      SELECT NULL INTO  _exclude_id;
    END IF;

  SELECT  
    d.id,
    d.email,
    dr.push_token,
    dr.device_id
    FROM permission p 
    INNER JOIN yp.drumate d on p.entity_id = d.id
    INNER JOIN yp.device_registation dr on d.id = dr.uid
    WHERE resource_id="*"  AND d.id <>_exclude_id ;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `hub_online_guests` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `hub_online_guests`(
  IN _nid VARCHAR(16)
)
BEGIN
  SELECT DISTINCT
    m.id, 
    email, 
    permission, 
    0 page, 
    s.id socket_id, 
    s.server     
    FROM permission p 
      INNER JOIN yp.socket s ON s.uid=p.entity_id
      INNER JOIN room r ON r.socket_id=s.id
      INNER JOIN yp.dmz_user m ON r.user_id=m.id
    WHERE resource_id=_nid AND s.state='active';
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `hub_online_members` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `hub_online_members`(
)
BEGIN
  (SELECT DISTINCT
    1 isDrumate,
    `uid`, 
    `uid` AS id, 
    firstname, 
    lastname, 
    fullname,      
    permission, 
    0 page, 
    s.id socket_id, 
    s.server     
    FROM permission p 
      INNER JOIN (yp.socket s, yp.drumate d)      
      ON p.entity_id=s.uid AND s.uid=d.id  
      WHERE resource_id="*" AND s.state ='active'
  )
  UNION
  (SELECT DISTINCT
    0 isDrumate,
    s.uid `uid`, 
    m.id, 
    email firstname, 
    email lastname, 
    email fullname, 
    permission, 
    0 page, 
    s.id socket_id, 
    s.server     
    FROM permission p 
      INNER JOIN yp.socket s ON p.entity_id = s.uid
      INNER JOIN yp.dmz_user m ON p.entity_id = m.id
      WHERE s.state ='active'
  );

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `hub_online_server_members` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `hub_online_server_members`(
  IN _server varchar(256)
)
BEGIN
  (SELECT DISTINCT
    1 isDrumate,
    `uid`, 
    `uid` AS id, 
    firstname, 
    lastname, 
    fullname,      
    permission, 
    0 page, 
    s.id socket_id, 
    s.server     
    FROM permission p 
      INNER JOIN (yp.socket s, yp.drumate d)      
      ON p.entity_id=s.uid AND s.uid=d.id AND s.server = _server 
      WHERE s.state = 'active' AND resource_id="*"
  )
  UNION
  (SELECT DISTINCT
    0 isDrumate,
    s.uid `uid`, 
    m.id, 
    email firstname, 
    email lastname, 
    email fullname, 
    permission, 
    0 page, 
    s.id socket_id, 
    s.server     
    FROM permission p 
      INNER JOIN yp.socket s ON ( p.entity_id = s.uid AND s.server = _server )
      INNER JOIN yp.dmz_user m ON p.entity_id = m.id
      WHERE s.state='active'  
  );

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `language_add` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `language_add`(
   IN _user_id      VARCHAR(100),
   IN _hub_id       VARCHAR(255),
   IN _hub_root     VARCHAR(500),
   IN _locale       VARCHAR(100),
   IN _state        VARCHAR(100)
)
BEGIN
  DECLARE _ts   INT(11) DEFAULT 0;
  DECLARE _base VARCHAR(10);
  DECLARE _name VARCHAR(100);
  DECLARE _db_name   VARCHAR(100);
  DECLARE _job_id   VARCHAR(100);
  SELECT UNIX_TIMESTAMP() INTO _ts;
  SELECT DATABASE() INTO _db_name;
  SELECT code, locale_en FROM yp.language WHERE lcid = _locale AND `state` = 'active' INTO _base, _name;

  IF IFNULL(_base, '') = "" OR IFNULL(_name, '') = "" THEN
    SELECT 1 AS invalid;
  ELSE
    INSERT INTO language (`base`, `name`, `locale`, `state`, `ctime`, `mtime`)
      VALUES(IFNULL(_base, ''), IFNULL(_name, ''), _locale, _state, _ts, _ts)
      ON DUPLICATE KEY UPDATE state=_state, mtime=_ts;
    
    IF LCASE(_state) = 'frozen' THEN
      SELECT SHA1(UUID()) INTO _job_id;
      INSERT IGNORE INTO yp.job_credential (`app_key`, `customer_key`, `job_id`, `user_id`, `ctime`)
        SELECT "language_management", id, _job_id, _user_id, _ts FROM yp.entity WHERE ident='admin';
      INSERT IGNORE INTO yp.frozen_language (`hub_id`, `dbase_name`, `root_path`, `job_id`, `lang`, `ctime`)
        VALUES(_hub_id, _db_name, _hub_root, _job_id, _locale, _ts);
    ELSEIF LCASE(_state) = 'active' OR LCASE(_state) = 'replaced' or LCASE(_state) = 'deleted' THEN
      DELETE FROM yp.frozen_language WHERE hub_id = _hub_id AND dbase_name = _db_name AND lang = _locale;
    END IF;
    
    SELECT sys_id AS language_id, base, name, locale, state FROM language WHERE locale = _locale;
  END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `language_add_next` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `language_add_next`(
   IN _locale       VARCHAR(100)
)
BEGIN
  DECLARE _ts   INT(11) DEFAULT 0;
  DECLARE _base VARCHAR(10);
  DECLARE _name VARCHAR(100);
  DECLARE _db_name   VARCHAR(100);
  DECLARE _job_id   VARCHAR(100);
  SELECT UNIX_TIMESTAMP() INTO _ts;
  SELECT DATABASE() INTO _db_name;
  SELECT code, locale_en FROM yp.language WHERE lcid = _locale AND `state` = 'active' 
    INTO _base, _name;

  IF _base IS NULL OR _name IS NULL THEN
    REPLACE INTO `language` SELECT null, "en", "English", "en", "active", _ts,_ts; 
  ELSE
    REPLACE INTO `language` SELECT null, _base, _name, _locale, "active", _ts,_ts;
  END IF;
  SELECT sys_id AS language_id, base, name, locale, state 
    FROM language WHERE locale = _locale;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `language_available_list` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `language_available_list`(
  IN _name         VARCHAR(200),
  IN _page         INT(11)
)
BEGIN
  DECLARE _range int(6);
  DECLARE _offset int(6);
  CALL pageToLimits(_page, _offset, _range);
  SELECT code, lcid, locale_en, locale, flag_image FROM yp.language WHERE `state` = 'active'
    AND code NOT IN (SELECT locale FROM language WHERE state = 'active' OR state = 'replaced')
    AND locale_en LIKE CONCAT(TRIM(IFNULL(_name, '')), '%')
    ORDER BY locale_en ASC LIMIT _offset, _range;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `language_change_state` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `language_change_state`(
   IN _user_id      VARCHAR(100),
   IN _hub_id       VARCHAR(255),
   IN _hub_root     VARCHAR(500),
   IN _locale       VARCHAR(100),
   IN _state        VARCHAR(20)
)
BEGIN
  DECLARE _ts   INT(11) DEFAULT 0;
  DECLARE _language_count INT(11) DEFAULT 0;
  DECLARE _db_name   VARCHAR(100);
  DECLARE _job_id   VARCHAR(100);
  SELECT UNIX_TIMESTAMP() INTO _ts;
  SELECT DATABASE() INTO _db_name;
  SELECT COUNT(*) FROM language WHERE state = 'active' INTO _language_count;
  IF _language_count <= 1 AND (LCASE(_state) = 'frozen' OR LCASE(_state) = 'deleted') THEN
    SELECT 0 AS updated;
  ELSE
    UPDATE language SET state = _state, mtime = _ts WHERE locale = _locale;
    IF LCASE(_state) = 'frozen' THEN
      SELECT SHA1(UUID()) INTO _job_id;
      INSERT IGNORE INTO yp.job_credential (`app_key`, `customer_key`, `job_id`, `user_id`, `ctime`)
        SELECT "language_management", id, _job_id, _user_id, _ts FROM yp.entity WHERE ident='admin';
      INSERT IGNORE INTO yp.frozen_language (`hub_id`, `dbase_name`, `root_path`, `job_id`, `lang`, `ctime`)
        VALUES(_hub_id, _db_name, _hub_root, _job_id, _locale, _ts);
      SELECT 1 AS updated;
    ELSEIF LCASE(_state) = 'active' OR LCASE(_state) = 'replaced' OR LCASE(_state) = 'deleted' THEN
      DELETE FROM yp.frozen_language WHERE hub_id = _hub_id AND dbase_name = _db_name AND lang = _locale;
      SELECT 1 AS updated;
    END IF;
  END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `language_find_base` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `language_find_base`()
BEGIN
  SELECT sys_id AS language_id, base, name, locale, state FROM language WHERE state = 'active' OR state = 'replaced' ORDER BY sys_id ASC LIMIT 1;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `language_get_by_locale` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `language_get_by_locale`(
   IN _locale       VARCHAR(100)
)
BEGIN
  SELECT sys_id AS language_id, base, name, locale, state FROM language WHERE locale = _locale;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `language_get_list` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `language_get_list`(
  IN _page         INT(11)
)
BEGIN
  DECLARE _range int(6);
  DECLARE _offset int(6);
  CALL pageToLimits(_page, _offset, _range);
  SELECT sys_id AS language_id, 
    base, 
    name, 
    yl.code,
    yl.locale_en,
    yl.lcid,
    name locale, 
    flag_image, 
    l.state 
    FROM `language` l
    JOIN yp.language yl ON yl.lcid = l.locale
    WHERE l.state = 'active' OR l.state = 'replaced' ORDER BY name ASC
    LIMIT _offset, _range;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `layout_add` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `layout_add`(
   IN _tag    VARCHAR(512),
   IN _author     VARBINARY(16),
   IN _lang      VARCHAR(20),
   IN _comment    TEXT,
   IN _context    VARCHAR(16),
   IN _content       MEDIUMTEXT,
   IN _device     VARCHAR(16),
   IN _vesrion    VARCHAR(16)
)
BEGIN
   DECLARE _new_id VARCHAR(16) DEFAULT '';
   DECLARE _hash VARCHAR(512) DEFAULT '';
   DECLARE _ts    INT(11) DEFAULT 0;
   SELECT uniqueId(), UNIX_TIMESTAMP(), layout_ident(_tag, _lang, _device) INTO _new_id, _ts, _hash;

   INSERT INTO layout (`id`, `context`, `hashtag`, `hash`, `tag`, `device`, `lang`, `author`, `author_id`,
   	  `comment`, `content`, `status`, `ctime`, `mtime`, `version`)
   VALUES(_new_id, _context, _tag, _hash, _tag, _device, _lang, _author, _author,
          _comment, _content, 'active', _ts, _ts, _vesrion);

   SELECT *, tag as hashtag FROM layout WHERE id=_new_id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `layout_backup` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `layout_backup`(
   IN _id           VARBINARY(16),
   IN _letc  MEDIUMTEXT
)
BEGIN
   UPDATE layout SET backup=_letc, mtime=UNIX_TIMESTAMP() WHERE id=_id;
   SELECT backup, id FROM layout WHERE id=_id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `layout_copy` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `layout_copy`(
   IN _id    VARCHAR(16),
   IN _author  VARCHAR(160)
)
BEGIN
   DECLARE _new_id VARBINARY(16) DEFAULT '';
   DECLARE _new_tag VARCHAR(512);
   DECLARE _tag VARCHAR(512);
   DECLARE _ident VARCHAR(512);

   SELECT tag, layout_ident(tag, lang, device) FROM layout WHERE id=_id INTO _tag, _ident;
   IF _tag='' OR _tag IS NULL THEN
     SELECT NULL;
   ELSE
     SET _new_id = uniqueId();
     SELECT concat(_tag, '-', COUNT(*)+1) FROM layout WHERE hash LIKE concat(_tag,"%!%!%") INTO _new_tag;
     INSERT INTO layout (`id`, `context`, `hash`, `tag`, `lang`, `device`, `author`, `comment`,
            `content`, `status`, `ctime`, `mtime`, `version`)
     SELECT _new_id, `context`, layout_ident(_new_tag, lang, device), _new_tag, lang, device, _author, comment,
            content, status, ctime, mtime, version FROM layout WHERE id=_id;
     SELECT * FROM layout WHERE id=_new_id;
   END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `layout_delete` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `layout_delete`(
   IN _tag      varchar(400),
   IN _lang     varchar(10),
   IN _device   varchar(10)
)
BEGIN
   DELETE FROM layout WHERE hash=concat(_tag, '!', _lang, '!', _device);
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `layout_find` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `layout_find`(
  IN _pattern VARCHAR(84),
  IN _page TINYINT(4)
)
BEGIN

  DECLARE _range bigint;
  DECLARE _offset bigint;
  CALL pageToLimits(_page, _offset, _range);

  SELECT
    *,
    @vhost AS vhost,
    tag as hashtag,
  MATCH(`content`) against(concat('*', _pattern, '*') IN BOOLEAN MODE) as relevance
  FROM layout HAVING relevance > 1 OR hashtag LIKE concat("%", _pattern, "%")
  ORDER BY relevance DESC, mtime DESC LIMIT _offset, _range;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `layout_get` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `layout_get`(
   IN _tag VARCHAR(512),
   IN _lang  VARCHAR(16),
   IN _device  VARCHAR(16)
)
BEGIN
   SELECT id, get_ident() AS owner, author, comment, context, status, if(status='draft', backup, content) as letc,
      tag as hashtag, lang, device, ctime, mtime, version
   FROM layout WHERE id=_tag OR tag=_tag
     ORDER BY layout_score(hash, tag, lang, device) DESC LIMIT 1;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `layout_get_v2` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `layout_get_v2`(
   IN _hashtag VARCHAR(512)
)
BEGIN
   DECLARE _l VARCHAR(20);
   DECLARE _d VARCHAR(20);
   SELECT id, concat(@root, id, '/') AS layout_path, @entity_id AS oid,
     author, status, mtime, version
   FROM layout WHERE id=_hashtag OR hashtag=_hashtag;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `layout_home` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `layout_home`(
)
BEGIN
  SELECT
    area, concat(TRIM(TRAILING '/' FROM home_dir), '/Layout/'), id from yp.entity where db_name=database()
  INTO @area, @root, @entity_id;
  SELECT @area as area, @entity_id as eid, @root AS layout_root;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `layout_list` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `layout_list`(
  IN _page TINYINT(4),
  IN _criteria VARCHAR(16)
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  CALL pageToLimits(_page, _offset, _range);
  IF _criteria LIKE "D%" THEN
    SELECT
      *,
      @vhost AS vhost,
      tag as hashtag
    FROM layout ORDER BY mtime DESC LIMIT _offset, _range;
  ELSE
    SELECT
      *,
      @vhost AS vhost,
      tag as hashtag
    FROM layout ORDER BY mtime ASC LIMIT _offset, _range;
  END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `layout_list_by` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `layout_list_by`(
  IN _page TINYINT(4),
  IN _type VARCHAR(16),
  IN _criteria VARCHAR(16)
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  CALL pageToLimits(_page, _offset, _range);
  IF _criteria LIKE "D%" THEN
    SELECT
      id, author_id, hashtag, type, device, lang, author, comment, ctime, mtime, version, status,
      @vhost AS vhost
    FROM layout WHERE type=_type ORDER BY mtime DESC LIMIT _offset, _range;
  ELSE
    SELECT
      id, author_id, hashtag, type, device, lang, author, comment, ctime, mtime, version, status,
      @vhost AS vhost
    FROM layout WHERE type=_type ORDER BY mtime ASC LIMIT _offset, _range;
  END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `layout_new` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `layout_new`(
   IN _author     VARBINARY(16),
   IN _lang      VARCHAR(20),
   IN _context    VARCHAR(16),
   IN _content       MEDIUMTEXT,
   IN _device     VARCHAR(16),
   IN _vesrion    VARCHAR(16)
)
BEGIN
   DECLARE _id VARCHAR(16) DEFAULT '';
   DECLARE _hash VARCHAR(512) DEFAULT '';
   DECLARE _tag VARCHAR(512) DEFAULT '';
   DECLARE _ts    INT(11) DEFAULT 0;

   SELECT uniqueId() INTO _id;
   SET _tag = _id;
   SELECT UNIX_TIMESTAMP(), layout_ident(_tag, _lang, _device) INTO _ts, _hash;

   INSERT INTO layout (`id`, `context`, `hash`, `tag`, `device`, `lang`, `author`, `content`, `backup`,
   	  `status`, `ctime`, `mtime`, `version`)
   VALUES(_id, _context, _hash, _tag, _device, _lang, _author, _content, _content,
          'draft', _ts, _ts, _vesrion)
   ON DUPLICATE KEY UPDATE backup=_content, mtime=_ts;
   SELECT *, tag as hashtag FROM layout WHERE id=_id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `layout_purge` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `layout_purge`(
   IN _id      VARBINARY(16)
)
BEGIN
   DELETE FROM layout WHERE id=_id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `layout_push` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `layout_push`(
   IN _dbname     VARCHAR(80),
   IN _tag    VARCHAR(512)
)
BEGIN
   DECLARE _new_id VARBINARY(16) DEFAULT '';
   DECLARE _new_tag VARCHAR(512);
   DECLARE _ts    INT(11) DEFAULT 0;

   DROP TABLE IF EXISTS `_tmp_layout`;
   CREATE TEMPORARY TABLE _tmp_layout AS (SELECT * FROM layout WHERE tag=_tag);
   UPDATE _tmp_layout SET status='readonly', mtime=UNIX_TIMESTAMP(), id=uniqueId() WHERE tag=_tag;

   SET @s = CONCAT("INSERT IGNORE INTO `", _dbname, "`.`layout` SELECT * FROM _tmp_layout");
   SELECT @s;



   SELECT * FROM _tmp_layout WHERE tag=_tag;
   DROP TABLE IF EXISTS `_tmp_layout`;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `layout_save` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `layout_save`(
   IN _id       VARCHAR(16),
   IN _content  MEDIUMTEXT,
   IN _dummy  VARCHAR(16)
)
BEGIN
   DECLARE _mtime INT(11) DEFAULT 0;
   SELECT UNIX_TIMESTAMP() INTO _mtime;
   UPDATE layout SET content=_content, status='active', mtime=_mtime WHERE id=_id;
   SELECT
     *,
     @vhost AS vhost,
     tag as hashtag
   FROM layout WHERE id=_id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `layout_search` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `layout_search`(
  IN _pattern VARCHAR(84),
  IN _page TINYINT(4)
)
BEGIN

  DECLARE _range bigint;
  DECLARE _offset bigint;
  CALL pageToLimits(_page, _offset, _range);

  SELECT
    *,
    @vhost AS vhost,
    tag as hashtag,
    + IF(tag = _pattern, 100, 0)
    + IF(tag LIKE concat(_pattern, "%"), 50, 0)
    + IF(tag LIKE concat("%", _pattern, "%"), 50, 0) AS score
    FROM layout HAVING  score > 30
    ORDER BY score DESC, mtime ASC LIMIT _offset, _range;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `layout_status` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `layout_status`(
   IN _id      VARBINARY(16),
   IN _status  VARCHAR(16)
)
BEGIN
   UPDATE layout SET status=_status WHERE id=_id;
   SELECT *, tag as hashtag FROM layout WHERE id=_id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `layout_store` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `layout_store`(
   IN _id       VARCHAR(16),
   IN _tagIn    VARCHAR(512),
   IN _author     VARBINARY(16),
   IN _lang      VARCHAR(20),
   IN _comment    TEXT,
   IN _context    VARCHAR(16),
   IN _content       MEDIUMTEXT,
   IN _device     VARCHAR(16),
   IN _vesrion    VARCHAR(16)
)
BEGIN
   UPDATE layout SET content=_content,
     status='active',
     tag = _tagIn,
     hash = layout_ident(_tagIn, _lang, _device),
     author = _author,
     lang = _lang,
     context = _context,
     backup =_content,
     device = _device
   WHERE id=_id;
   SELECT *, tag as hashtag FROM layout WHERE id=_id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `layout_update` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `layout_update`(
   IN _id      VARCHAR(16),
   IN _tag     VARCHAR(512),
   IN _author  VARCHAR(160),
   IN _lang    VARCHAR(20),
   IN _device  VARCHAR(20),
   IN _comment TEXT
)
BEGIN
   DECLARE _mtime INT(11) DEFAULT 0;
   DECLARE _url_key   VARCHAR(1000) DEFAULT '';
   SELECT UNIX_TIMESTAMP() INTO _mtime;
   UPDATE layout SET hash=layout_ident(_tag, _lang, _device),  tag=_tag,
     author=_author, comment=_comment, mtime=_mtime WHERE id=_id;
   SELECT
     *,
     @vhost AS vhost,
     tag as hashtag
   FROM layout WHERE id=_id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `list_media_comments` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `list_media_comments`(
  IN _media_id VARBINARY(16),
  IN _page TINYINT(8)
)
BEGIN

  DECLARE _range bigint;
  DECLARE _offset bigint;
  CALL pageToLimits(_page, _offset, _range);

  SELECT
    comment.id AS id,
    ref_id     AS ref_id,
    origin_id  as oid,
    author_id  as author_id,
    content as comment,
    create_time as ctime,
    publish_time as ptime,
    edit_time as mtime,
    rating,
    firstname,
    lastname,
    if((UNIX_TIMESTAMP() - connexion_time)<120, 'on', 'off') as online,
    status
  FROM yp.drumate join comment on author_id=drumate.id WHERE ref_id=_media_id
  ORDER BY ptime DESC LIMIT _offset, _range;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `log_show_backup` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `log_show_backup`(
 IN _page TINYINT(4)
)
BEGIN

  DECLARE _is_admin int(10);
  DECLARE _range bigint;
  DECLARE _offset bigint;
    
  CALL pageToLimits(_page, _offset, _range);


   SELECT * FROM action_log WHERE action='backup'
   ORDER BY ctime ASC LIMIT _offset, _range;  

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `lookup_hubers` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `lookup_hubers`(
  IN _name   VARCHAR(255),
  IN _page         INT(4)
)
BEGIN
  DECLARE _range int(6);
  DECLARE _offset int(6);
  DECLARE _count int(6);
  DECLARE _hub_id VARCHAR(16);
  DECLARE _p int(4);

  CALL pageToLimits(_page, _offset, _range);

  SELECT 
    _page as `page`,
    d.id, 
    permission AS privilege,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(d.profile, '$.firstname')), ''))AS firstname,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(d.profile, '$.lastname')), '')) AS lastname,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(d.profile, '$.email')), '')) AS email,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(d.profile, '$.mobile')), '')) AS mobile,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(d.profile, '$.address')), '')) AS address,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(d.profile, '$.city.content')), IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.city')), ''))) AS city,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(d.profile, '$.country.content')), IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.country')), ''))) AS country,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(d.profile, '$.country.value')), IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.country')), ''))) AS country_code,
    permission.ctime, 
    permission.utime, 
    IF(expiry_time > 0, expiry_time - UNIX_TIMESTAMP(), 0) AS ttl
    FROM permission LEFT JOIN yp.drumate d ON entity_id=d.id 
    WHERE d.id IS NOT NULL AND (
      firstname LIKE CONCAT("%", _name, "%") OR       
      lastname LIKE CONCAT("%", _name, "%") OR       
      mobile LIKE CONCAT("%", _name, "%") OR      
      email LIKE CONCAT("%", _name, "%")       
    )
    ORDER BY firstname ASC LIMIT _offset, _range;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `map_ticket_add` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `map_ticket_add`(
  IN _message_id VARCHAR(16),
  IN _ticket_id  int(11) 
  )
BEGIN
  INSERT INTO map_ticket(message_id,ticket_id)
  SELECT _message_id, _ticket_id;
  UPDATE yp.ticket SET utime = UNIX_TIMESTAMP() WHERE ticket_id =_ticket_id;
  SELECT *  FROM map_ticket WHERE message_id =_message_id;  
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mediaEnv` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mediaEnv`(
  OUT _vhost VARCHAR(255),
  OUT _hub_id VARCHAR(16), 
  OUT _area VARCHAR(25),
  OUT _home_dir VARCHAR(512),
  OUT _home_id VARCHAR(16),
  OUT _db_name VARCHAR(50),
  OUT _accessibility VARCHAR(16)
)
BEGIN
  DECLARE _domain VARCHAR(512);
  
  SELECT d.name FROM yp.domain d INNER JOIN 
    yp.entity e ON e.dom_id=d.id WHERE db_name=database() INTO _domain;
  SELECT IFNULL(fqdn, _domain), e.id, area, home_dir, db_name, accessibility, home_id
  FROM yp.entity e INNER JOIN yp.vhost v ON e.id=v.id WHERE db_name=database() LIMIT 1
  INTO _vhost, _hub_id, _area, _home_dir, _db_name, _accessibility, _home_id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `media_search` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `media_search`(
  IN _pattern VARCHAR(84),
  IN _page TINYINT(4)
)
BEGIN

  DECLARE _range bigint;
  DECLARE _offset bigint;
  DECLARE _finished       INTEGER DEFAULT 0; 
  DECLARE _nid VARCHAR(16);   
  DECLARE _uid VARCHAR(16);
  DECLARE _db_name VARCHAR(50);
  DECLARE _sys_id INT;
  DECLARE _temp_sys_id INT;
  DECLARE _db VARCHAR(400);

  CALL pageToLimits(_page, _offset, _range);


  
  SELECT id FROM yp.entity where db_name = DATABASE() INTO _uid;   

  DROP TABLE IF EXISTS _search_node;
  CREATE TEMPORARY TABLE _search_node  AS     
  SELECT  
    m.id  as nid,
    m.parent_id AS parent_id,
    m.extension as ext,
    m.origin_id  AS origin_id,
    filepath(m.id) as filepath,
    cast( he.db_name    as VARCHAR(5000))AS hub_db_name, 
    COALESCE(he.id,me.id) AS hub_id,
    cast(null   as VARCHAR(5000))AS hub_name ,
    COALESCE(he.status,m.status) AS status,
    COALESCE(hh.name,m.user_filename) AS filename,
    COALESCE(me.space,m.filesize) AS filesize,
    _uid AS oid,
    ff.capability,
    IF(m.category='hub', he.area, me.area) AS area,
    m.category as filetype,
    null firstname,
    null lastname,
    caption,
    upload_time as mtime,
    publish_time as ctime,
    download_count as views,
    IF(COALESCE(hh.name,m.user_filename) = _pattern, 100, 0)
    + IF(COALESCE(hh.name,m.user_filename) LIKE concat("%", _pattern, "%"), 50, 0) AS score,
    user_expiry(_uid, m.id ) expiry_time,
    user_permission(_uid, m.id ) privilege
    FROM media m  
    INNER JOIN yp.entity me  ON me.db_name=database()
    LEFT JOIN yp.filecap ff ON m.extension=ff.extension
    LEFT JOIN yp.entity he ON m.id = he.id AND m.category='hub'
    LEFT JOIN yp.hub hh ON m.id = hh.id AND m.category='hub'
    
    WHERE  m.status IN ('active', 'locked')  AND
    m.file_path not REGEXP '^/__(chat|trash)__'  AND
    m.`status` != 'hidden' 
    HAVING  score > 25 AND privilege > 0  AND
    (expiry_time = 0 OR expiry_time > UNIX_TIMESTAMP());

    ALTER TABLE _search_node ADD sys_id INT PRIMARY KEY AUTO_INCREMENT;

    SELECT sys_id, IF(filetype = 'hub', hub_db_name, null), IF(filetype = 'hub', nid, null) 
    FROM _search_node WHERE sys_id > 0  AND  (hub_db_name is not null) ORDER BY sys_id ASC LIMIT 1 
    INTO _sys_id , _db, _nid;

    WHILE _sys_id <> 0 DO

        SET @perm = 0;
        SET @resexpiry = NULL;
        SET @s = CONCAT("SELECT ",
          _db,".user_permission (?, ?) INTO @perm"
        );
        PREPARE stmt FROM @s;
        EXECUTE stmt USING _uid, _nid;
        DEALLOCATE PREPARE stmt; 

        
        SET @resexpiry = null;    
        SET @s = CONCAT("SELECT ",
          _db,".user_expiry (?, ?) INTO @resexpiry"
        );
        PREPARE stmt FROM @s;
        EXECUTE stmt USING _uid, _nid;
        DEALLOCATE PREPARE stmt;

        
        UPDATE _search_node s SET privilege = @perm, expiry_time = @resexpiry  
          WHERE sys_id = _sys_id;
        SELECT _sys_id INTO  _temp_sys_id ;  
        SELECT 0 , NULL INTO  _sys_id, _db ; 

        SELECT IFNULL(sys_id,0), IF(filetype = 'hub', hub_db_name, null), nid 
        FROM _search_node WHERE sys_id >_temp_sys_id AND filetype = 'hub' AND hub_db_name IS NOT NULL ORDER BY sys_id ASC LIMIT 1 
        INTO _sys_id, _db, _nid;

    END WHILE;

    BEGIN
        DECLARE dbcursor CURSOR FOR 
          SELECT db_name , id FROM yp.entity WHERE id IN (
            SELECT id FROM media m INNER JOIN permission p 
              ON p.resource_id = m.id AND m.status='active'
          );
        DECLARE CONTINUE HANDLER FOR NOT FOUND SET _finished = 1;
        OPEN dbcursor;
          STARTLOOP: LOOP
            FETCH dbcursor INTO _db_name , _nid;
            IF _finished = 1 THEN 
                LEAVE STARTLOOP;
            END IF;  

            SELECT NULL INTO @file_path;
            SELECT parent_path(_nid) INTO @parent_path;
            SELECT  name  FROM  yp.hub WHERE id = _nid  INTO @hub_name;
        

            SET @sql = CONCAT("
             INSERT INTO  _search_node 
             SELECT  
              m.id  as nid,
              m.parent_id AS parent_id,
              m.extension as ext,
              m.origin_id  AS origin_id,
              CONCAT (  @parent_path , @hub_name, ", _db_name,".filepath(m.id))  as filepath,
              null,
              COALESCE(he.id,me.id) AS hub_id,
              @hub_name hub_name,  
              COALESCE(he.status,m.status) AS status,
              COALESCE(hh.name,m.user_filename) AS filename,
              COALESCE(me.space,m.filesize) AS filesize,
              ? AS oid,
              ff.capability,
              IF(m.category='hub', he.area, me.area) AS area,
              m.category as filetype,
              null firstname,
              null lastname,
              caption,
              upload_time as ctime,
              publish_time as mtime,
              download_count as views,
              IF(COALESCE(hh.name,m.user_filename) = ",QUOTE(_pattern),", 100, 0)
              + IF(COALESCE(hh.name,m.user_filename) LIKE concat('%',",QUOTE( _pattern) ,", '%'), 50, 0) AS score,
              ", _db_name,".user_expiry(?, m.id ) expiry_time,
              ", _db_name,".user_permission(?, m.id ) privilege,
              NULL  
              FROM ", _db_name,".media m  
              INNER JOIN yp.entity me  ON me.db_name=",QUOTE(_db_name)," 
              LEFT JOIN yp.filecap ff ON m.extension=ff.extension
              LEFT JOIN yp.entity he ON m.id = he.id AND m.category='hub'
              LEFT JOIN yp.hub hh ON m.id = hh.id AND m.category='hub'
              -- INNER JOIN yp.drumate d  ON m.origin_id=d.id 
              WHERE  m.status IN ('active', 'locked') AND
              m.file_path not REGEXP '^/__(chat|trash)__'  AND
              m.`status` != 'hidden' 
              HAVING  score > 25 AND privilege > 0  AND
              (expiry_time = 0 OR expiry_time > UNIX_TIMESTAMP())
          ");

          PREPARE stmt FROM @sql;
          EXECUTE stmt USING _uid,_uid,_uid;
          DEALLOCATE PREPARE stmt;   
          END LOOP STARTLOOP;   
        CLOSE dbcursor;
    END;  
             
    SELECT * FROM _search_node WHERE (expiry_time = 0 OR expiry_time > UNIX_TIMESTAMP())
    ORDER BY score DESC, mtime ASC LIMIT _offset, _range;
    DROP TABLE IF EXISTS _search_node;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `members_set_privilege` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `members_set_privilege`(
  IN _privilege INT(4)
)
BEGIN
  DECLARE _db_name VARCHAR(30);
  DECLARE _hub_id VARCHAR(16);
  DECLARE _finished INTEGER DEFAULT 0;


  
  SELECT id FROM yp.entity WHERE db_name=DATABASE() INTO _hub_id;

  DROP TABLE IF EXISTS  _mid_tmp;  
  CREATE TEMPORARY TABLE `_mid_tmp` (db_name   VARCHAR(50));
  INSERT INTO _mid_tmp SELECT db_name FROM permission 
    LEFT JOIN yp.entity e ON entity_id=e.id WHERE permission < 31;

  BEGIN 
    DECLARE dbcursor CURSOR FOR SELECT db_name FROM _mid_tmp;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET _finished = 1;
    OPEN dbcursor;
    WHILE NOT _finished DO 
      FETCH dbcursor INTO _db_name;
      IF _db_name IS NOT NULL THEN 
        SET @s = CONCAT(
          "UPDATE `" ,_db_name,"`.permission SET permission=",_privilege, 
          ", utime = UNIX_TIMESTAMP() WHERE resource_id=", QUOTE(_hub_id));
        PREPARE stmt FROM @s;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
        
      END IF;
    END WHILE;
  END;
  UPDATE permission SET permission=_privilege, utime = UNIX_TIMESTAMP()
    WHERE resource_id='*' AND permission < 31; 

  SELECT 
    p.entity_id AS uid,
    d.firstname,
    JSON_UNQUOTE(JSON_EXTRACT(d.profile, '$.email')) AS email,permission as privilege,
    d.lastname
  FROM permission p INNER JOIN (yp.drumate d) ON 
    p.entity_id=d.id;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `member_show_privilege` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `member_show_privilege`(
  _uid VARCHAR(16)
)
BEGIN
  DECLARE _range int(6);
  DECLARE _offset int(6);
  DECLARE _count int(6);
  DECLARE _hub_id VARCHAR(16);
  DECLARE _p int(4);


  SELECT drumate.id, 
    permission AS privilege,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.firstname')), ''))AS firstname,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.lastname')), '')) AS lastname,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.email')), '')) AS email,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.mobile')), '')) AS mobile,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.address')), '')) AS address,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.city.content')), IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.city')), ''))) AS city,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.country.content')), IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.country')), ''))) AS country,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.country.value')), IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.country')), ''))) AS country_code,
    permission.ctime, 
    permission.utime, 
    IF(expiry_time > 0, expiry_time - UNIX_TIMESTAMP(), 0) AS ttl,
    _count as total
    FROM permission LEFT JOIN yp.drumate ON entity_id=drumate.id 
    WHERE entity_id = _uid and resource_id='*';
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `message_id` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `message_id`()
BEGIN
    SELECT  yp.uniqueId() as id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_access_node` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_access_node`(
  IN _uid VARCHAR(500) CHARACTER SET ascii,
  IN _node_id VARCHAR(1000) CHARACTER SET ascii
)
BEGIN

  DECLARE _area VARCHAR(25);
  DECLARE _vhost VARCHAR(255);
  DECLARE _home_dir VARCHAR(500);
  DECLARE _hub_id VARCHAR(16) CHARACTER SET ascii ;
  DECLARE _dom_id VARCHAR(16);
  DECLARE _home_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _parent_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _db_name VARCHAR(50);
  DECLARE _hub_name VARCHAR(150);
  DECLARE _hub_db VARCHAR(150);
  DECLARE _actual_home_id VARCHAR(150) CHARACTER SET ascii DEFAULT NULL;
  DECLARE _actual_hub_id VARCHAR(150) CHARACTER SET ascii DEFAULT NULL;
  DECLARE _actual_db VARCHAR(150) DEFAULT NULL;
  DECLARE _remit TINYINT(4) DEFAULT 0;
  DECLARE _perm TINYINT(2) DEFAULT 0;
  DECLARE _root_hub_id VARCHAR(16) CHARACTER SET ascii ;
  DECLARE _user_db_name VARCHAR(255);
  DECLARE _src_db_name VARCHAR(255);

  SELECT database() INTO _src_db_name;
  SELECT  h.id FROM yp.hub h INNER JOIN yp.entity e on e.id = h.id WHERE db_name=_src_db_name INTO _root_hub_id;
  SELECT '' INTO @xhub_name;
  

  IF _root_hub_id IS NOT NULL THEN
    SELECT db_name FROM yp.entity WHERE id = _uid INTO _user_db_name;
    IF _user_db_name IS NOT NULL THEN 
      SET @s = CONCAT("SELECT ", _user_db_name, ".filepath(?) INTO @xhub_name");
      PREPARE stmt FROM @s;
      EXECUTE stmt USING _root_hub_id;
      DEALLOCATE PREPARE stmt;
    END IF;
  END IF;

  IF _node_id REGEXP ".*/.*" THEN 
    SELECT id FROM media WHERE file_path=_node_id INTO _node_id;
  END IF;

  SELECT 
    COALESCE(h.id, dr.id) AS id,
    e.home_id,
    e.home_dir,
    d.id,
    e.area,
    v.fqdn  AS vhost,
    e.db_name 
  FROM yp.entity e
    INNER JOIN yp.domain d ON d.id = e.dom_id
    LEFT JOIN yp.vhost v ON v.id = e.id
    LEFT JOIN yp.entity dr ON e.id = dr.id AND e.area='personal'
    LEFT JOIN yp.entity h ON e.id = h.id AND e.area IN('private', 'public', 'share','dmz','restricted')
  WHERE e.db_name = database() GROUP BY (id) LIMIT 1
  INTO 
    _hub_id, 
    _home_id, 
    _home_dir,
    _dom_id, 
    _area,
    _vhost,
    _db_name;

  SELECT IFNULL(privilege, 0) FROM yp.privilege WHERE  domain_id = _dom_id AND  `uid`=_uid
    INTO _remit;

  SELECT 
    COALESCE(h.name, dr.fullname) AS `name`,
    IFNULL(e.area, _area), 
    IFNULL(e.home_id, _home_id), 
    IFNULL(e.id, _hub_id),
    IFNULL(e.db_name, _db_name)
  FROM yp.entity e 
    LEFT JOIN yp.drumate dr ON e.id = dr.id AND e.type='drumate'
    LEFT JOIN yp.hub h ON e.id = h.id 
    WHERE e.id=_node_id 
  INTO 
    _hub_name, 
    _area,
    _actual_home_id, 
    _actual_hub_id,
    _actual_db;
  SELECT user_permission(_uid, _node_id) INTO _perm;

  SELECT
    m.id,
    m.id  AS nid,
    IFNULL(_actual_home_id, _home_id) AS actual_home_id, 
    IFNULL(_actual_hub_id, _hub_id) AS actual_hub_id,
    IFNULL(_actual_db, _db_name) AS actual_db,
    _db_name AS db_name,
    concat(_home_dir, "/__storage__/") AS mfs_root,
    concat(_home_dir, "/__storage__/") AS home_dir,
    parent_id AS pid,
    parent_id AS parent_id,
    _hub_id AS hub_id,
    _vhost AS vhost,
    caption,
    _area AS accessibility,
    _area AS area,
    _home_id AS home_id,
    capability,
    m.status AS status,
    m.extension,
    m.extension AS ext,
    COALESCE(fc.category, m.category) ftype,
    COALESCE(fc.category, m.category) filetype,
    COALESCE(fc.mimetype, m.mimetype) mimetype,
    isalink,
    JSON_VALUE(m.metadata, "$.md5Hash") AS md5Hash,
    IF(m.isalink =1 AND m.category NOT IN ('hub'), JSON_VALUE(m.metadata, "$.target.nid"), NULL) target_nid , 
    IF(m.isalink =1 AND m.category NOT IN ('hub'), JSON_VALUE(m.metadata, "$.target.hub_id"), NULL)  target_hub_id, 
    IF(m.isalink =1 AND m.category NOT IN ('hub'), JSON_VALUE(m.metadata, "$.target.mfs_root"), NULL)  target_mfs_root, 
    _perm  as permission,
    _perm  as privilege,
    download_count AS view_count,
    m.metadata metadata,
    geometry,
    upload_time AS ctime,
    publish_time AS mtime,
    CASE 
      WHEN m.category='hub' THEN _hub_name
      WHEN m.parent_id='0' THEN _hub_name
      ELSE user_filename
    END AS filename,
    parent_path,
    CONCAT(@xhub_name, file_path) as file_path,
    REGEXP_REPLACE(CONCAT(@xhub_name, file_path), '/+', '/') as filepath,
    REGEXP_REPLACE(file_path, '/+', '/') as ownpath,
    filesize,
    firstname,
    lastname,
    _remit AS remit
  FROM  media m LEFT JOIN (yp.filecap fc, yp.drumate) 
  ON m.extension=fc.extension AND origin_id=drumate.id 
  WHERE m.id=_node_id
UNION ALL
  SELECT
    m.id,
    m.id  AS nid,
    IFNULL(_actual_home_id, _home_id) AS actual_home_id, 
    IFNULL(_actual_hub_id, _hub_id) AS actual_hub_id,
    IFNULL(_actual_db, _db_name) AS actual_db,
    _db_name AS db_name,
    concat(_home_dir, "/__storage__/") AS mfs_root,
    concat(_home_dir, "/__storage__/") AS home_dir,
    parent_id AS pid,
    parent_id AS parent_id,
    _hub_id AS hub_id,
    _vhost AS vhost,
    caption,
    _area AS accessibility,
    _area AS area,
    _home_id AS home_id,
    capability,
    m.status AS status,
    m.extension,
    m.extension AS ext,
    COALESCE(fc.category, m.category) ftype,
    COALESCE(fc.category, m.category) filetype,
    COALESCE(fc.mimetype, m.mimetype) mimetype,
    isalink,
    JSON_VALUE(m.metadata, "$.md5Hash") AS md5Hash,
    IF(m.isalink =1 AND m.category NOT IN ('hub'), JSON_VALUE(m.metadata, "$.target.nid"), NULL) target_nid , 
    IF(m.isalink =1 AND m.category NOT IN ('hub'), JSON_VALUE(m.metadata, "$.target.hub_id"), NULL)  target_hub_id, 
    IF(m.isalink =1 AND m.category NOT IN ('hub'), JSON_VALUE(m.metadata, "$.target.mfs_root"), NULL)  target_mfs_root, 
    _perm AS permission,
    _perm AS privilege,
    download_count AS view_count,
    m.metadata metadata,
    geometry,
    upload_time AS ctime,
    publish_time AS mtime,
    CASE 
      WHEN m.category='hub' THEN _hub_name
      WHEN m.parent_id='0' THEN _hub_name
      ELSE user_filename
    END AS filename,
    parent_path,
    CONCAT(@xhub_name, file_path) as file_path,
    REGEXP_REPLACE(CONCAT(@xhub_name, file_path), '/+', '/') AS filepath,
    IF(COALESCE(fc.category, m.category) = 'hub', '/', REGEXP_REPLACE(file_path, '/+', '/')) AS ownpath,
    filesize,
    firstname,
    lastname,
    _remit AS remit
  FROM  trash_media m LEFT JOIN (yp.filecap fc, yp.drumate) 
  ON m.extension=fc.extension AND origin_id=drumate.id 
  WHERE m.id=_node_id;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_add_comment` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_add_comment`(
  IN _ref_id          VARBINARY(16),
  IN _hub_id        VARBINARY(16),
  IN _author_id       VARBINARY(16),
  IN _content         MEDIUMTEXT,
  IN _editable        TINYINT(4),
  IN _rating          DOUBLE,
  IN _lang            VARCHAR(16),
  IN _ext_data        MEDIUMTEXT,
  IN _status          VARCHAR(50),
  IN _version         INT(10) UNSIGNED
)
BEGIN
  DECLARE _id   VARBINARY(16) DEFAULT '';
  DECLARE _ts   INT(11) DEFAULT 0;
  DECLARE _last INT(11) DEFAULT 0;

  SELECT UNIX_TIMESTAMP() INTO _ts;
  SELECT yp.uniqueId() INTO _id;
  INSERT INTO `comment` (id, ref_id, owner_id, author_id, content, create_time, publish_time,
    edit_time, editable, rating, lang, ext_data, `status`, `version`)
    VALUES (_id, _ref_id, _hub_id, _author_id, _content, _ts, _ts, _ts, _editable,
    _rating, _lang, _ext_data, _status, _version);
  SELECT LAST_INSERT_ID() INTO _last;

  SELECT * FROM comment WHERE sys_id = _last;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_attachment_remove` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_attachment_remove`(
  IN _nid VARCHAR(16) 
)
BEGIN
  SELECT * FROM media WHERE file_path  REGEXP '^/__chat__' AND  id = _nid; 
  DELETE FROM media WHERE file_path  REGEXP '^/__chat__' AND id = _nid; 
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_available_folder` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_available_folder`(
  IN _nid VARCHAR(16),
  IN _fname VARCHAR(256)

)
    DETERMINISTIC
BEGIN

  DECLARE _id VARCHAR(16);
  SELECT id FROM media WHERE parent_id=_nid AND user_filename=_fname INTO _id;

  IF _id='' OR _id IS NULL THEN
    SELECT _fname AS filename, 'available' AS status, 1 AS active;
  ELSE
    SELECT _fname AS filename, 'unavailable' AS status, 0 AS active;
  END IF;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_browse` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_browse`(
  IN _node_id VARCHAR(16),
  IN _cat VARCHAR(32),
  IN _page TINYINT(4)
)
BEGIN

  DECLARE _range bigint;
  DECLARE _offset bigint;
  CALL pageToLimits(_page, _offset, _range);

  IF _cat='files' OR _cat='' THEN
     SELECT
       media.id  AS nid,
       parent_id AS pid,
       parent_id AS parent_id,
       origin_id AS gid,
       caption,
       media.status AS status,
       extension AS ext,
       media.category AS ftype,
       media.category AS filetype,
       mimetype,
       download_count AS view_count,
       IF(parent_id='0', 'root', 'branch') as npos,
       geometry,
       upload_time AS ctime,
       publish_time AS ptime,
       user_filename AS filename,
       parent_path,
       IF(parent_path='' or parent_path is NULL , '/', parent_path) AS user_path,
       file_path,
       filesize,
       firstname,
       lastname,
       remit,
       _page as page,
       concat(@root, file_path) AS file_path,
       @area as area
     FROM  media inner join yp.drumate on origin_id=drumate.id
     WHERE parent_id=_node_id
     ORDER BY ctime DESC LIMIT _offset, _range;
  ELSE
     SELECT
       media.id  AS nid,
       parent_id AS pid,
       parent_id AS parent_id,
       origin_id AS gid,
       caption,
       media.status AS status,
       extension AS ext,
       media.category AS ftype,
       media.category AS filetype,
       mimetype,
       download_count AS view_count,
       IF(parent_id='0', 'root', 'branch') as npos,
       geometry,
       upload_time AS ctime,
       publish_time AS ptime,
       user_filename AS filename,
       parent_path,
       IF(parent_path='' or parent_path is NULL , '/', parent_path) AS user_path,
       file_path,
       filesize,
       firstname,
       lastname,
       remit,
       _page as page,
       concat(@root, file_path) AS file_path,
       @area as area
     FROM  media inner join yp.drumate on origin_id=drumate.id
     WHERE (media.category=_cat OR media.category='folder') AND parent_id=_node_id
     ORDER BY ctime DESC LIMIT _offset, _range;
  END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_browse_asc` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_browse_asc`(
  IN _node_id VARCHAR(16),
  IN _cat VARCHAR(32),
  IN _page TINYINT(4)
)
BEGIN

  DECLARE _range bigint;
  DECLARE _offset bigint;
  CALL pageToLimits(_page, _offset, _range);

  IF _cat='files' OR _cat='' THEN
     SELECT
       media.id  AS nid,
       parent_id AS pid,
       parent_id AS parent_id,
       origin_id AS gid,
       caption,
       media.status AS status,
       extension AS ext,
       media.category AS ftype,
       media.category AS filetype,
       mimetype,
       download_count AS view_count,
       IF(parent_id='0', 'root', 'branch') as npos,
       geometry,
       upload_time AS ctime,
       publish_time AS ptime,
       user_filename AS filename,
       parent_path,
       IF(parent_path='' or parent_path is NULL , '/', parent_path) AS user_path,
       file_path,
       filesize,
       firstname,
       lastname,
       gender,
       remit,
       _page as page,
       concat(@root, file_path) AS file_path,
       @area as area
     FROM  media inner join yp.drumate on origin_id=drumate.id
     WHERE parent_id=_node_id
     ORDER BY ctime ASC LIMIT _offset, _range;
  ELSE
     SELECT
       media.id  AS nid,
       parent_id AS pid,
       parent_id AS parent_id,
       origin_id AS gid,
       caption,
       media.status AS status,
       extension AS ext,
       media.category AS ftype,
       media.category AS filetype,
       mimetype,
       download_count AS view_count,
       IF(parent_id='0', 'root', 'branch') as npos,
       geometry,
       upload_time AS ctime,
       publish_time AS ptime,
       user_filename AS filename,
       parent_path,
       IF(parent_path='' or parent_path is NULL , '/', parent_path) AS user_path,
       file_path,
       filesize,
       firstname,
       lastname,
       gender,
       remit,
       _page as page,
       concat(@root, file_path) AS file_path,
       @area as area
     FROM  media inner join yp.drumate on origin_id=drumate.id
     WHERE (media.category=_cat OR media.category='folder') AND parent_id=_node_id
     ORDER BY ctime ASC LIMIT _offset, _range;
  END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_check_consistency` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_check_consistency`(
)
BEGIN
 UPDATE media m LEFT JOIN yp.entity e USING(id) 
   SET m.status= 'orphaned' WHERE category='hub' AND e.id IS NULL;
 DELETE FROM media WHERE STATUS = 'orphaned';

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_child_is_exist` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_child_is_exist`(
  IN _src_id VARCHAR(16),
  IN _dest_pid VARCHAR(16),
  IN _des_entity_id VARCHAR(16)
  )
BEGIN
  DECLARE _id varchar(16);
  DECLARE _temp_filename varchar(1024);
  DECLARE _lvl int;
  DECLARE _des_db   VARCHAR(255);

  
  SELECT db_name from yp.entity WHERE id=_des_entity_id INTO _des_db;

    DROP TABLE IF EXISTS  _src_media;
    CREATE TEMPORARY TABLE `_src_media` (
    `id` varchar(16) DEFAULT NULL,
    `file_path` varchar(512) DEFAULT NULL,
    `user_filename` varchar(128) DEFAULT NULL,
    `parent_id` varchar(16) NOT NULL DEFAULT '',
    `parent_path` varchar(1024) NOT NULL,
    `category`  varchar(16) NOT NULL,
    `is_checked` boolean default 0,
    `relative_path` varchar(1024) NOT NULL,
    `lvl` int default 0
    );

    DROP TABLE IF EXISTS  _des_media;
    CREATE TEMPORARY TABLE `_des_media` as select * from _src_media where 1=2;
    
    
    
    
    INSERT INTO _src_media (id,file_path,user_filename,parent_id,parent_path,category,
    is_checked,relative_path,lvl)
    SELECT id,file_path,user_filename,parent_id ,parent_path,category,
    0, user_filename,0
    FROM media m WHERE m.id =_src_id;
   
    SELECT  id ,relative_path ,lvl FROM _src_media WHERE is_checked =0 LIMIT 1 INTO _id ,_temp_filename  ,_lvl;
    SET  _temp_filename =IFNULL(_temp_filename,'''');

    WHILE _id is not null DO
     
        INSERT INTO _src_media (id,file_path,user_filename,parent_id ,parent_path,category,
        is_checked,relative_path,lvl)
        SELECT  
          id,file_path,user_filename,parent_id,parent_path,category,
          0,CONCAT(_temp_filename,'/',user_filename ) ,_lvl+1
        FROM media WHERE  parent_id =_id;
        
        UPDATE _src_media SET is_checked = 1 WHERE id = _id;
        SELECT NULL INTO _id;
        SELECT id ,relative_path ,lvl FROM _src_media WHERE is_checked =0 LIMIT 1 INTO _id,_temp_filename ,_lvl ;
        SET  _temp_filename =IFNULL(_temp_filename,'''');
    END WHILE;



    
    SELECT NULL,NULL INTO _id,_temp_filename;
    SET @sql = CONCAT('
    INSERT INTO _des_media 
      (id,file_path,user_filename,parent_id ,parent_path,category,
      is_checked,relative_path,lvl)
    SELECT
      m.id,m.file_path,m.user_filename,m.parent_id ,m.parent_path,m.category,
      0, m.user_filename,0
    FROM ' ,_des_db ,'.media m
    WHERE 
      parent_id =''', _dest_pid ,''' AND 
      category = ''folder'' AND 
      user_filename  = ( SELECT  user_filename  FROM _src_media sm WHERE sm.id =''', _src_id,''')');

    PREPARE stmt FROM @sql ;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

  
    SELECT  id ,relative_path,lvl FROM _des_media WHERE is_checked =0 LIMIT 1 INTO _id ,_temp_filename,_lvl; 
    SET  _temp_filename =IFNULL(_temp_filename,'''');

    WHILE _id is not null DO
         SET @sql = CONCAT('
        INSERT INTO _des_media (id,file_path,user_filename,parent_id ,parent_path,category,
        is_checked,relative_path,lvl)
        SELECT  
          id,file_path,user_filename,parent_id,parent_path,category,
          0,','CONCAT(''',_temp_filename,''',''/'',user_filename ) ,',_lvl+1,
                ' FROM ' ,_des_db,'.media WHERE  parent_id =''',_id,'''');
        PREPARE stmt FROM @sql ;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
        UPDATE _des_media SET is_checked = 1 WHERE id = _id;
        SELECT NULL INTO _id;
        SELECT id ,relative_path,lvl FROM _des_media WHERE is_checked =0 LIMIT 1 INTO _id,_temp_filename,_lvl ;
        SET  _temp_filename =IFNULL(_temp_filename,'''');
    END WHILE;
    
    
    SELECT EXISTS
      (SELECT 1
      FROM _src_media s
      INNER JOIN _des_media d ON 
        s.relative_path = d.relative_path AND 
        s.category=d.category and s.lvl>0) status;
    
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_chk_circular_ref` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_chk_circular_ref`(
  IN _nodes MEDIUMTEXT,
  IN _uid VARCHAR(16),
  IN _dest_id VARCHAR(16),
  IN _recipient_id VARCHAR(16)
)
BEGIN
  DECLARE  _idx INT(4) DEFAULT 0; 
  DECLARE  _nid VARCHAR(16);
  DECLARE  _hub_id VARCHAR(16);
  DECLARE  _hub_db VARCHAR(40);
  DECLARE  _home_dir VARCHAR(512);
  DECLARE  _dest_db VARCHAR(40);
  DECLARE _dest_home_dir VARCHAR(512);

  DROP TABLE IF EXISTS  _src_tree_media;
  CREATE TEMPORARY TABLE _src_tree_media (
    `id`              varchar(16) NOT NULL,
    `parent_id`       varchar(16) DEFAULT NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8;


  SELECT db_name,home_dir FROM yp.entity WHERE id=_recipient_id INTO _dest_db,_dest_home_dir;

  WHILE _idx < JSON_LENGTH(_nodes) DO 
    SELECT JSON_UNQUOTE(JSON_EXTRACT(_nodes, CONCAT("$[", _idx, "]"))) INTO @_node;
    SELECT JSON_UNQUOTE(JSON_EXTRACT(@_node, "$.nid")) INTO _nid;
    SELECT JSON_UNQUOTE(JSON_EXTRACT(@_node, "$.hub_id")) INTO _hub_id;

    SELECT db_name,home_dir FROM yp.entity WHERE id=_hub_id INTO _hub_db ,_home_dir;

    SET @streg = CONCAT("
      INSERT INTO _src_tree_media  WITH RECURSIVE mytree AS (
        SELECT  id,  parent_id
        FROM " , _hub_db ,".media  WHERE id = ?
        UNION 
        SELECT m.id,m.parent_id
        FROM " , _hub_db ,".media  m JOIN mytree t ON m.parent_id = t.id AND m.category <> 'hub'
      )
      SELECT 
        *
      FROM mytree;
    ");
    PREPARE stamtreg FROM @streg;
    EXECUTE stamtreg USING _nid;
    DEALLOCATE PREPARE stamtreg;
    SELECT _idx + 1 INTO _idx;
  END WHILE; 

  SELECT * from _src_tree_media where id =_dest_id ;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_chk_pre_trash` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_chk_pre_trash`(
  IN _nodes JSON,
  IN _uid VARCHAR(16) CHARACTER SET ascii,
  IN _modify_perm TINYINT(4)
)
BEGIN

  DECLARE _idx INT DEFAULT 0; 
  DECLARE _nid VARCHAR(16);
  DECLARE _shub_id VARCHAR(16);
  DECLARE _shub_db VARCHAR(40);

 
  DROP TABLE IF EXISTS `_mytree`; 
  CREATE  TEMPORARY TABLE `_mytree` (
          id varchar(16)  CHARACTER SET ascii DEFAULT NULL,
          parent_id varchar(16)  CHARACTER SET ascii DEFAULT NULL,
          category varchar(16) DEFAULT NULL
          );


  WHILE _idx < JSON_LENGTH(_nodes) DO 

        SELECT JSON_UNQUOTE(JSON_EXTRACT(_nodes, CONCAT("$[", _idx, "]"))) INTO @_node;
        SELECT JSON_VALUE(@_node, "$.nid") INTO _nid;
        SELECT JSON_VALUE(@_node, "$.hub_id") INTO _shub_id;
        SELECT db_name FROM yp.entity WHERE id = _shub_id INTO _shub_db; 
   

       
        SET @st = CONCAT
        ( " 
           INSERT INTO _mytree
           WITH RECURSIVE mytree AS (
            SELECT id, parent_id ,category
            FROM ",_shub_db,".media WHERE id =", QUOTE(_nid),"
            UNION ALL
            SELECT m.id, m.parent_id ,m.category
            FROM ",_shub_db,".media AS m JOIN mytree AS t ON m.parent_id = t.id  
          )
         SELECT id, parent_id ,category FROM mytree;");
        PREPARE stmt FROM @st;
        EXECUTE stmt ;
        DEALLOCATE PREPARE stmt; 

      SELECT _idx + 1 INTO _idx;
  END WHILE; 
    SELECT 1 is_hub FROM  _mytree WHERE category = 'hub' limit 1;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_clear_notification` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_clear_notification`(
  IN _id     VARCHAR(16),
  IN _uid    VARCHAR(16),
  IN _show_results BOOLEAN
)
BEGIN
  DECLARE _md JSON;
  DECLARE _cat VARCHAR(100);
  DECLARE _seen INT(11) DEFAULT NULL;
  SELECT metadata, category FROM media WHERE id=_id INTO _md, _cat;
  IF _cat = 'folder' THEN
    DROP TABLE IF EXISTS _innerfile; 
    CREATE TEMPORARY TABLE `_innerfile` (
      seq  int NOT NULL AUTO_INCREMENT,
      id varchar(16) DEFAULT NULL, 
      parent_id varchar(16) DEFAULT NULL, 
      PRIMARY KEY `seq`(`seq`)  
    );
    INSERT INTO _innerfile (id, parent_id) 
      WITH RECURSIVE myfile AS 
      (
        SELECT id, parent_id
          FROM media WHERE id = _id AND file_path not REGEXP '^/__(chat|trash)__' 
        UNION ALL
        SELECT m.id, m.parent_id
          FROM media AS m JOIN myfile AS t ON m.parent_id =t.id 
            WHERE m.parent_id !='0' AND m.file_path not REGEXP '^/__(chat|trash)__' 
      )
    SELECT id, parent_id FROM myfile;
    UPDATE media m INNER JOIN _innerfile ii USING(id) SET 
      metadata=IF(JSON_VALID(metadata), 
        JSON_REPLACE(metadata, CONCAT("$._seen_.", _uid), UNIX_TIMESTAMP()),
        JSON_OBJECT('_seen_', JSON_OBJECT(_uid, UNIX_TIMESTAMP()))
      );

  ELSE   
    IF NOT JSON_VALID(_md) THEN
      UPDATE media SET metadata=JSON_OBJECT('_seen_', JSON_OBJECT(_uid, UNIX_TIMESTAMP())) WHERE id=_id;
    END IF; 
    IF _md IS NULL THEN 
      UPDATE media SET metadata=JSON_OBJECT('_seen_', JSON_OBJECT(_uid, UNIX_TIMESTAMP())) WHERE id=_id;
    END IF;
    IF NOT JSON_EXISTS(_md, CONCAT("$._seen_.", _uid)) THEN 
      UPDATE media SET metadata=JSON_MERGE(metadata, JSON_OBJECT('_seen_', JSON_OBJECT(_uid, UNIX_TIMESTAMP()))) WHERE id=_id;
    ELSE 
      UPDATE media SET metadata=JSON_REPLACE(metadata, CONCAT("$._seen_.", _uid), UNIX_TIMESTAMP()) WHERE id=_id;
    END IF;
    IF _show_results THEN 
      SELECT metadata FROM media WHERE id=_id;
    END IF;
  END IF;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_clear_notifications` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_clear_notifications`(
  IN _nodes  JSON,
  IN _uid    VARCHAR(16)
)
BEGIN
  DECLARE _i INT(8) DEFAULT 0;
  DECLARE _nid VARCHAR(16);

  WHILE _i < JSON_LENGTH(_nodes) DO 
    SELECT get_json_array(_nodes, _i) INTO _nid;
    SELECT _nid;
    CALL mfs_clear_notification(_nid, _uid, 0);
    SET _i = _i + 1;
  END WHILE;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_copy_all` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_copy_all`(
  IN _nodes JSON,
  IN _uid VARCHAR(16),
  IN _dest_id VARCHAR(16),
  IN _recipient_id VARCHAR(16)
)
BEGIN
  DECLARE _idx INT(4) DEFAULT 0; 
  DECLARE _nid VARCHAR(16);
  DECLARE _hub_id VARCHAR(16);
  DECLARE _hub_db VARCHAR(40);
  DECLARE _home_dir VARCHAR(512);
  DECLARE _dest_db VARCHAR(50);
  DECLARE _dest_home_dir VARCHAR(512);
  DECLARE _temp_nid  VARCHAR(16);
  


  DECLARE _origin_id      VARCHAR(16);   
  DECLARE _file_name      VARCHAR(512); 
  DECLARE _category       VARCHAR(50);   
  DECLARE _extension      VARCHAR(100); 
  DECLARE _mimetype       VARCHAR(100);      
  DECLARE _file_size      INT(20) UNSIGNED;
  DECLARE _geometry       VARCHAR(200);       
  DECLARE _status         VARCHAR(50); 
  DECLARE _finished       INTEGER DEFAULT 0;
  DECLARE _seq            INTEGER;  
  DECLARE _id             VARCHAR(16);   
  DECLARE _new_parent_id  VARCHAR(16);  
  DECLARE _metadata       JSON; 
  DECLARE _isalink         tinyint(2) unsigned DEFAULT 0;


  SELECT db_name, home_dir FROM yp.entity 
    WHERE id=_recipient_id INTO _dest_db, _dest_home_dir;

  DROP TABLE IF EXISTS  _src_media;
  CREATE TEMPORARY TABLE `_src_media` (
    `seq`  int NOT NULL AUTO_INCREMENT,
    `is_root` boolean default 0 ,
    `id` varchar(16) DEFAULT NULL,
    `origin_id` varchar(16) DEFAULT NULL,
    `owner_id` varchar(16) DEFAULT NULL,
    `user_filename` varchar(128) DEFAULT NULL,
    `metadata` JSON,
    `isalink`  tinyint(2) unsigned, 
    `category`      VARCHAR(50) DEFAULT NULL,
    `parent_id` varchar(16) DEFAULT null,
    `extension` varchar(100) NOT NULL DEFAULT '',
    `mimetype` varchar(100) NOT NULL,
    `filesize` int(20) unsigned NOT NULL DEFAULT '0',
    `geometry` varchar(200) NOT NULL DEFAULT '0x0',
    `new_id` varchar(16) DEFAULT NULL,  
    `new_parent_id` varchar(16) DEFAULT '' ,
    `is_checked` boolean default 0 ,
    `home_dir` VARCHAR(512) DEFAULT null,
    `db_name` VARCHAR(512) DEFAULT null,
    `hub_id` VARCHAR(16) DEFAULT null,
    PRIMARY KEY `seq`(`seq`)  
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

  DROP TABLE IF EXISTS _final_media; 
  CREATE TEMPORARY TABLE `_final_media` (
    nid varchar(16) DEFAULT NULL,  
    category varchar(50) DEFAULT NULL,  
    src_mfs_root varchar(1024) DEFAULT NULL,  
    src_db varchar(160) DEFAULT NULL,  
    des_id varchar(16) DEFAULT NULL,  
    des_mfs_root varchar(1024) DEFAULT NULL,  
    des_db varchar(160) DEFAULT NULL,  
    action varchar(16) DEFAULT NULL
  );




  WHILE _idx < JSON_LENGTH(_nodes) DO 
    DELETE FROM _src_media;
    
    SELECT get_json_array(_nodes, _idx) INTO @_node;
    SELECT get_json_object(@_node, "nid") INTO _nid;
    SELECT get_json_object(@_node, "hub_id") INTO _hub_id;

    SELECT db_name, home_dir FROM yp.entity WHERE id=_hub_id INTO _hub_db ,_home_dir;
    
    
    SET @st = CONCAT("
      INSERT INTO _src_media SELECT 
      null, 1, id, origin_id, ?, user_filename,metadata,isalink, category, parent_id, 
      extension, mimetype, filesize, geometry, null, null, 0, ?, ?, ? 
      FROM ", _hub_db,".media m  WHERE category <> 'hub' AND m.id =?
    ");  
    PREPARE stmt FROM @st;
    EXECUTE stmt USING _uid, _home_dir, _hub_db, _hub_id, _nid;
    DEALLOCATE PREPARE stmt;

    UPDATE _src_media SET new_parent_id = _dest_id  WHERE  id=_nid; 
    SELECT id FROM _src_media WHERE id = _nid INTO _temp_nid ;

     WHILE _temp_nid IS NOT NULL DO
       
      SELECT seq,id,origin_id,user_filename,metadata, isalink,category,
        extension,mimetype,`geometry`,filesize,new_parent_id 
      FROM _src_media WHERE id =_temp_nid 
      INTO _seq,_id,_origin_id,_file_name,_metadata, _isalink,_category,
        _extension,_mimetype,_geometry,_file_size, _new_parent_id;        
    

      
      IF _category = 'folder' THEN
        SET @st = CONCAT("
          INSERT INTO _src_media SELECT 
          null, 0, id, origin_id, ?, user_filename, null, 0, category, parent_id, extension, 
          mimetype, filesize, geometry, null, null, 0, ?, ?, ?  
          FROM ", _hub_db,".media m WHERE status <> 'hidden' AND  category <> 'hub' AND m.parent_id =?
        ");  
        PREPARE stmt FROM @st;
        EXECUTE stmt USING _uid, _home_dir, _hub_db, _hub_id, _temp_nid;
        DEALLOCATE PREPARE stmt; 
      END IF ;

      SET @args = JSON_OBJECT(
        "owner_id", _uid,
        "origin_id", _origin_id,
        "filename", _file_name,
        "pid", _new_parent_id,
        "category", _category,
        "ext", _extension,
        "mimetype", _mimetype,
        "filesize", _file_size,
        "geometry", _geometry,
        "isalink", _isalink
      );

      SET @results = JSON_OBJECT();
      SET @st = CONCAT("CALL ", _dest_db, ".mfs_create_node(?, ?, @results)");

      PREPARE stmt2 FROM @st;
      EXECUTE stmt2 USING @args, _metadata;
      DEALLOCATE PREPARE stmt2;

      SELECT JSON_VALUE(@results, "$.id") INTO @temp_nid;
      SELECT JSON_VALUE(@results, "$.pid") INTO @pid;

      UPDATE _src_media SET new_id =@temp_nid  WHERE seq =_seq ; 
      UPDATE _src_media SET new_parent_id =  @temp_nid WHERE parent_id = _temp_nid; 
      

      
      UPDATE _src_media SET is_checked = 1 WHERE id = _temp_nid ;
      SELECT NULL,NULL,NULL INTO _temp_nid ,@temp_nid,@pid;
      SELECT id FROM _src_media WHERE is_checked =0 
        AND new_parent_id IS NOT NULL LIMIT 1 INTO _temp_nid ;

     END WHILE;

    SELECT _idx + 1 INTO _idx;
    INSERT INTO _final_media (nid, category, src_db, des_db, `action`)
      SELECT IFNULL(new_id,id), category, _hub_db, _dest_db, 'showone' 
      FROM _src_media WHERE seq=1; 

    INSERT INTO _final_media (nid, category, src_db, des_db, `action`)
      SELECT IFNULL(new_id,id), category, _hub_db, _dest_db, 'show' 
      FROM _src_media WHERE is_root=1;

    INSERT INTO _final_media (nid, category, src_mfs_root, des_id, des_mfs_root, `action`)
      SELECT id, category, CONCAT(home_dir, "/__storage__/"), new_id, CONCAT(_dest_home_dir, "/__storage__/"), 'copy'  
      FROM _src_media WHERE category NOT IN ("folder","hub") ; 
  END WHILE;

  SELECT * FROM _final_media;
  DROP TABLE IF EXISTS `_src_media`;
  DROP TABLE IF EXISTS `_final_media`;


END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_copy_node` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_copy_node`(
  IN _id VARCHAR(100),
  IN _dest_id VARCHAR(16),
  IN _recipient_id VARCHAR(16)
)
BEGIN
  DECLARE _type           VARCHAR(100);
  DECLARE _new_id         VARCHAR(16);
  DECLARE _dest_db        VARCHAR(50);
  
  DECLARE _origin_id      VARCHAR(16);   
  DECLARE _user_filename  VARCHAR(512); 
  DECLARE _category       VARCHAR(50);   
  DECLARE _extension      VARCHAR(100); 
  DECLARE _mimetype       VARCHAR(100);      
  DECLARE _file_size      INT(20) UNSIGNED;
  DECLARE _geometry       VARCHAR(200);       
  DECLARE _status         VARCHAR(50);            

  SELECT category FROM media WHERE id=_dest_id INTO _type;
  SELECT db_name FROM yp.entity WHERE id=_recipient_id OR ident =_recipient_id 
    INTO _dest_db;

  SELECT
    origin_id       ,       
    user_filename   ,   
    category        ,        
    extension       ,       
    mimetype        ,        
    filesize        ,       
    IFNULL(geometry, '0x0'),        
    status                    
  FROM media WHERE id = _id INTO
    _origin_id       ,       
    _user_filename   ,   
    _category        ,        
    _extension       ,       
    _mimetype        ,        
    _file_size       ,       
    _geometry        ,        
    _status;                    

   
  SET @s = CONCAT("CALL mfs_register(",
    "'"  , _origin_id     , "'," ,
    "'"  , _user_filename , "'," ,
    "'"  , _dest_id       , "'," ,
    "'"  , _category      , "'," ,
    "'"  , _extension     , "'," ,
    "'"  , _mimetype      , "'," ,
    "'"  , _geometry      , "'," ,
           _file_size     , ",1)"          
  );
  PREPARE stmt FROM @s;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;   

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_copy_tree` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_copy_tree`(
  IN _nid VARCHAR(16),
  IN _pid VARCHAR(16),
  IN _recipient_id VARCHAR(16)
)
BEGIN
   
    DECLARE  _temp_nid      VARCHAR(16);
    DECLARE  _lvl           INTEGER;
    DECLARE _dest_db        VARCHAR(50);
    DECLARE _origin_db      VARCHAR(50);

    DECLARE _origin_id      VARCHAR(16);   
    DECLARE _src_path       VARCHAR(1024); 
    DECLARE _des_path       VARCHAR(1024); 
    DECLARE _file_name      VARCHAR(512); 
    DECLARE _category       VARCHAR(50);   
    DECLARE _extension      VARCHAR(100); 
    DECLARE _mimetype       VARCHAR(100);      
    DECLARE _file_size      INT(20) UNSIGNED;
    DECLARE _geometry       VARCHAR(200);       
    DECLARE _status         VARCHAR(50); 
    DECLARE _finished       INTEGER DEFAULT 0;
    DECLARE _seq            INTEGER;  
    DECLARE _id             VARCHAR(16);   

    SELECT db_name FROM yp.entity WHERE id=_recipient_id OR ident =_recipient_id INTO _dest_db;
    
    SELECT db_name FROM yp.entity WHERE id =( 
        SELECT origin_id FROM media where id=_nid and parent_path(_nid) LIKE CONCAT("/__Inbound__/","%",'/') 
        ) 
        INTO  _origin_db ;   

    DROP TABLE IF EXISTS  _src_media;
    CREATE TEMPORARY TABLE `_src_media` (
      `seq`  int NOT NULL AUTO_INCREMENT,
      `id` varchar(16) DEFAULT NULL,
      `origin_id` varchar(16) DEFAULT NULL,
      `user_filename` varchar(128) DEFAULT NULL,
      `category`      VARCHAR(50) DEFAULT NULL,
      `parent_id` varchar(16) DEFAULT '',
      `extension` varchar(100) NOT NULL DEFAULT '',
      `mimetype` varchar(100) NOT NULL,
      `filesize` int(20) unsigned NOT NULL DEFAULT '0',
      `geometry` varchar(200) NOT NULL DEFAULT '0x0',
      `new_id` varchar(16) DEFAULT NULL,  
      `new_parent_id` varchar(16) DEFAULT '' ,
      `lvl` int default 0, 
      `is_checked` boolean default 0 ,
       PRIMARY KEY `seq`(`seq`)  
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

    SELECT _nid,0  INTO _temp_nid , _lvl;
   
    WHILE _temp_nid IS NOT NULL DO
      
      INSERT INTO _src_media
      SELECT 
      null, id,origin_id,user_filename,category,parent_id,extension,mimetype,filesize,geometry,null,null,_lvl ,0
      FROM media m1 WHERE  category <> "hub" AND CASE WHEN _lvl <> 0 THEN m1.parent_id ELSE m1.id END  =_temp_nid;
      
      
      UPDATE _src_media SET is_checked = 1 WHERE id = _temp_nid and _lvl <> 0;
      SELECT NULL,_lvl+1 INTO _temp_nid,_lvl;
      SELECT id FROM _src_media WHERE is_checked =0 LIMIT 1 INTO _temp_nid ;
  
    END WHILE;
 
  UPDATE _src_media SET new_parent_id = _pid  WHERE  seq=1;  
  
  BEGIN
    DECLARE dbcursor CURSOR FOR SELECT seq,id,origin_id,user_filename,category,extension,mimetype,`geometry`,filesize FROM _src_media order by seq;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET _finished = 1;
    OPEN dbcursor;
     
      STARTLOOP: LOOP
        FETCH dbcursor INTO _seq,_id,_origin_id,_file_name,_category,_extension,_mimetype,_geometry,_file_size;
         IF _finished = 1 THEN 
            LEAVE STARTLOOP;
         END IF;    

       

        SET @s1 = CONCAT( "CREATE TEMPORARY TABLE IF NOT EXISTS  ",_dest_db,".__register_stack LIKE template.tmp_media"); 
        PREPARE stmt FROM @s1;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;


        SET @s1 = CONCAT( "DELETE FROM ",_dest_db,".__register_stack"); 
        PREPARE stmt1 FROM @s1;
        EXECUTE stmt1;
        DEALLOCATE PREPARE stmt1;
        
        SELECT new_parent_id  FROM _src_media WHERE seq =_seq INTO _pid; 
       

        SET @s2 = CONCAT("CALL ",_dest_db,".mfs_register(",
            "'"  , _origin_id     , "'," ,
            "'"  , _file_name     , "'," ,
            "'"  , _pid           , "'," ,
            "'"  , _category      , "'," ,
            "'"  , _extension     , "'," ,
            "'"  , _mimetype      , "'," ,
            "'"  , _geometry      , "'," ,
                   _file_size     , ", 0 )"          
          );
        PREPARE stmt2 FROM @s2;
        EXECUTE stmt2;
        DEALLOCATE PREPARE stmt2;   
 

      
        SET @s3 = CONCAT( "SELECT id ,parent_id FROM ",_dest_db,".__register_stack INTO @temp_nid,@pid");
        PREPARE stmt3 FROM @s3;
        EXECUTE stmt3;
        DEALLOCATE PREPARE stmt3;   
        

        UPDATE _src_media SET new_id =@temp_nid , new_parent_id = @pid  WHERE seq =_seq ; 
        UPDATE _src_media SET new_parent_id =  @temp_nid    WHERE parent_id = _id; 

      END LOOP STARTLOOP;   

    CLOSE dbcursor;
  END;  
   
  DROP TABLE IF EXISTS _final_media; 
      CREATE TEMPORARY TABLE `_final_media` (
      nid varchar(16) DEFAULT NULL,  
      new_id varchar(16) DEFAULT NULL,    
      action varchar(16) DEFAULT NULL,
      mfs_root varchar(1024)  DEFAULT NULL
      );   
    
  INSERT INTO   _final_media  
  SELECT new_id AS nid ,new_id AS dest_id, 'show'   AS action, null as mfs_root  FROM _src_media WHERE seq = 1 ;

  INSERT INTO   _final_media
  SELECT id   AS nid ,new_id AS dest_id, 'copy'   AS action, null as mfs_root  FROM _src_media WHERE category NOT IN ("folder","hub");

  SELECT * FROM  _final_media;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_count_new` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_count_new`(
  IN _node_id VARCHAR(16), 
  IN _uid VARCHAR(16)
)
BEGIN
  DECLARE _tempid VARCHAR(16);
  DECLARE _category VARCHAR(16);
  DECLARE _lvl INT;
  DECLARE _hub_db_name VARCHAR(255);
  DECLARE _hubs MEDIUMTEXT DEFAULT NULL;
  DECLARE _hub_id VARCHAR(16);


    SELECT id FROM yp.entity WHERE db_name = database() INTO  _hub_id;
  
    DROP TABLE IF EXISTS _show_node; 
    CREATE TEMPORARY TABLE _show_node (
     `seq`  int NOT NULL AUTO_INCREMENT,
     `id` varchar(16),
     `parent_id` varchar(16), 
     `category` varchar(16) ,
      PRIMARY KEY `seq`(`seq`) 
    );

    INSERT INTO _show_node 
    (id, parent_id ,category)
    WITH RECURSIVE mytree AS 
    ( 
      SELECT id, parent_id ,category
      FROM media WHERE id = _node_id
        UNION ALL
      SELECT m.id,m.parent_id ,m.category
      FROM media AS m JOIN mytree AS t ON m.parent_id = t.id
    ) SELECT id, parent_id ,category FROM mytree;
    
    
 
    SELECT MAX(seq) FROM _show_node  INTO _lvl; 
    SELECT id,category FROM _show_node WHERE seq = _lvl 
      INTO _tempid  ,_category;

    SET @_new_chat = 0;
    SET @_new_file = 0;
    WHILE ( _lvl >= 1 AND  _tempid IS NOT NULL) DO
        IF (_category = 'hub') THEN
        SET @_temp_file_count = 0;
        SET @_temp_read_cnt = 0; 
        SET @_temp_result = NULL;
        SELECT db_name FROM yp.entity WHERE id = _tempid
        INTO _hub_db_name; 
        SET @s = CONCAT(
          "SELECT IFNULL(SUM(is_new(metadata, owner_id, ?)), 0) FROM ", _hub_db_name ,
          ".media WHERE file_path not REGEXP '^/__(chat|trash)__' INTO @_temp_file_count"
         );
        PREPARE stmt FROM @s;
        EXECUTE stmt USING _uid;
        DEALLOCATE PREPARE stmt;


        SET @st = CONCAT('CALL ', _hub_db_name ,'.room_detail(?,?)');
        PREPARE stamt FROM @st;
        EXECUTE stamt USING  JSON_OBJECT('uid',_uid ) , @_temp_result ;
        DEALLOCATE PREPARE stamt; 
      
        SELECT JSON_UNQUOTE(JSON_EXTRACT( @_temp_result, "$.read_cnt")) INTO @_temp_read_cnt;
    

        SELECT @_temp_file_count + @_new_file INTO @_new_file;
        SELECT @_temp_read_cnt + @_new_chat INTO @_new_chat;    
      END IF;
    
     
      SELECT _lvl - 1  INTO _lvl; 
      SELECT NULL, NULL INTO _tempid,_category;
      SELECT id,category FROM _show_node WHERE seq = _lvl 
      INTO _tempid,_category;

    END WHILE;
  
  SELECT SUM(is_new(m.metadata, owner_id, _uid)) FROM _show_node 
  INNER JOIN media m USING(id)  INTO @_file_count;
  SELECT IFNULL(GROUP_CONCAT(id), _hubs) FROM _show_node 
  WHERE category='hub' INTO @_hubs;
 
  SELECT @_file_count + @_new_file INTO @_new_file;
  SELECT _node_id nid, _uid `uid`, _hub_id AS hub_id, @_hubs hubs,
    @_new_chat new_chat, @_new_file AS count, @_new_file new_file,
    CAST((@_new_chat + @_new_file) as UNSIGNED INTEGER) notify;
  


END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_create_link` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_create_link`(
  IN _nid VARCHAR(16),
  IN _uid VARCHAR(16),
  IN _dest_id VARCHAR(16),
  IN _recipient_id VARCHAR(16)
)
BEGIN

  DECLARE _is_root tinyint(2) ;
  DECLARE _origin_id      VARCHAR(16);   
  DECLARE _file_name      VARCHAR(512); 
  DECLARE _metadata       JSON; 
  DECLARE _category       VARCHAR(50);   
  DECLARE _extension      VARCHAR(100); 
  DECLARE _mimetype       VARCHAR(100);      
  DECLARE _file_size      INT(20) UNSIGNED;
  DECLARE _geometry       VARCHAR(200);       
  DECLARE _status         VARCHAR(50); 
  DECLARE _finished       INTEGER DEFAULT 0;
  DECLARE _seq            INTEGER;  
  DECLARE _id             VARCHAR(16);   
  DECLARE _dest_db VARCHAR(50);
  DECLARE _src_id VARCHAR(50);
  DECLARE _src_vhost VARCHAR(1000);
  DECLARE _src_home_dir VARCHAR(1000);
  DECLARE _src_home_id VARCHAR(16);

  SELECT e.id, home_dir, fqdn FROM yp.entity e INNER JOIN yp.vhost v on e.id = v.id 
    WHERE db_name=DATABASE() 
  INTO _src_id, _src_home_dir, _src_vhost;

  SELECT db_name FROM yp.entity WHERE id = _recipient_id INTO _dest_db;

  SELECT id, origin_id, user_filename, metadata,`status`, category,
    extension, mimetype, `geometry`, filesize 
  FROM media WHERE id =_nid 
  INTO _id, _origin_id, _file_name, _metadata,_status, _category,
    _extension, _mimetype, _geometry, _file_size;   
 
  SELECT id FROM media WHERE parent_id = '0' INTO _src_home_id;   
 
  SET @args = JSON_OBJECT(
    "owner_id", _uid,
    "origin_id", _origin_id,
    "filename",_file_name,
    "pid", _dest_id,
    "category", _category,
    "ext", _extension,
    "mimetype", _mimetype,
    "filesize", 0,
    "geometry", _geometry,  
    "isalink", 1
  );
  SET @results = JSON_OBJECT();

  SET @metadata = JSON_OBJECT('target', 
    JSON_OBJECT(
      'nid', _nid,
      'hub_id', _src_id,
      'home_id', _src_home_id,
      'vhost', _src_vhost,
      'privilege', @privilege
    )
  );

  SET @st = CONCAT("CALL ", _dest_db, ".mfs_create_node(?, ?, @results)");
  PREPARE stmt2 FROM @st;
  EXECUTE stmt2 USING @args, @metadata;
  DEALLOCATE PREPARE stmt2;


END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_create_linkx` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_create_linkx`(
  IN _nid VARCHAR(16),
  IN _uid VARCHAR(16),
  IN _dest_id VARCHAR(16),
  IN _recipient_id VARCHAR(16)
)
BEGIN
  DECLARE _home_dir VARCHAR(512);
  DECLARE _dest_db VARCHAR(40);
  DECLARE _dest_home_dir VARCHAR(512);

  DECLARE  _dest_name VARCHAR(1024);
  DECLARE  _dest_path TEXT;
  DECLARE  _rank   int(11);

  DECLARE  _src_name   VARCHAR(1024);
  DECLARE  _src_extension       VARCHAR(100);
  DECLARE  _src_category       VARCHAR(50);

  DECLARE _hub_id VARCHAR(16);

  SELECT db_name,home_dir FROM yp.entity WHERE id=_recipient_id OR ident =_recipient_id 
  INTO _dest_db,_dest_home_dir;
  
  DROP TABLE IF EXISTS _final_media; 
   CREATE TEMPORARY TABLE `_final_media` (
   nid varchar(16) DEFAULT NULL,  
   src_mfs_root varchar(1024) DEFAULT NULL,  
   des_id varchar(16) DEFAULT NULL,  
   des_mfs_root varchar(1024) DEFAULT NULL,  
   action varchar(16) DEFAULT NULL,
   recipient_id VARCHAR(16) NULL
   );
 


  SET @st = CONCAT( "CREATE TEMPORARY TABLE IF NOT EXISTS  ",_dest_db,".__register_tree_stack 
    (
    `id` varchar(16) DEFAULT NULL,
    `old_id` varchar(16) DEFAULT NULL,
    `origin_id` varchar(16) DEFAULT NULL,
    `file_path` varchar(512) DEFAULT NULL,
    `user_filename` varchar(128) DEFAULT NULL,
    `parent_id` varchar(16) DEFAULT '',
    `old_parent_id` varchar(16) DEFAULT NULL,
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
    `rank` int(8) DEFAULT 0,
    `home_dir` VARCHAR(512) 
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8
    "); 
    PREPARE stmt FROM @st;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;


    SET @st = CONCAT( "DELETE FROM ",_dest_db,".__register_tree_stack"); 
    PREPARE stmt1 FROM @st;
    EXECUTE stmt1;
    DEALLOCATE PREPARE stmt1;


    SET @st = CONCAT("CALL  " , _dest_db ,".mfs_pre_register_destination (?,?,?,?)");
    PREPARE stamt FROM @st;
    EXECUTE stamt USING _dest_id,_dest_name, _dest_path,_rank;
    DEALLOCATE PREPARE stamt;


    SELECT user_filename ,extension,category FROM media m WHERE m.id=_nid 
    INTO _src_name,_src_extension,_src_category;
    SELECT id , home_dir FROM yp.entity WHERE db_name=database() INTO _hub_id,  _home_dir;

    SET @st = CONCAT("CALL  " , _dest_db ,".mfs_register_tree (?,?,?,?,?,?,?,?,?,?,1)");
    PREPARE stamt FROM @st;
    EXECUTE stamt USING _uid,_dest_id,_dest_name,_dest_path, _rank,_nid,_src_name, _src_extension,_home_dir,_hub_id;
    DEALLOCATE PREPARE stamt;



    SET @st = CONCAT( "INSERT INTO _final_media (nid,src_mfs_root,des_id,des_mfs_root,action,recipient_id)
    SELECT id,NULL ,NULL, NULL ,'showone',", QUOTE(_recipient_id)   ," FROM ",_dest_db,".__register_tree_stack  WHERE parent_id=? LIMIT 1") ; 
    PREPARE stmt FROM @st;
    EXECUTE stmt USING _dest_id ;
    DEALLOCATE PREPARE stmt; 

    SELECT * from _final_media;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_create_link_by` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_create_link_by`(
  IN _nid VARCHAR(16),
  IN _uid VARCHAR(16),
  IN _dest_id VARCHAR(16),
  IN _recipient_id VARCHAR(16)
)
BEGIN

  DECLARE _is_root tinyint(2) ;
  DECLARE _origin_id      VARCHAR(16);
  DECLARE _file_name      VARCHAR(512);
  DECLARE _metadata       JSON;
  DECLARE _category       VARCHAR(50);
  DECLARE _extension      VARCHAR(100);
  DECLARE _mimetype       VARCHAR(100);
  DECLARE _file_size      INT(20) UNSIGNED;
  DECLARE _geometry       VARCHAR(200);
  DECLARE _status         VARCHAR(50);
  DECLARE _finished       INTEGER DEFAULT 0;
  DECLARE _seq            INTEGER;
  DECLARE _id             VARCHAR(16);
  DECLARE _dest_db VARCHAR(50);
  DECLARE _src_id VARCHAR(50);
  DECLARE _src_vhost VARCHAR(1000);
  DECLARE _src_home_dir VARCHAR(1000);
  DECLARE _src_home_id VARCHAR(16);
  DECLARE _sys_id INT;
  DECLARE _temp_sys_id INT;

  SELECT e.id, home_dir, fqdn FROM yp.entity e INNER JOIN yp.vhost v on e.id = v.id
  WHERE db_name=DATABASE()
  INTO _src_id, _src_home_dir, _src_vhost;

  SELECT db_name FROM yp.entity WHERE id = _recipient_id INTO _dest_db;

  SELECT id FROM media WHERE parent_id = '0' INTO _src_home_id;


 DROP TABLE IF EXISTS  _src_media;
  CREATE TEMPORARY TABLE _src_media (
    `sys_id`  int NOT NULL AUTO_INCREMENT,
    `id` varchar(16) DEFAULT NULL,
    PRIMARY KEY `sys_id`(`sys_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8;


  INSERT INTO _src_media SELECT null, id from media
    WHERE parent_id = _nid AND category NOT IN ('hub', 'folder') ;
  SELECT sys_id , id  FROM _src_media WHERE sys_id > 0  ORDER BY sys_id ASC LIMIT 1
    INTO _sys_id ,  _nid;


  WHILE _sys_id <> 0 DO


    SELECT id, origin_id, user_filename, metadata,`status`, category,
      extension, mimetype, `geometry`, filesize
    FROM media WHERE id =_nid
    INTO _id, _origin_id, _file_name, _metadata,_status, _category,
      _extension, _mimetype, _geometry, _file_size;

    SET @args = JSON_OBJECT(
      "owner_id", _uid,
      "origin_id", _origin_id,
      "filename",_file_name,
      "pid", _dest_id,
      "category", _category,
      "ext", _extension,
      "mimetype", _mimetype,
      "filesize", 0,
      "geometry", _geometry,
      "isalink", 1
    );

    SET @results = JSON_OBJECT();
    SET @metadata = JSON_OBJECT('target',
      JSON_OBJECT(
        'nid', _nid,
        'hub_id', _src_id,
        'home_id', _src_home_id,
        'vhost', _src_vhost,
        'privilege', @privilege
      )
    );
    SET @st = CONCAT("CALL ", _dest_db, ".mfs_create_node(?, ?, @results)");

    PREPARE stmt2 FROM @st;
    EXECUTE stmt2 USING @args, @metadata;
    DEALLOCATE PREPARE stmt2;

    SELECT JSON_VALUE(@results, "$.id") INTO @temp_nid;
    SELECT JSON_VALUE(@results, "$.pid") INTO @pid;

    SET @st = CONCAT( "SELECT ", _dest_db, ".user_permission(?, ?) INTO @privilege");

    PREPARE stmt3 FROM @st;
    EXECUTE stmt3 USING _uid, @temp_nid;
    DEALLOCATE PREPARE stmt3;

    SELECT _sys_id INTO  _temp_sys_id ;
    SELECT 0 , NULL INTO  _sys_id, _nid ;
    SELECT sys_id , id  FROM _src_media WHERE sys_id > _temp_sys_id  ORDER BY sys_id ASC LIMIT 1
      INTO _sys_id , _nid;
  END WHILE;


  

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_create_node` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_create_node`(
  IN _attributes JSON,
  IN _metadata JSON,
  OUT _output JSON
)
BEGIN
  DECLARE _vhost VARCHAR(255);
  DECLARE _hub_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _area VARCHAR(50);
  DECLARE _home_dir VARCHAR(512);
  DECLARE _home_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _src_db_name VARCHAR(50);
  DECLARE _accessibility VARCHAR(20);

  DECLARE _fileid   VARCHAR(16) CHARACTER SET ascii DEFAULT '';
  DECLARE _ts   INT(11) DEFAULT 0;
  DECLARE _parent_id TEXT;
  DECLARE _root_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _parent_path TEXT;
  DECLARE _parent_name VARCHAR(100) DEFAULT '';
  DECLARE _filepath VARCHAR(1024);
  DECLARE _username VARCHAR(100);
  DECLARE _org VARCHAR(500);
  DECLARE _root_hub_id VARCHAR(16) CHARACTER SET ascii ;
  DECLARE _user_db_name VARCHAR(255);
  DECLARE _rollback BOOLEAN DEFAULT 0;

  DECLARE _origin_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _owner_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _fname VARCHAR(1024);
  DECLARE _pid VARCHAR(16) CHARACTER SET ascii;
  DECLARE _category VARCHAR(50);
  DECLARE _ext VARCHAR(100);
  DECLARE _mimetype VARCHAR(100);
  DECLARE _geometry VARCHAR(200);
  DECLARE _filesize BIGINT UNSIGNED;
  DECLARE _show BOOLEAN;
  DECLARE _isalink TINYINT(2) UNSIGNED DEFAULT 0;
  DECLARE _target JSON DEFAULT JSON_OBJECT();
  DECLARE _content JSON;

  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
  BEGIN
    SET _rollback = 1;  
    GET DIAGNOSTICS CONDITION 1 
      @sqlstate = RETURNED_SQLSTATE, 
      @errno = MYSQL_ERRNO, 
      @message = MESSAGE_TEXT;
  END;

  START TRANSACTION;

  SELECT JSON_VALUE(_attributes, "$.origin_id") INTO _origin_id;
  SELECT JSON_VALUE(_attributes, "$.owner_id") INTO _owner_id;
  SELECT JSON_VALUE(_attributes, "$.filename") INTO _fname;
  SELECT JSON_VALUE(_attributes, "$.pid") INTO _pid;
  SELECT JSON_VALUE(_attributes, "$.category") INTO _category;
  SELECT JSON_VALUE(_attributes, "$.ext") INTO _ext;
  SELECT JSON_VALUE(_attributes, "$.mimetype") INTO _mimetype;
  SELECT JSON_VALUE(_attributes, "$.geometry") INTO _geometry;
  SELECT JSON_VALUE(_attributes, "$.filesize") INTO _filesize;
  SELECT JSON_VALUE(_attributes, "$.isalink") INTO _isalink;
  SELECT JSON_VALUE(_attributes, "$.showResults") INTO _show;

  SELECT JSON_EXTRACT(_metadata, "$.content") INTO _content;
  SELECT JSON_EXTRACT(_metadata, "$.target") INTO _target;

  SELECT UNIX_TIMESTAMP() INTO _ts;
  SELECT yp.uniqueId() INTO _fileid;

  SELECT database() INTO _src_db_name;
  SELECT  h.id FROM yp.hub h INNER JOIN yp.entity e on e.id = h.id WHERE db_name=_src_db_name INTO _root_hub_id;
  SELECT '' INTO @xhub_name;

  IF _root_hub_id IS NOT NULL THEN
    SELECT db_name FROM yp.entity WHERE id = _owner_id INTO _user_db_name;
    IF _user_db_name IS NOT NULL THEN 
      SET @s = CONCAT("SELECT ", _user_db_name, ".filepath(?) INTO @xhub_name");
      PREPARE stmt FROM @s;
      EXECUTE stmt USING _root_hub_id;
      DEALLOCATE PREPARE stmt;
    END IF;
  END IF;

  SELECT username, link FROM yp.drumate d 
    INNER JOIN yp.organisation o ON o.domain_id = d.domain_id
    WHERE d.id=_owner_id INTO _username, _org;

  SELECT  home_dir from yp.entity WHERE  db_name=database() INTO  _home_dir ; 

  IF IFNULL(_pid, '0') IN('', '0') THEN 
    SELECT id FROM media WHERE parent_id='0' INTO  _pid;
  END IF;

  SELECT id, REGEXP_REPLACE(user_filename, '^[/ ]+|/+|\<.*\>|[/ ]+$', '') 
    FROM media WHERE id=_pid INTO _parent_id, _parent_name;

  IF _parent_id IS NULL OR _parent_id='' THEN 
    SELECT id FROM media m WHERE m.parent_id='0' INTO  _parent_id;
    
  END IF;
  
  SELECT COUNT(1) FROM media WHERE parent_id = _pid INTO @_count;

  SELECT parent_path(_parent_id) INTO _parent_path;
  SELECT REGEXP_REPLACE(_fname, '^[/ ]+|\<.*\>|[/ ]+$', '') INTO _fname;
  SELECT REGEXP_REPLACE(_fname, '( *)(/+)( *)', '') INTO _fname;
  SELECT unique_filename(_parent_id, _fname, _ext) INTO _fname;

  IF(_ext IS NULL OR _category IN('folder', 'hub', 'root') OR _ext IN('', 'root', 'folder')) THEN
    SELECT CONCAT(_parent_path, '/', _parent_name, '/', _fname)
    INTO _filepath;
    SELECT '' INTO _ext;
  ELSEIF (_category='hub') THEN
    SELECT _username INTO _ext;
  ELSE
    SELECT CONCAT(_parent_path, '/', _parent_name, '/', _fname, '.', _ext) INTO _filepath;
    SELECT IFNULL(category, _category), IFNULL(mimetype, _mimetype) 
      FROM yp.filecap WHERE extension=_ext INTO _category, _mimetype;
  END IF;

  SELECT clean_path(_filepath) INTO _filepath;
  IF _category NOT IN ('hub', 'folder') THEN 
    SELECT JSON_MERGE(_metadata, JSON_OBJECT(
      '_seen_', JSON_OBJECT(_owner_id, UNIX_TIMESTAMP())
    )) INTO _metadata;
  END IF; 

  IF _isalink THEN
    SELECT user_permission(_owner_id, _pid) INTO @privilege;
    SELECT JSON_SET(_target, "$.privilege", @privilege) INTO _target;
    SELECT JSON_SET(_metadata, "$.target", _target) INTO _metadata;
  END IF;

  IF JSON_VALUE(_content, "$.room_id") = "set-me" THEN
    SELECT JSON_SET(_content, "$.room_id", _fileid) INTO _content;
    SELECT JSON_SET(_metadata, "$.content", _content) INTO _metadata;
  END IF;
  INSERT INTO `media` (
    id, 
    origin_id, 
    owner_id,
    file_path, 
    user_filename, 
    parent_id, 
    parent_path,
    extension, 
    mimetype, 
    category,
    isalink,
    filesize, 
    `geometry`, 
    publish_time, 
    upload_time, 
    `status`,
    `metadata`,
    rank
  ) VALUES (
    _fileid, 
    IFNULL(_origin_id, _owner_id), 
    _owner_id,
    _filepath, 
    TRIM('/' FROM _fname),
    _pid, 
    _parent_path,
    _ext, 
    _mimetype, 
    _category, 
    IFNULL(_isalink, 0),
    IFNULL(_filesize, 4096),
    IFNULL(_geometry, '0x0'), 
    _ts, 
    _ts, 
    IF(_category='stylesheet', 'idle', 'active'),
    _metadata,
    @_count
  );

  SELECT JSON_OBJECT(
    "id", _fileid, 
    "nid", _fileid, 
    "pid", _pid, 
    "filepath", _filepath, 
    "parentpath", _parent_path,
    "timestamp", _ts, 
    "status", 'active',
    "count", @_count
  )  INTO _output;
  
  SET @perm = 0;

  UPDATE media SET parent_path=parent_path(_fileid) WHERE id=_fileid;

  IF IFNULL(_show, 0) != 0  THEN
    SELECT 
      m.id, 
      m.id as nid, 
      concat(_home_dir, "/__storage__/") AS mfs_root,
      parent_id AS pid,
      parent_id,
      e.id AS holder_id,
      e.home_id,
      e.home_dir,
      user_permission(_owner_id, m.id)  AS privilege,
      e.id AS owner_id,    
      e.id AS hub_id,    
      yp.vhost(e.id) AS vhost,    
      user_filename AS filename,
      file_path as ownpath,
      CONCAT(@xhub_name, file_path) as file_path,
      CONCAT(@xhub_name, file_path) as filepath,
      filesize,
      e.area,
      caption,
      e.accessibility,
      capability,
      m.extension,
      m.extension AS ext,
      m.category AS ftype,
      m.category AS filetype,
      m.mimetype,
      download_count AS view_count,
      geometry,
      upload_time AS ctime,
      publish_time AS mtime,
      firstname,
      lastname,
      m.category,
      user_filename,
      _username AS username,
      _org AS organization,
      parent_path,
      metadata,
      database() db_name
    FROM media m
      INNER JOIN yp.entity e  ON e.db_name=database()
      LEFT JOIN yp.drumate dr ON e.id = dr.id
      LEFT JOIN yp.domain d ON d.id = e.dom_id
      LEFT JOIN yp.filecap ff ON m.extension=ff.extension

      
      
      WHERE m.id = _fileid;
  END IF ;

  SELECT id FROM yp.entity WHERE db_name=database() INTO _hub_id;
  UPDATE yp.disk_usage SET size = (IFNULL(size,0) + IFNULL(_filesize,0)) WHERE hub_id = _hub_id;

  IF _rollback THEN
    ROLLBACK;
    SELECT 1 failed, 
      @sqlstate AS `sqlstate`,
      @errno AS `errno`,
      CONCAT(DATABASE(), ":", @message) AS `message`;
  ELSE
    COMMIT;
  END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_delete` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_delete`(
  IN _rid VARCHAR(16),
  IN _uid VARCHAR(16),
  IN _bound VARCHAR(255)
)
BEGIN
  DECLARE _node_path VARCHAR(255);
  DECLARE _category VARCHAR(40);
  
  DECLARE _src_share_box_id VARCHAR(16);
  DECLARE _src_db_name VARCHAR(255);
  DECLARE _des_share_box_id VARCHAR(16);
  DECLARE _des_db_name VARCHAR(255);
  DECLARE _hub_id VARCHAR(16);
  DECLARE _sid VARCHAR(16);
  DECLARE _eid VARCHAR(16);
  DECLARE _status VARCHAR(16); 

 
  IF _bound = '__Nobound__' THEN

    SELECT category from media WHERE id=_rid into _category;
    IF _category='folder' THEN
      SELECT TRIM(TRAILING '/' FROM file_path) from media WHERE id=_rid into _node_path;
      DELETE FROM media WHERE file_path LIKE concat(_node_path, '/%');
    END IF;
    DELETE FROM media WHERE id=_rid;

  END IF ;
  
 
  IF _bound = '__Outbound__' THEN

    DROP TABLE IF EXISTS  _user_box_media;
    CREATE TEMPORARY TABLE _user_box_media (
        `id` varchar(16) DEFAULT NULL,
        `entity_id` varchar(16) NOT NULL,
        `status` enum('receive','accept','refuse','remove','change') DEFAULT 'receive',  
        `is_checked` boolean default 0
    );

    INSERT INTO _user_box_media
    SELECT sys_id,n.entity_id,n.status,0 
    FROM yp.notification n 
    WHERE  n.status IN ('receive','change','accept')
    AND owner_id = _uid
    AND resource_id =(
      SELECT id
      FROM media m 
      INNER JOIN yp.notification n ON  n.resource_id=m.id 
      WHERE (SELECT concat(parent_path,'/',user_filename) 
        FROM media WHERE id = _rid) REGEXP user_filename AND n.permission IS NOT NULL
      ORDER BY (LENGTH(parent_path)-LENGTH(REPLACE(parent_path, '/', '')))  DESC LIMIT 1 
    );

    WHILE (IFNULL(
      (SELECT 1 FROM _user_box_media  WHERE  is_checked = 0 limit 1 ),0)  = 1 ) DO
      
      SELECT id, entity_id, status  FROM _user_box_media WHERE is_checked = 0 LIMIT 1 
        INTO _sid ,_eid,_status;
      
      IF _status <> 'receive' THEN
        SET @s = CONCAT(" CALL sb_to_sb("
                        , QUOTE(_uid) ,"," 
                        , QUOTE(_rid) ,"," 
                        , QUOTE(_eid), ",null,null,null,'remove')"
                    );
        PREPARE pstmt FROM @s;
        EXECUTE pstmt;
        DEALLOCATE PREPARE pstmt;
      END IF;  

      SET @s = CONCAT(" CALL  yp.yp_notification_remove(", QUOTE(_rid) ,"," , QUOTE(_eid), ")");
      PREPARE stmt FROM @s;
      EXECUTE stmt;
      DEALLOCATE PREPARE stmt;
      
      UPDATE _user_box_media SET is_checked =  1 WHERE id =_sid  AND  entity_id =_eid ; 
    END WHILE ; 

    
    SET @s = CONCAT(" CALL  permission_revoke(", QUOTE(_rid) ,",'nobody')");
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;


    SELECT category from media WHERE id=_rid into _category;
    IF _category='folder' THEN
      SELECT TRIM(TRAILING '/' FROM file_path) from media WHERE id=_rid into _node_path;
      DELETE FROM media WHERE file_path LIKE concat(_node_path, '/%');
    END IF;
    DELETE FROM media WHERE id=_rid;

  END IF;

  IF _bound = '__Inbound__' THEN
     
    
    SELECT owner_id FROM yp.share_box where id =(SELECT host_id from media WHERE id = _rid ) INTO _hub_id;

    SET @s = CONCAT(" CALL sb_to_sb("
                      , QUOTE(_hub_id) ,"," 
                      , QUOTE(_rid) ,"," 
                      , QUOTE(_uid), ",null,null,null,'remove')"
                   );
    PREPARE pstmt FROM @s;
    EXECUTE pstmt;
    DEALLOCATE PREPARE pstmt;

    SET @s = CONCAT(" CALL  yp.yp_notification_remove(", QUOTE(_rid) ,"," , QUOTE(_uid), ")");
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;


    SELECT category from media WHERE id=_rid into _category;
    IF _category='folder' THEN
      SELECT TRIM(TRAILING '/' FROM file_path) from media WHERE id=_rid into _node_path;
      DELETE FROM media WHERE file_path LIKE concat(_node_path, '/%');
    END IF;
    DELETE FROM media WHERE id=_rid;
      
    DELETE FROM media WHERE  parent_path =  "/__Inbound__" AND id 
    NOT IN (SELECT parent_id FROM(SELECT parent_id FROM media)a);
  
  END IF ;

 SELECT _rid as id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_delete_node` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_delete_node`(
  IN _id VARCHAR(16)
)
BEGIN
  DECLARE _node_path VARCHAR(255);
  DECLARE _category VARCHAR(40);
  
  SELECT category from media WHERE id=_id into _category;
  
  IF _category='folder' THEN
    SELECT CONCAT(parent_path(id),user_filename) from media WHERE id=_id into _node_path;
    DELETE FROM media  WHERE CONCAT(parent_path(id),user_filename ) LIKE concat(_node_path, '/%');
  END IF;
  DELETE FROM media WHERE id=_id;
  

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_delete_trash` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_delete_trash`(IN _nodes JSON)
BEGIN
  DECLARE _idx INT DEFAULT 0;
  DECLARE _nid VARCHAR(16) CHARACTER SET ascii;
  DECLARE _hub_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _db_name VARCHAR(60) CHARACTER SET ascii;
  DECLARE _home_dir VARCHAR(300) CHARACTER SET ascii;
 
  DECLARE exit handler for sqlexception
  BEGIN
    ROLLBACK;
  END;
   
  DECLARE exit handler for sqlwarning
  BEGIN
    ROLLBACK;
  END;

  START TRANSACTION;

  DROP TABLE IF EXISTS _mytree; 
  CREATE  TEMPORARY TABLE _mytree (
          id varchar(16)  CHARACTER SET ascii DEFAULT NULL,
          parent_id varchar(16)  CHARACTER SET ascii DEFAULT NULL,
          filesize bigint default 0,
          category varchar(16) NOT NULL DEFAULT 'other',
          hub_id varchar(16)  CHARACTER SET ascii DEFAULT NULL,
          home_dir VARCHAR(512) DEFAULT null,
          nid varchar(16)  CHARACTER SET ascii DEFAULT NULL
        );


  WHILE _idx < JSON_LENGTH(_nodes) DO 

    SELECT JSON_UNQUOTE(JSON_EXTRACT(_nodes, CONCAT("$[", _idx, "]"))) INTO @_node;
    SELECT JSON_VALUE(@_node, "$.nid") INTO _nid;
    SELECT JSON_VALUE(@_node, "$.hub_id") INTO _hub_id;

    SELECT  db_name,home_dir FROM yp.entity WHERE id = _hub_id INTO _db_name , _home_dir;
   
      SET @st = CONCAT
        ( " 
           INSERT INTO _mytree( id, nid,parent_id,category ,filesize )
           WITH RECURSIVE mytree AS (
            SELECT id, ", QUOTE(_nid)," nid, parent_id,category ,filesize 
            FROM ",_db_name,".trash_media WHERE id =", QUOTE(_nid),"
            UNION ALL
            SELECT m.id, ", QUOTE(_nid), " nid, m.parent_id ,m.category,m.filesize
            FROM ",_db_name,".trash_media AS m JOIN mytree AS t ON m.parent_id = t.id
          )
         SELECT id, nid, parent_id,category ,filesize FROM mytree;");

        PREPARE stmt FROM @st;
        EXECUTE stmt ;
        DEALLOCATE PREPARE stmt; 

        UPDATE _mytree 
        SET hub_id =_hub_id ,home_dir =_home_dir 
        WHERE  nid =_nid;


        SET @st = CONCAT("UPDATE yp.disk_usage SET size = size - 
            (SELECT SUM(filesize) FROM _mytree WHERE nid =",  QUOTE(_nid) ," ) 
            WHERE hub_id =",QUOTE( _hub_id),"");
        PREPARE stmt FROM @st;
        EXECUTE stmt ;
        DEALLOCATE PREPARE stmt; 

        SET @st = CONCAT ("DELETE FROM " ,_db_name,".trash_media 
          WHERE id IN (SELECT id FROM _mytree WHERE nid =",  QUOTE(_nid) ,")");
        PREPARE stmt FROM @st;
        EXECUTE stmt ;
        DEALLOCATE PREPARE stmt;



    SELECT _idx + 1 INTO _idx;
  END WHILE; 
  COMMIT;
  SELECT 
    id, category, parent_id,CONCAT(home_dir, "/__storage__/") home_dir
  FROM _mytree
  WHERE category NOT IN ('hub') ;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_empty_bin` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_empty_bin`(
)
BEGIN

  DECLARE _count INT(6);
  SELECT count(*) FROM media WHERE status='deleted' INTO _count;
  DELETE FROM media WHERE status='deleted' AND id=_id;
  SELECT _count AS count;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_empty_trash` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_empty_trash`()
BEGIN

  DECLARE _hub_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _db_name VARCHAR(60) CHARACTER SET ascii;
  DECLARE _home_dir VARCHAR(300) CHARACTER SET ascii;

  DECLARE exit handler for sqlexception
  BEGIN
  
    ROLLBACK;
  END;


  START TRANSACTION;

    DROP TABLE IF EXISTS `_hubs`; 
    CREATE  TEMPORARY TABLE `_hubs` 
    (
      hub_id varchar(16)  CHARACTER SET ascii DEFAULT NULL,
      db_name varchar(60)  CHARACTER SET ascii DEFAULT NULL,
      home_dir varchar(300)  CHARACTER SET ascii DEFAULT NULL,
      is_checked int default 0      
    );

    DROP TABLE IF EXISTS `_delete`; 
    CREATE  TEMPORARY TABLE `_delete` 
    (
      id varchar(16)  CHARACTER SET ascii DEFAULT NULL,
      hub_id varchar(16)  CHARACTER SET ascii DEFAULT NULL,
      db_name varchar(60)  CHARACTER SET ascii DEFAULT NULL,
      home_dir varchar(300)  CHARACTER SET ascii DEFAULT NULL
    );


    INSERT INTO _hubs
    SELECT id hub, db_name,home_dir,0 FROM 
    yp.entity WHERE id IN(
    SELECT id FROM media m INNER JOIN permission p 
    ON p.resource_id = m.id AND p.permission>=15 AND m.status='active' );
    INSERT INTO _hubs
    SELECT id, db_name,home_dir,0 FROM yp.entity WHERE db_name=database() ;

    SELECT hub_id,db_name,home_dir  FROM _hubs WHERE is_checked = 0 LIMIT 1 INTO _hub_id ,_db_name , _home_dir;
    WHILE  _hub_id IS NOT NULL DO 

        SET @st = CONCAT("UPDATE yp.disk_usage SET size = size - (SELECT IFNULL(SUM(filesize),0) FROM " ,_db_name, ".trash_media) WHERE hub_id =",QUOTE( _hub_id),";");
        PREPARE stmt FROM @st;
        EXECUTE stmt ;
        DEALLOCATE PREPARE stmt; 

        SET @st = CONCAT("INSERT INTO _delete (id ,hub_id )
            SELECT  id ,", QUOTE( _hub_id )," FROM ",_db_name, ".trash_media WHERE category NOT IN ('hub') ");
        PREPARE stmt FROM @st;
        EXECUTE stmt ;
        DEALLOCATE PREPARE stmt; 

        SET @st = CONCAT("DELETE FROM ",_db_name, ".trash_media");
        PREPARE stmt FROM @st;
        EXECUTE stmt ;
        DEALLOCATE PREPARE stmt; 

        UPDATE _delete SET db_name = _db_name ,home_dir =_home_dir WHERE  hub_id =_hub_id;

        UPDATE _hubs SET is_checked = 1 WHERE _hub_id =hub_id;
        SELECT NULL,NULL,NULL INTO _hub_id ,_db_name , _home_dir;
        SELECT hub_id,db_name,home_dir  FROM _hubs WHERE is_checked = 0 LIMIT 1 INTO _hub_id ,_db_name , _home_dir;


     END WHILE; 
  COMMIT;
  SELECT id,  CONCAT(home_dir, "/__storage__/") home_dir FROM _delete;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_export` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_export`(
  IN _nodes JSON,
  IN _uid VARCHAR(16) CHARACTER SET ascii
)
BEGIN
  DECLARE _idx INT(4) DEFAULT 0; 
  DECLARE _shub_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _shub_db VARCHAR(40);
  DECLARE _shome_dir VARCHAR(512) DEFAULT null;
  DECLARE _nid VARCHAR(16) CHARACTER SET ascii;
  DECLARE _hubid VARCHAR(16) CHARACTER SET ascii;

 DROP TABLE IF EXISTS _mytree; 
    CREATE  TEMPORARY TABLE _mytree (
          id varchar(16)  CHARACTER SET ascii DEFAULT NULL,
          parent_id varchar(16)  CHARACTER SET ascii DEFAULT NULL,
         `is_root` boolean default 0 ,
          user_filename varchar(128),
          parent_path  varchar(4000),
          file_path varchar(4000),
          extension varchar(100),    
          mimetype varchar(100),
          category varchar(16),
          src_mfs_root VARCHAR(1024) DEFAULT null
        );


  WHILE _idx < JSON_LENGTH(_nodes) DO 
    SELECT get_json_array(_nodes, _idx) INTO @_node;
    SELECT get_json_object(@_node, "nid") INTO _nid;
    SELECT get_json_object(@_node, "hub_id") INTO _shub_id;


    SELECT db_name,home_dir FROM yp.entity WHERE id = _shub_id 
    INTO _shub_db,_shome_dir; 

      
 
      SET @st = CONCAT("SELECT parent_id, user_filename,extension FROM  ", _shub_db, ".media WHERE  id =? INTO  @parent_id , @user_filename,@extension ");
      PREPARE stmt3 FROM @st;
      EXECUTE stmt3 USING   _nid;
      DEALLOCATE PREPARE stmt3;

      SELECT CONCAT('/',name) ,'' FROM  yp.hub  WHERE @parent_id = '0' AND id =  _shub_id  INTO @user_filename ,@extension ; 
 
      SET @st = CONCAT("
        INSERT INTO _mytree
        WITH RECURSIVE mytree AS 
        (
              SELECT  id, 
              parent_id,1 is_root,
              @user_filename user_filename,
              CONCAT(IFNULL(@parent_path,''), IFNULL(@parent_name,''),'') parent_path,
              CASE WHEN  category ='folder' or extension = '' or parent_id = '0' 
                  THEN 
                    CONCAT(IFNULL(@parent_path,''), IFNULL(@parent_name,''),'/', IFNULL( @user_filename,'')) 
                  ELSE 
                    CONCAT(IFNULL(@parent_path,''), IFNULL(@parent_name,''),'/', IFNULL( @user_filename,''), '.',IFNULL(extension,''))  
                  END file_path,
              m.extension,m.mimetype,   
              CASE WHEN parent_id = '0' THEN 'folder' ELSE m.category END category,
              ", QUOTE(_shome_dir) , "src_mfs_root 
              FROM ",_shub_db,".media m WHERE  
              m.file_path not REGEXP '^/__(chat|trash)__' AND 
              m.status IN ('active', 'locked')   AND  id =", QUOTE(_nid) , "
              UNION ALL 
              SELECT  m.id, 
              m.parent_id , 0 is_root, 
              m.user_filename,
              CONCAT(IFNULL(t.parent_path,''), IFNULL(t.user_filename,''),'/') parent_path ,
              CASE WHEN  m.category ='folder' or m.extension = '' 
                  THEN 
                    CONCAT(IFNULL(t.parent_path,''), IFNULL(t.user_filename,''),'/', IFNULL(m.user_filename,'')) 
                  ELSE 
                    CONCAT(IFNULL(t.parent_path,''), IFNULL(t.user_filename,''),'/', IFNULL(m.user_filename,''), '.',IFNULL(m.extension,''))  
              END file_path,
              m.extension,m.mimetype,m.category,
              ", QUOTE(_shome_dir) , " src_mfs_root
              FROM ",_shub_db,".media m  JOIN mytree t on m.parent_id =t.id  WHERE  
              m.file_path not REGEXP '^/__(chat|trash)__' AND 
              m.status IN ('active', 'locked')
        )
        SELECT * FROM mytree;
        ");
      PREPARE stmt FROM @st;
      EXECUTE stmt ;
      DEALLOCATE PREPARE stmt;

    SELECT _idx + 1 INTO _idx;

  END WHILE; 

  DROP TABLE IF EXISTS _myhub; 

  CREATE  TEMPORARY TABLE _myhub (
      id varchar(16)  CHARACTER SET ascii DEFAULT NULL,
      parent_id varchar(16)  CHARACTER SET ascii DEFAULT NULL,
      `is_root` boolean default 0 ,
      user_filename varchar(128),
      parent_path  varchar(4000),
      file_path varchar(4000),
      extension varchar(100),    
      mimetype varchar(100),
      category varchar(16),
      src_mfs_root VARCHAR(1024) DEFAULT null
    );

    INSERT INTO _myhub
    SELECT * FROM _mytree WHERE category = 'hub';
    ALTER TABLE _myhub ADD `is_checked` boolean default 0 ;
 

    SELECT  id,parent_path,user_filename FROM _myhub where is_checked =0 LIMIT 1 INTO _hubid ,@parent_path,  @parent_name;


    WHILE (_hubid IS NOT NULL) do
     
      SELECT db_name,home_dir FROM yp.entity WHERE id = _hubid 
      INTO _shub_db,_shome_dir; 


      SET @st = CONCAT("SELECT id FROM  ", _shub_db, ".media WHERE  parent_id ='0'  INTO  @nid  ");
      PREPARE stmt3 FROM @st;
      EXECUTE stmt3 ;
      DEALLOCATE PREPARE stmt3;

      SELECT @nid  INTO _nid;

      
      SET @st = CONCAT("
        INSERT INTO _mytree
        WITH RECURSIVE mytree AS 
        (
              SELECT  id, 
              parent_id,0 is_root,
              user_filename,
              CONCAT(IFNULL(@parent_path,''), IFNULL(@parent_name,''),'/') parent_path,
              CASE WHEN  category ='folder' or extension = '' or parent_id = '0' 
                  THEN 
                    CONCAT(IFNULL(@parent_path,''), IFNULL(@parent_name,''),'/', IFNULL( user_filename,'')) 
                  ELSE 
                    CONCAT(IFNULL(@parent_path,''), IFNULL(@parent_name,''),'/', IFNULL( user_filename,''), '.',IFNULL(extension,''))  
                  END file_path,
              m.extension,m.mimetype,   
              CASE WHEN parent_id = '0' THEN 'folder' ELSE m.category END category,
              ", QUOTE(_shome_dir) , "src_mfs_root 
              FROM ",_shub_db,".media m WHERE  
              m.file_path not REGEXP '^/__(chat|trash)__' AND 
              m.status IN ('active', 'locked')   AND  parent_id =", QUOTE(_nid) , "
              UNION ALL 
              SELECT  m.id, 
              m.parent_id , 0 is_root, 
              m.user_filename,
              CONCAT(IFNULL(t.parent_path,''), IFNULL(t.user_filename,''),'/') parent_path ,
              CASE WHEN  m.category ='folder' or m.extension = '' 
                  THEN 
                    CONCAT(IFNULL(t.parent_path,''), IFNULL(t.user_filename,''),'/', IFNULL(m.user_filename,'')) 
                  ELSE 
                    CONCAT(IFNULL(t.parent_path,''), IFNULL(t.user_filename,''),'/', IFNULL(m.user_filename,''), '.',IFNULL(m.extension,''))  
              END file_path,
              m.extension,m.mimetype,m.category,
              ", QUOTE(_shome_dir) , " src_mfs_root
              FROM ",_shub_db,".media m  JOIN mytree t on m.parent_id =t.id  WHERE  
              m.file_path not REGEXP '^/__(chat|trash)__' AND 
              m.status IN ('active', 'locked')
        )
        SELECT * FROM mytree;
        ");
      PREPARE stmt FROM @st;
      EXECUTE stmt ;
      DEALLOCATE PREPARE stmt;

      
      UPDATE _myhub SET is_checked = 1 WHERE id = _hubid ;
      SELECT NULL INTO _hubid ;
      SELECT  id,parent_path,user_filename FROM _myhub where is_checked =0 LIMIT 1 INTO _hubid ,@parent_path,  @parent_name;

    END WHILE;
  
  SELECT  NULL ,NULL INTO @parent_path,  @parent_name;

  UPDATE _mytree SET  category = 'folder'  WHERE category = 'hub';

  SELECT  CASE WHEN  m.category ='folder' 
                    THEN ''
                    ELSE CONCAT( src_mfs_root,'__storage__/',id,'/orig.',extension )  
          END source  ,  
          file_path destination,
          m.category, 
          m.extension
  FROM _mytree m
  WHERE category NOT IN ( 'root');


END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_fetch` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_fetch`(
  IN _in JSON , 
  OUT _out JSON
)
BEGIN
DECLARE _nid VARCHAR(16) ; 
  SELECT get_json_object(_in, "nid") INTO _nid;
  SELECT 
  JSON_MERGE( 
    JSON_OBJECT('origin_id',origin_id),
    JSON_OBJECT('user_filename',user_filename),
    JSON_OBJECT('category',category),
    JSON_OBJECT('extension',extension),
    JSON_OBJECT('mimetype',mimetype),
    JSON_OBJECT('filesize',filesize)    
  )
  FROM media WHERE id= _nid  INTO _out; 

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_file_stat` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_file_stat`(
  IN _node_id VARCHAR(16)
)
BEGIN

  DECLARE _vhost VARCHAR(255);
  DECLARE _home_id VARCHAR(16);
  DECLARE _hub_id VARCHAR(16);
  DECLARE _area VARCHAR(50);
  DECLARE _home_dir VARCHAR(512);
  DECLARE _db_name VARCHAR(50);
  DECLARE _accessibility VARCHAR(16);

  CALL mediaEnv(_vhost, _hub_id, _area, _home_dir, _home_id, _db_name, _accessibility);

  SELECT
    media.id  AS nid,
    parent_id AS pid,
    parent_id AS parent_id,
    _hub_id AS holder_id,
    _home_id AS home_id,
    IF(media.category='hub', 
      (SELECT id FROM yp.entity WHERE entity.id=media.id), _hub_id
    ) AS oid,    
    caption,
    capability,
    IF(media.category='hub', (
      SELECT accessibility FROM yp.entity WHERE entity.id=media.id), _accessibility
    ) AS accessibility,
    IF(media.category='hub', (
      SELECT status FROM yp.entity WHERE entity.id=media.id), status
    ) AS status,
    media.extension AS ext,
    media.category AS ftype,
    media.category AS filetype,
    media.mimetype,
    download_count AS view_count,
    geometry,
    upload_time AS ctime,
    publish_time AS ptime,
    parent_path,
    IF(parent_path='' or parent_path is NULL , '/', parent_path) AS user_path,
    IF(media.category='hub', (
      SELECT `name` FROM yp.hub WHERE hub.id=media.id), user_filename
    ) AS filename,
    IF(media.category='hub', (
      SELECT space FROM yp.entity WHERE entity.id=media.id), filesize
    ) AS filesize,
    firstname,
    lastname,
    remit,
    IF(media.category='hub', (
      SELECT utils.vhost(ident) FROM yp.entity WHERE entity.id=media.id), _vhost
    ) AS vhost,
    IF(media.category='hub', media.extension, _area) AS area
  FROM  media LEFT JOIN (yp.filecap, yp.drumate) ON 
  media.extension=filecap.extension AND origin_id=yp.drumate.id 
  WHERE media.id=_node_id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_find` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_find`(
  IN _uid VARCHAR(512),
  IN _pattern VARCHAR(84),
  IN _page TINYINT(4)
)
BEGIN

  DECLARE _range bigint;
  DECLARE _offset bigint;
  DECLARE _finished       INTEGER DEFAULT 0; 
  DECLARE _nid VARCHAR(16);   
  CALL pageToLimits(_page, _offset, _range);
  
   

    
  CREATE TEMPORARY TABLE _search_node  AS     
  SELECT  
    m.id  as nid,
    m.extension as ext,
    m.origin_id  AS origin_id,
    m.file_path as filepath,
    COALESCE(he.id,me.id) AS hub_id,
    
    COALESCE(he.status,m.status) AS status,
    COALESCE(hh.name,m.user_filename) AS filename,
    COALESCE(me.space,m.filesize) AS filesize,
    _uid AS oid,
    ff.capability,
    IF(m.category='hub', m.extension, me.area) AS area,
    m.category as filetype,
    firstname,
    lastname,
    caption,
    upload_time as mtime,
    download_count as views,
    MATCH(`caption`,`user_filename`,`metadata`)
      against(_pattern IN NATURAL LANGUAGE MODE WITH QUERY EXPANSION)
    + IF(MATCH(`caption`,`user_filename`,`metadata`)
      against(concat(_pattern, '*') IN BOOLEAN MODE), 30, 0)
    + IF(user_filename = _pattern, 100, 0)
    + IF(user_filename LIKE concat("%", _pattern, "%"), 27, 0) AS score
    FROM media m  
    LEFT  JOIN yp.filecap ff ON m.extension=ff.extension
    LEFT  JOIN yp.entity he ON m.id = he.id AND m.category='hub'
    LEFT  JOIN yp.hub hh ON m.id = hh.id AND m.category='hub'
    INNER JOIN yp.drumate d  ON m.origin_id=d.id 
    INNER JOIN yp.entity me  ON me.db_name=database()
    WHERE  m.status='active'
    HAVING  score > 25
     LIMIT _offset, _range;
    
    ALTER table _search_node ADD privilege  tinyint(4) unsigned ;
    ALTER table _search_node ADD expiry_time int(11) ;
    
    BEGIN
      DECLARE dbcursor CURSOR FOR SELECT  nid FROM _search_node;
      DECLARE CONTINUE HANDLER FOR NOT FOUND SET _finished = 1; 
      OPEN dbcursor;
        STARTLOOP: LOOP
          FETCH dbcursor INTO _nid;
          
            IF _finished = 1 THEN 
              LEAVE STARTLOOP;
            END IF;
          
            SET @perm = 0;
            SET @s = CONCAT("SELECT user_permission (", QUOTE(_uid),",",QUOTE(_nid), ") INTO @perm");
            PREPARE stmt FROM @s;
            EXECUTE stmt;
            DEALLOCATE PREPARE stmt; 
            
            SET @resexpiry = null;    
            SET @s = CONCAT("SELECT user_expiry (", QUOTE(_uid),",",QUOTE(_nid), ") INTO @resexpiry");
            PREPARE stmt FROM @s;
            EXECUTE stmt;
            DEALLOCATE PREPARE stmt;

            UPDATE   _search_node SET privilege = @perm ,expiry_time = @resexpiry WHERE nid = _nid;

          END LOOP STARTLOOP; 
      CLOSE dbcursor;
    END; 
    
    
    SELECT * FROM _search_node WHERE (expiry_time = 0 OR expiry_time > UNIX_TIMESTAMP())
    ORDER BY score DESC, mtime ASC LIMIT _offset, _range;

    DROP TABLE IF EXISTS _search_node;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_get_bin_content` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_get_bin_content`(
  IN _id VARCHAR(16)
)
BEGIN
  DECLARE _node_path VARCHAR(255);
  DECLARE _category VARCHAR(40);
  DECLARE _home_dir VARCHAR(500);
  DECLARE _uid VARCHAR(16);

  
  
  

  DECLARE _db_name VARCHAR(50);
  DECLARE _finished INTEGER DEFAULT 0;
  DECLARE _hubid VARCHAR(16);
  

  
  
  
  

 
  SELECT id, home_dir FROM yp.entity WHERE db_name=database() INTO _uid, _home_dir;

  DROP TABLE IF EXISTS  _bin_media; 
  CREATE TEMPORARY TABLE `_bin_media` (
  `id` varchar(16) DEFAULT NULL,
  `hub_root` varchar(512) DEFAULT NULL,
  `owner_id` varchar(16) DEFAULT NULL,
  `mfs_root` varchar(500) DEFAULT NULL,
  `parent_id` varchar(16) NOT NULL DEFAULT '',
  `category`  varchar(16),  
  `privilege` tinyint(2) DEFAULT NULL,
  `user_filename` varchar(128) DEFAULT NULL,
  `parent_path` varchar(1024) DEFAULT NULL,
  `bound` varchar(128) DEFAULT '__Nobound__',
  `db_name` varchar(128) DEFAULT NULL
  ); 

  IF _id IS NULL OR _id="" OR _id='0' THEN
    INSERT INTO _bin_media  
    SELECT id, 
      (SELECT home_dir FROM yp.entity y WHERE y.id=m.id) AS hub_root,
      IFNULL((SELECT owner_id FROM yp.hub y WHERE y.id=m.id),_uid) AS owner_id,
      concat(_home_dir, "/__storage__/"), 
      parent_id,
      category, 
      user_permission(_uid, m.id) AS privilege, 
      user_filename, 
      concat(_home_dir, "/__storage__/", parent_path),
      '__Nobound__',
      IF(category='hub', 
        (SELECT db_name FROM yp.entity y WHERE y.id=m.id),
      database()) AS db_name
    FROM media m WHERE 
    parent_id NOT IN (SELECT id FROM media WHERE status='deleted')
    AND m.status='deleted';
    
    BEGIN
    DECLARE dbcursor CURSOR FOR  SELECT id, db_name FROM 
      yp.entity WHERE id IN(
         SELECT id FROM media m INNER JOIN permission p 
          ON p.resource_id = m.id AND p.permission>=15 AND m.status='active'
    );
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET _finished = 1;
    OPEN dbcursor;
     
      STARTLOOP: LOOP
        FETCH dbcursor INTO _hubid , _db_name ;
         IF _finished = 1 THEN 
            LEAVE STARTLOOP;
         END IF;    

        SET @sql = CONCAT("
          INSERT INTO _bin_media 
          SELECT 
            m.id,
            null as hub_root,
            null as owner_id,
            concat(e.home_dir, '/__storage__/'),
            parent_id,
            category,
            null as privilege,
            user_filename,
            concat(e.home_dir, '/__storage__/', parent_path) parent_path,
            '__Nobound__',
            " ,QUOTE(_db_name ),"
          FROM " ,_db_name ,".media m 
          INNER JOIN yp.entity e on e.id = ",QUOTE(_hubid),"  
         --  LEFT JOIN " ,_db_name ,".permission p on p.entity_id = ",QUOTE(_uid)," AND  p.resource_id = m.id
          WHERE 
         --  ( IFNULL(p.expiry_time,0) = 0 OR   IFNULL(p.expiry_time,0) > UNIX_TIMESTAMP() )
           parent_id NOT IN (SELECT id FROM " ,_db_name , ".media WHERE status='deleted')
          AND m.status='deleted'");
        PREPARE stmt FROM @sql ;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
      END LOOP STARTLOOP;   

    CLOSE dbcursor;
    END;
  ELSE
    INSERT INTO _bin_media 
    SELECT id, 
      (SELECT home_dir FROM yp.entity y WHERE y.id=m.id) AS hub_root,
      IFNULL((SELECT owner_id FROM yp.hub y WHERE y.id=m.id),_uid) AS owner_id,
      concat(_home_dir, "/__storage__/"),
      parent_id,
      category, 
      user_permission(_uid, _id) AS privilege, 
      user_filename, 
      concat(_home_dir, "/__storage__/", parent_path),
      null,
       IF(category='hub', 
        (SELECT db_name FROM yp.entity y WHERE y.id=m.id),
      database()) AS db_name
    FROM media m WHERE id=_id;

    BEGIN
    DECLARE dbcursor CURSOR FOR  SELECT id, db_name FROM  yp.entity WHERE id IN(
      SELECT id FROM media m INNER JOIN permission p 
          ON p.resource_id = m.id AND p.permission>=15 AND m.status='active');
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET _finished = 1;
    OPEN dbcursor;
     
      STARTLOOP: LOOP
        FETCH dbcursor INTO _hubid , _db_name ;
         IF _finished = 1 THEN 
            LEAVE STARTLOOP;
         END IF;    

        SET @sql = CONCAT("
          INSERT INTO _bin_media 
          SELECT 
            m.id,
            null as hub_root,
            null as owner_id,
            concat(e.home_dir, '/__storage__/'),
            parent_id,
            category,
            null as privilege,
            user_filename,
            concat(e.home_dir, '/__storage__/', parent_path) parent_path,
            '__Nobound__',
            " ,QUOTE(_db_name ),"
          FROM " ,_db_name ,".media m 
          INNER JOIN yp.entity e on e.id = ",QUOTE(_hubid),"  
          WHERE 
          m.id =" ,QUOTE(_id) );
        PREPARE stmt FROM @sql ;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
      END LOOP STARTLOOP;   

    CLOSE dbcursor;
    END;
  END IF;
  SELECT *  FROM _bin_media;
  DROP TABLE IF EXISTS _bin_media;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_get_by` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_get_by`(
  IN _nid VARCHAR(16)
)
BEGIN
    WITH RECURSIVE _tree AS
    (
      SELECT
        m.id, 
        m.id top_id, 
        m.filesize,
        m.parent_id
      FROM
        media m
        WHERE m.parent_id =  _nid AND status='active'
      UNION ALL
        SELECT
        m.id, 
        t.top_id,
        m.filesize,
        m.parent_id      
      FROM
        media  m
      INNER JOIN _tree  t ON m.parent_id = t.id
        AND m.status='active'
    )
    SELECT 
        m.id AS nid,
        s.filesize,
        m.parent_id AS pid,
        m.user_filename  filename,
        m.file_path as filepath,
        m.extension AS ext,
        m.category AS ftype,
        m.category AS filetype,
        m.upload_time AS ctime,
        m.publish_time AS mtime
    FROM media m
    INNER JOIN 
      (SELECT
         top_id id , sum(filesize) filesize  
      FROM _tree GROUP BY   top_id 
      ) s  ON s.id = m.id 
    WHERE m.parent_id =_nid;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_get_by_path` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_get_by_path`(
  IN _path VARCHAR(1024)
)
BEGIN
  SELECT * FROM media WHERE file_path=clean_path(_path);
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_get_dmz_link` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_get_dmz_link`( 
   IN _src_id VARCHAR(16),
   IN _uid VARCHAR(16)
)
BEGIN
DECLARE _rid VARCHAR(16);
DECLARE _eid VARCHAR(16);
DECLARE _vhost VARCHAR(255);
  
  SELECT m.id ,p.entity_id 
  FROM permission p 
  INNER JOIN media m ON 
    m.id = p.resource_id 
  WHERE m.id =_src_id 
    AND p.entity_id = _uid
    AND p.assign_via='link' 
    INTO _rid,_eid ;

  SELECT 
    d.firstname,
    d.lastname,
    d.email,
    _rid AS nid,
    _eid AS entity_id
  FROM yp.entity e
  INNER JOIN yp.hub sb on sb.id = e.id
  INNER JOIN yp.drumate d on d.id = sb.owner_id
  WHERE e.db_name= DATABASE() AND _rid IS NOT NULL AND _eid IS NOT NULL ;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_get_filenames` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_get_filenames`(
  IN _pid VARCHAR(16)CHARACTER SET ascii
)
BEGIN
  select id, user_filename `filename` FROM media WHERE parent_id=_pid;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_get_path` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_get_path`(
  IN _id VARCHAR(16)
)
    DETERMINISTIC
BEGIN
  DECLARE _nid VARCHAR(16);
  DECLARE _pid VARCHAR(16);
  DECLARE _fname VARCHAR(255);
  DECLARE _ppath VARCHAR(600);
  DECLARE _vhost VARCHAR(255);
  DECLARE _hub_id VARCHAR(16);
  DECLARE _area VARCHAR(50);
  DECLARE _home_dir VARCHAR(512);
  DECLARE _home_id VARCHAR(16);
  DECLARE _db_name VARCHAR(50);
  DECLARE _accessibility VARCHAR(16);
  DECLARE _ext varchar(50);  
 
  

  
  

  SELECT e.id, e.area, e.home_dir, m.id, e.db_name, e.accessibility from media m 
    INNER JOIN yp.entity e  ON e.db_name=database()
    WHERE parent_id='0' 
    INTO _hub_id, _area, _home_dir, _home_id, _db_name, _accessibility;

  DROP TABLE IF EXISTS  __media_path;  
  CREATE TEMPORARY TABLE `__media_path` (
    hub_id varchar(16) DEFAULT NULL,
    home_id varchar(16) DEFAULT NULL,
    nid varchar(16) DEFAULT NULL, 
    pid varchar(16) DEFAULT NULL, 
    filename varchar(1024) DEFAULT NULL, 
    parent_path varchar(1024) DEFAULT NULL,
    ext varchar(50) DEFAULT NULL,  
    area varchar(50) DEFAULT NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8;   

  SELECT m.id, m.parent_id, m.user_filename, m.parent_path,
    m.extension AS ext,
    IF(m.category='hub', m.extension, me.area)
    FROM media m
    INNER JOIN yp.entity me  ON me.db_name=database()
  WHERE m.id=_id INTO _nid, _pid, _fname, _ppath, _ext,_area;

  INSERT INTO __media_path 
    SELECT _hub_id, _home_id, _nid, _pid, _fname, _ppath,_ext,_area FROM media WHERE id=_id;

  WHILE _pid != "0" DO
    SELECT m.id, m.parent_id, m.user_filename, m.parent_path,
    m.extension AS ext,
    IF(m.category='hub', m.extension, me.area)
    FROM media m  
    INNER JOIN yp.entity me  ON me.db_name=database()
  WHERE m.id=_pid INTO _nid, _pid, _fname, _ppath, _ext,_area ;

  INSERT INTO __media_path SELECT _hub_id, _home_id, _nid, _pid, _fname, _ppath,_ext,_area;
  END WHILE;


  
  

  SELECT * FROM __media_path;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_home` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_home`(
)
BEGIN
  DECLARE _area VARCHAR(25);

  DECLARE _home_dir VARCHAR(500);
  DECLARE _name VARCHAR(500);

  DECLARE _home_id VARCHAR(16) CHARACTER SET ascii; 
  DECLARE _chat_upload_id VARCHAR(16) CHARACTER SET ascii; 
  DECLARE _chat_id VARCHAR(16) CHARACTER SET ascii; 
  DECLARE _ticket_id VARCHAR(16) CHARACTER SET ascii; 

  DECLARE _entity_id VARCHAR(16) CHARACTER SET ascii;
  SELECT id  FROM media WHERE parent_id='0' INTO _home_id;
  SELECT node_id_from_path('/__chat__/__upload__') INTO _chat_upload_id;
  SELECT node_id_from_path('/__chat__/') INTO _chat_id;
  SELECT node_id_from_path('/__ticket__/') INTO _ticket_id;
  
  SELECT id ,area, home_dir from yp.entity WHERE  db_name=database() INTO _entity_id, _area, _home_dir ; 
 
  SELECT name FROM  yp.hub  WHERE id = _entity_id  INTO _name;

  IF _name IS NULL THEN 
     SELECT CONCAT(firstname, ' ', lastname) FROM yp.drumate 
     WHERE id = _entity_id  INTO _name;
  END IF;
  
  IF _chat_id IS NULL THEN
    CALL mfs_make_dir(_home_id, JSON_ARRAY('__chat__'), 0);
    SELECT node_id_from_path('/__chat__/') INTO _chat_id;
  END IF;

  IF _chat_upload_id IS NULL THEN
    CALL mfs_make_dir(_home_id, JSON_ARRAY('__chat__', '__upload__'), 0);
    SELECT node_id_from_path('/__chat__/__upload__') INTO _chat_upload_id;
  END IF;
  
  SELECT utils.vhost(_entity_id) vhost, 
    _entity_id AS hub_id, 
    _area area, 
    _home_dir home_dir, 
    _name AS `name`,
    _home_id AS home_id,
    _chat_upload_id chat_upload_id,
    _chat_id  chat_id,
    _ticket_id ticket_id;
    
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_hub_chat_init` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_hub_chat_init`()
BEGIN
 
  SELECT node_id_from_path('/__chat__') INTO @temp_chat_id;

  IF @temp_chat_id IS NULL THEN 
    call mfs_make_dir("0", JSON_ARRAY('__chat__'), 0);
    UPDATE media SET status='hidden' where file_path='/__chat__.folder';
  END IF;
  
  SELECT node_id_from_path('/__chat__') INTO @temp_chat_id;
  SELECT node_id_from_path('/__chat__/__upload__') INTO @temp_upload_id;

 
  IF @temp_upload_id IS NULL THEN 
    CALL mfs_make_dir(@temp_chat_id, JSON_ARRAY("__upload__"), 0);
    UPDATE media set status='hidden' where file_path='/__chat__/__upload__.folder';
  END IF;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_import` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_import`(
  IN _nodes JSON,
  IN _uid VARCHAR(16) CHARACTER SET ascii
)
BEGIN

    DECLARE _idx INT(4) DEFAULT 0; 
    DECLARE _id              VARCHAR(16) CHARACTER SET ascii;                                                                            
    DECLARE _origin_id       VARCHAR(16) CHARACTER SET ascii;                                                                            
    DECLARE _owner_id        VARCHAR(16) CHARACTER SET ascii;                                                                          
    DECLARE _host_id         VARCHAR(16) CHARACTER SET ascii;                                                                         
    DECLARE _file_path       VARCHAR(1000);                                                                         
    DECLARE _user_filename   VARCHAR(128);                                                                       
    DECLARE _parent_id       VARCHAR(16) CHARACTER SET ascii;                                                                        
    DECLARE _parent_path     VARCHAR(1024);                                                                        
    DECLARE _extension       VARCHAR(100);                                                                       
    DECLARE _mimetype        VARCHAR(100);                                                                        
    DECLARE _category        VARCHAR(16);                                                                         
    DECLARE _isalink         TINYINT(2) ;                                                              
    DECLARE _filesize        BIGINT(20) ;                                                                
    DECLARE _geometry        VARCHAR(200);                                                                           
    DECLARE _publish_time    INT(11) ;                                                                    
    DECLARE _upload_time     INT(11) ;                                                                          
    DECLARE _last_download   INT(11) ;                                                                 
    DECLARE _download_count  MEDIUMINT(8) ;                                                              
    DECLARE _metadata        LONGTEXT  ;                                                                             
    DECLARE _caption         VARCHAR(1024);                                                                         
    DECLARE _status          VARCHAR(20);                                                                            
    DECLARE _rank            INT(11);  
    DECLARE _ts   INT(11) DEFAULT 0;
    
    SELECT UNIX_TIMESTAMP() INTO _ts;

    WHILE _idx < JSON_LENGTH(_nodes) DO 
      SELECT get_json_array(_nodes, _idx) INTO @_node;
      SELECT get_json_object(@_node, "id") INTO _id;
      SELECT get_json_object(@_node, "parent_id") INTO _parent_id;
      SELECT get_json_object(@_node, "file_path") INTO _file_path;
      SELECT get_json_object(@_node, "parent_path") INTO _parent_path;
      SELECT get_json_object(@_node, "user_filename") INTO _user_filename;
      SELECT get_json_object(@_node, "extension") INTO _extension;
      SELECT get_json_object(@_node, "mimetype") INTO _mimetype;
      SELECT get_json_object(@_node, "category") INTO _category;
      SELECT get_json_object(@_node, "filesize") INTO _filesize;

      SELECT JSON_OBJECT('_seen_', JSON_OBJECT(_uid, UNIX_TIMESTAMP()))  INTO _metadata WHERE _category != 'folder' ;

      INSERT INTO `media` (
          id, 
          origin_id, 
          owner_id,
          file_path, 
          user_filename, 
          parent_id, 
          parent_path,
          extension, 
          mimetype, 
          category,
          isalink,
          filesize, 
          `geometry`, 
          publish_time, 
          upload_time, 
          `status`,
          rank,
          metadata
        )
      VALUES (
          _id, 
          _id, 
          _id,
          _file_path, 
          TRIM('/' FROM _user_filename),
          _parent_id, 
          _parent_path,
          _extension, 
          _mimetype, 
          _category, 
          0,
          IFNULL(_filesize, 4096),
          IFNULL( '0x0', '0x0'), 
          _ts, 
          _ts, 
          'active',
          1,
          _metadata
        );


      SELECT NULL INTO _id;
      SELECT NULL INTO _parent_id;
      SELECT NULL INTO _file_path;
      SELECT NULL INTO _parent_path;
      SELECT NULL INTO _user_filename;
      SELECT NULL INTO _extension;
      SELECT NULL INTO _mimetype;
      SELECT NULL INTO _category;


      SELECT _idx + 1 INTO _idx;

  END WHILE; 

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_init_folders` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_init_folders`(
  IN _folders JSON,
  IN _clear_existing boolean
)
BEGIN
  DECLARE _i INT(4) DEFAULT 0; 
  DECLARE _pid VARCHAR(16);
  DECLARE _home_id VARCHAR(16);
  DECLARE _uid VARCHAR(16);
  DECLARE _status VARCHAR(16);
  DECLARE _path TEXT;
  SELECT id FROM media WHERE parent_id='0' INTO _home_id;
  IF _clear_existing THEN 
    DELETE FROM media WHERE status='active' AND parent_id=_home_id;
    SELECT id FROM yp.entity WHERE db_name=database() INTO _uid;
    UPDATE media SET origin_id=_uid;
  END IF;
  WHILE _i < JSON_LENGTH(_folders) DO 
    SELECT JSON_EXTRACT(_folders, CONCAT("$[", _i, "]")) INTO @_node;
    SELECT JSON_VALUE(@_node, "$.path") INTO _path;
    SELECT TRIM(TRAILING '/' FROM TRIM(LEADING '/' FROM _path)) INTO _path;
    SELECT IFNULL(JSON_VALUE(@_node, "$.pid"), _home_id) INTO _pid;
    SELECT IFNULL(JSON_VALUE(@_node, "$.status"), 'active') INTO _status;
    CALL mfs_make_dir(_pid, JSON_ARRAY(_path), 0);

    SELECT _i + 1 INTO _i;
  END WHILE;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_list_all` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_list_all`(
  IN _node_id VARCHAR(16),
  IN _page TINYINT(4)
)
BEGIN

  DECLARE _range bigint;
  DECLARE _offset bigint;
  DECLARE _vhost VARCHAR(255);
  DECLARE _hub_id VARCHAR(16);
  DECLARE _area VARCHAR(50);
  DECLARE _home_dir VARCHAR(512);
  DECLARE _home_id VARCHAR(16);
  DECLARE _db_name VARCHAR(50);
  DECLARE _accessibility VARCHAR(16);

  CALL pageToLimits(_page, _offset, _range);
  CALL mediaEnv(_vhost, _hub_id, _area, _home_dir, _home_id, _db_name, _accessibility);

  SELECT
    media.id  AS nid,
    parent_id AS pid,
    parent_id AS parent_id,
    _hub_id AS holder_id,
    _home_id AS home_id,
    IF(media.category='hub', 
      (SELECT id FROM yp.entity WHERE entity.id=media.id), _hub_id
    ) AS oid,    
    caption,
    capability,
    IF(media.category='hub', (
      SELECT accessibility FROM yp.entity WHERE entity.id=media.id), _accessibility
    ) AS accessibility,
    IF(media.category='hub', (
      SELECT status FROM yp.entity WHERE entity.id=media.id), status
    ) AS status,
    media.extension AS ext,
    media.category AS ftype,
    media.category AS filetype,
    media.mimetype,
    download_count AS view_count,
    geometry,
    upload_time AS ctime,
    publish_time AS ptime,
    parent_path,
    IF(parent_path='' or parent_path is NULL , '/', parent_path) AS user_path,
    IF(media.category='hub', (
      SELECT `name` FROM yp.hub WHERE hub.id=media.id), user_filename
    ) AS filename,
    IF(media.category='hub', (
      SELECT space FROM yp.entity WHERE entity.id=media.id), filesize
    ) AS filesize,
    firstname,
    lastname,
    remit,
    IF(media.category='hub', (
      SELECT utils.vhost(ident) FROM yp.entity WHERE entity.id=media.id), _vhost
    ) AS vhost,    
    
    
    
    _page as page,
    IF(media.category='hub', media.extension, _area) AS area
  FROM  media LEFT JOIN (yp.filecap, yp.drumate) ON 
  media.extension=filecap.extension AND origin_id=yp.drumate.id 
  WHERE parent_id=_node_id AND status='active'
  ORDER BY ctime DESC LIMIT _offset, _range;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_list_by` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_list_by`(
  IN _args JSON
)
BEGIN

  DECLARE _range bigint;
  DECLARE _offset bigint;
  DECLARE _sort VARCHAR(20);  
  DECLARE _pid VARCHAR(2000);
  DECLARE _order VARCHAR(20);
  DECLARE _type VARCHAR(20);
  DECLARE _page TINYINT(4);

  SELECT IFNULL(JSON_VALUE(_args, '$.page'), 1) INTO _page ;
  SELECT IFNULL(JSON_VALUE(_args, '$.sort'), "name") INTO _sort ;
  SELECT IFNULL(JSON_VALUE(_args, '$.order'), "asc") INTO _order ;
  SELECT IFNULL(JSON_VALUE(_args, '$.type'), "") INTO _type ;
  SELECT IFNULL(JSON_VALUE(_args, '$.pid'), "*") INTO _pid ;

  IF _pid REGEXP "^/.+" THEN 
    SELECT id FROM media WHERE file_path = clean_path(_node_id) INTO _pid;
  END IF;

  CALL pageToLimits(_page, _offset, _range);
  IF _pid = "*" THEN 
    SELECT
      m.id  AS nid,
      parent_id AS pid,
      parent_id AS parent_id,
      origin_id AS gid,
      file_path,
      file_path filepath,
      capability,
      m.status AS status,
      m.extension AS ext,
      m.category AS ftype,
      m.category AS filetype,
      m.mimetype,
      download_count AS view_count,
      geometry,
      upload_time AS ctime,
      publish_time AS ptime,
      user_filename AS filename,
      parent_path,
      filesize,
      firstname,
      lastname,
      remit,
      _page as page,
      me.area,
      me.id as hub_id,
      me.home_id,
      COALESCE(vv.fqdn, v.fqdn) AS vhost
    FROM  media m 
      INNER JOIN yp.entity me  ON me.db_name=database()
      LEFT JOIN yp.filecap f ON m.extension=f.extension
      LEFT JOIN yp.drumate dr ON origin_id=dr.id 
      LEFT JOIN yp.vhost v ON  v.id=me.id
      LEFT JOIN yp.vhost vv ON  vv.id=m.id

    WHERE m.category=_type AND 
      m.file_path NOT REGEXP '^/__(chat|trash|upload)__' AND 
      m.`status` NOT IN ('hidden', 'deleted')
    ORDER BY 
      CASE WHEN LCASE(_sort) = 'date' and LCASE(_order) = 'asc' THEN ctime END ASC,
      CASE WHEN LCASE(_sort) = 'date' and LCASE(_order) = 'desc' THEN ctime END DESC,
      CASE WHEN LCASE(_sort) = 'name' and LCASE(_order) = 'asc' THEN filename END ASC,
      CASE WHEN LCASE(_sort) = 'name' and LCASE(_order) = 'desc' THEN filename END DESC,
      CASE WHEN LCASE(_sort) = 'rank' and LCASE(_order) = 'asc' THEN rank END ASC,
      CASE WHEN LCASE(_sort) = 'rank' and LCASE(_order) = 'desc' THEN rank END DESC,
      CASE WHEN LCASE(_sort) = 'size' and LCASE(_order) = 'asc' THEN filesize END ASC,
      CASE WHEN LCASE(_sort) = 'size' and LCASE(_order) = 'desc' THEN filesize END DESC
    LIMIT _offset ,_range;

  ELSE
    SELECT
      m.id  AS nid,
      parent_id AS pid,
      parent_id AS parent_id,
      origin_id AS gid,
      file_path,
      file_path filepath,
      capability,
      m.status AS status,
      m.extension AS ext,
      m.category AS ftype,
      m.category AS filetype,
      m.mimetype,
      download_count AS view_count,
      geometry,
      upload_time AS ctime,
      publish_time AS ptime,
      user_filename AS filename,
      parent_path,
      filesize,
      firstname,
      lastname,
      remit,
      _page as page,
      me.area,
      me.id as hub_id,
      me.home_id,
      COALESCE(vv.fqdn, v.fqdn) AS vhost
    FROM  media m 
      INNER JOIN yp.entity me  ON me.db_name=database()
      LEFT JOIN yp.filecap f ON m.extension=f.extension
      LEFT JOIN yp.drumate dr ON origin_id=dr.id 
      LEFT JOIN yp.vhost v ON  v.id=me.id
      LEFT JOIN yp.vhost vv ON  vv.id=m.id

    WHERE m.category=_type AND parent_id=_pid AND 
      m.file_path not REGEXP '^/__(chat|trash|upload)__' AND 
      m.`status` NOT IN ('hidden', 'deleted')
    ORDER BY 
      CASE WHEN LCASE(_sort) = 'date' and LCASE(_order) = 'asc' THEN ctime END ASC,
      CASE WHEN LCASE(_sort) = 'date' and LCASE(_order) = 'desc' THEN ctime END DESC,
      CASE WHEN LCASE(_sort) = 'name' and LCASE(_order) = 'asc' THEN filename END ASC,
      CASE WHEN LCASE(_sort) = 'name' and LCASE(_order) = 'desc' THEN filename END DESC,
      CASE WHEN LCASE(_sort) = 'rank' and LCASE(_order) = 'asc' THEN rank END ASC,
      CASE WHEN LCASE(_sort) = 'rank' and LCASE(_order) = 'desc' THEN rank END DESC,
      CASE WHEN LCASE(_sort) = 'size' and LCASE(_order) = 'asc' THEN filesize END ASC,
      CASE WHEN LCASE(_sort) = 'size' and LCASE(_order) = 'desc' THEN filesize END DESC
    LIMIT _offset ,_range;
  END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_list_dir` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_list_dir`(
  IN _node_id VARCHAR(16),
  IN _page TINYINT(4)
)
BEGIN

  DECLARE _range bigint;
  DECLARE _offset bigint;
  CALL pageToLimits(_page, _offset, _range);

  SELECT
    media.id  AS nid,
    parent_id AS pid,
    parent_id AS parent_id,
    origin_id AS gid,
    caption,
    media.status AS status,
    extension AS ext,
    media.category AS ftype,
    media.category AS filetype,
    mimetype,
    download_count AS view_count,
    IF(parent_id='0', 'root', 'branch') as npos,
    geometry,
    upload_time AS ctime,
    publish_time AS ptime,
    user_filename AS filename,
    parent_path,
    IF(parent_path='' or parent_path is NULL , '/', parent_path) AS user_path,
    file_path,
    filesize,
    firstname,
    lastname,
    gender,
    remit,
    _page as page,
    concat(@root, file_path) AS file_path,
    @area as area
  FROM media inner join yp.drumate on origin_id=drumate.id WHERE parent_id=_node_id AND media.category='folder'
  ORDER BY ctime DESC LIMIT _offset, _range;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_log_stats` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_log_stats`(
  IN _nid VARCHAR(16),
  IN _uid VARCHAR(16),
  IN _sid VARCHAR(128)
)
BEGIN
  DECLARE _oid  VARCHAR(16) DEFAULT NULL;
  SELECT owner_id FROM media WHERE id=_nid INTO _oid;
  IF _oid != _uid THEN 
    INSERT INTO media_stats VALUES(null, _nid, _uid, _sid, UNIX_TIMESTAMP());
  END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_make_dir` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_make_dir`(
  IN _pid TEXT,
  IN _rel_path JSON,
  IN _show_results  BOOLEAN
)
BEGIN

  DECLARE _idx INT(4) DEFAULT 0;
  DECLARE _parent_path TEXT DEFAULT '/'; 
  DECLARE _file_name VARCHAR(80);
  DECLARE _file_path TEXT DEFAULT NULL;
  DECLARE _temp_nid  VARCHAR(16);
  DECLARE _parent_id  VARCHAR(16);
  DECLARE _nid  VARCHAR(16) DEFAULT null;
  DECLARE _hub_id VARCHAR(16);
  DECLARE _home_id VARCHAR(16);
  DECLARE _rollback BOOLEAN DEFAULT 0;

  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
  BEGIN
    SET _rollback = 1;  
    GET DIAGNOSTICS CONDITION 1 
      @sqlstate = RETURNED_SQLSTATE, 
      @errno = MYSQL_ERRNO, 
      @message = MESSAGE_TEXT;
  END;

  START TRANSACTION;

  SELECT id FROM media WHERE parent_id='0' INTO _home_id;

  IF _pid REGEXP "^/" THEN 
    SELECT id, file_path FROM media WHERE file_path=clean_path(_pid) 
      INTO _pid, _file_path;
  END IF; 

  IF _file_path IS NULL THEN 
    SELECT REGEXP_REPLACE(file_path, '\\\.folder$', '')
      FROM media WHERE id = _pid INTO _file_path;
  END IF; 

  IF _file_path IS NULL THEN 
    SELECT _home_id, '' INTO _parent_id, _file_path;
  ELSE 
    SELECT _pid INTO _parent_id;
  END IF;
  
  IF JSON_LENGTH(_rel_path) IS NULL THEN
    SELECT JSON_ARRAY(_rel_path) INTO _rel_path;
  END IF;

  WHILE _idx < JSON_LENGTH(_rel_path) DO 
    SELECT JSON_VALUE(_rel_path, CONCAT("$[", _idx, "]")) INTO _file_name;
    SELECT _idx + 1 INTO _idx;
    IF _file_name != '' THEN 
      SELECT _file_path INTO _parent_path;
      SELECT clean_path(CONCAT(_file_path, '/', _file_name)) INTO _file_path;
      SELECT NULL INTO _nid;
      
      SELECT id FROM media WHERE file_path = _file_path INTO _nid;
      IF _nid IS NULL THEN
        SELECT yp.uniqueId() INTO _temp_nid;
        INSERT INTO `media` (
          id, 
          origin_id, 
          file_path, 
          user_filename, 
          parent_id, 
          parent_path,

          extension, 
          mimetype, 
          category,
          isalink,

          filesize, 
          `geometry`, 
          publish_time, 
          upload_time, 

          `status`,
          rank
        ) VALUES (
          _temp_nid,
          _hub_id, 
          _file_path,
          TRIM('/' FROM _file_name),
          _parent_id, 
          _parent_path,

          '', 
          'folder', 
          'folder', 
          0,

          0,
          '0x0', 
          UNIX_TIMESTAMP(), 
          UNIX_TIMESTAMP(), 

          'active',
          0
        );
        SELECT _temp_nid INTO _parent_id;
      ELSE 
        SELECT id, parent_path, file_path FROM media WHERE id = _nid 
          INTO _parent_id, _parent_path, _file_path;
        SELECT _nid INTO _temp_nid;
      END IF;
    END IF;
  END WHILE;


  IF _rollback THEN
    ROLLBACK;
    SELECT 1 failed, 
      @sqlstate AS `sqlstate`,
      @errno AS `errno`,
      CONCAT(DATABASE(), ":", @message) AS `message`;
  ELSE
    COMMIT;
    IF IFNULL(_show_results, 1) = 1  THEN
      CALL mfs_node_attr(_temp_nid);
    END IF;  
  END IF;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_manifest` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_manifest`(
  IN _nid VARCHAR(16),
  IN _uid VARCHAR(16),
  IN _show_nodes TINYINT
)
BEGIN
  DECLARE _filepath TEXT DEFAULT NULL;
  DECLARE _db_name VARCHAR(80) DEFAULT NULL;
  DECLARE _home_dir VARCHAR(2000) DEFAULT NULL;
  DECLARE _eid VARCHAR(16) DEFAULT NULL;
  DECLARE _owner_id VARCHAR(16) DEFAULT NULL;
  DECLARE _home_id VARCHAR(16) DEFAULT NULL;
  DECLARE _name VARCHAR(80) DEFAULT NULL;

  DROP TABLE IF EXISTS __tmp_manifest;
  SELECT e.home_dir, e.home_id, e.id, COALESCE(h.name, d.fullname), 
    COALESCE(h.owner_id, d.id)  FROM yp.entity e
    LEFT JOIN yp.hub h ON e.id = h.id AND e.type='hub'
    LEFT JOIN yp.drumate d ON e.id = d.id AND e.type='drumate'
    WHERE e.db_name=database() INTO _home_dir, _home_id, _eid, _name, _owner_id;

  CREATE TEMPORARY TABLE __tmp_manifest AS SELECT 
    id, 
    _owner_id AS owner_id,
    _home_dir AS home_dir, 
    _home_id AS home_id, 
    _eid AS hub_id, 
    file_path as filepath, 
    parent_id AS pid, 
    status, 
    filesize,
    user_filename, 
    extension, 
    isalink,
    upload_time AS ctime,
    publish_time AS mtime,
    metadata,
    0 AS privilege,
    category
  FROM media where 1=2;
  ALTER TABLE __tmp_manifest ADD sys_id INT PRIMARY KEY AUTO_INCREMENT;
  ALTER TABLE __tmp_manifest ADD ownpath VARCHAR(2000) AFTER filepath;
  ALTER TABLE __tmp_manifest ADD UNIQUE KEY `hub_id` (`id`, `hub_id`);
  REPLACE INTO __tmp_manifest
    WITH RECURSIVE __parent_tree AS
    (
      SELECT
        m.id, 
        _owner_id,
        _home_dir AS home_dir, 
        IF(m.category = 'hub', (SELECT home_id FROM yp.entity e WHERE e.id=m.id), _home_id ) home_id,
        _eid AS hub_id,
        m.file_path,
        m.file_path  AS ownpath,
        m.parent_id,
        m.status, 
        m.filesize,
        m.user_filename, 
        m.extension, 
        m.isalink,
        m.upload_time AS ctime,
        m.publish_time AS mtime,
        m.metadata,
        user_permission(_uid, m.id ) privilege,
        m.category, 
        null
      FROM
        media m
        WHERE m.id = _nid 
        AND  m.status IN('active', 'locked')
      UNION ALL
        SELECT
        m.id, 
        _owner_id,
        _home_dir AS home_dir, 
        IF(m.category = 'hub', (SELECT home_id FROM yp.entity e WHERE e.id=m.id), _home_id ) home_id,
        _eid AS hub_id,
        m.file_path,
        m.file_path AS ownpath,
        m.parent_id,
        m.status, 
        m.filesize,
        m.user_filename, 
        m.extension, 
        m.isalink,
        m.upload_time AS ctime,
        m.publish_time AS mtime,
        m.metadata,
        user_permission(_uid, m.id ) privilege,
        m.category,
        null
      FROM
        media AS m
      INNER JOIN __parent_tree AS t ON m.parent_id = t.id AND 
        t.category IN('folder',  'root') AND  m.status IN('active', 'locked')
    )
    SELECT * FROM __parent_tree ;

  BEGIN
    DECLARE _finished INTEGER DEFAULT 0;
    DECLARE dbcursor CURSOR FOR SELECT e.id, e.home_dir, filepath,
      db_name FROM __tmp_manifest m
      INNER JOIN (yp.entity e, permission p) ON m.id=e.id AND p.resource_id=m.id 
      WHERE m.category='hub' AND 
      JSON_VALUE(e.settings, "$.syncForbiden") IS NULL AND
      permission&2;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET _finished = 1; 
    OPEN dbcursor;
      STARTLOOP: LOOP
        FETCH dbcursor INTO _eid, _home_dir, _filepath, _db_name;
        IF _finished = 1 THEN 
          LEAVE STARTLOOP;
        END IF;  

        SELECT COALESCE(h.owner_id, d.id), e.home_id FROM yp.entity e
          LEFT JOIN yp.hub h ON e.id = h.id AND e.type='hub'
          LEFT JOIN yp.drumate d ON e.id = d.id AND e.type='drumate'
          WHERE e.db_name=_db_name INTO _owner_id, _home_id;

        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        SET @s = CONCAT(
          "REPLACE INTO __tmp_manifest SELECT id, ?, ?, ?, ?, CONCAT(?, file_path), ", 
          "file_path, parent_id, status, filesize, user_filename, extension, isalink, 
          upload_time AS ctime, publish_time AS mtime, metadata,",
          _db_name, ".user_permission(?, id ) AS privilege, category, null FROM ", 
          _db_name, ".media WHERE extension !='root' AND status IN('active', 'locked')", 
          " AND NOT file_path REGEXP '(/__trash__/|/__chat__/)'");
        
        IF @s IS NOT NULL THEN 
          PREPARE stmt FROM @s;
          EXECUTE stmt USING _owner_id, _home_dir, _home_id, _eid, _filepath, _uid;
          DEALLOCATE PREPARE stmt;
        END IF;

       END LOOP STARTLOOP;
    CLOSE dbcursor;
  END;

  IF _show_nodes > 0 THEN 
    SELECT 
      id AS nid, 
      owner_id,
      REGEXP_REPLACE(home_dir, '^/+', '') AS home_dir, 
      home_id,
      REGEXP_REPLACE(filepath, '/+', '/') filepath, 
      REGEXP_REPLACE(ownpath, '/+', '/') ownpath, 
      IF(m.category='hub', id, hub_id) AS hub_id,
      status, 
      filesize, 
      IFNULL(REGEXP_REPLACE(user_filename, '<.*\>', ''), _name) AS filename, 
      
      pid,
      m.extension AS ext, 
      isalink,
      ctime,
      if(mtime < ctime, ctime, mtime) AS mtime,
      JSON_VALUE(metadata, "$.md5Hash") AS md5Hash,
      privilege,
      COALESCE(fc.category, m.category) filetype
    FROM __tmp_manifest m 
      LEFT JOIN yp.filecap fc ON m.extension=fc.extension
      WHERE NOT filepath REGEXP '(/__trash__/|/__chat__/)' AND
        m.category NOT IN('root') AND home_id IS NOT NULL;
  END IF;

  SELECT sum(filesize) AS total_size FROM __tmp_manifest;
  SELECT IF(user_filename = '' OR user_filename IS NULL, _name, user_filename) AS filename 
    FROM media WHERE id=_nid;
  SELECT count(*) AS amount, sum(filesize) AS size_per_type, category 
    FROM __tmp_manifest WHERE owner_id = _uid AND category NOT IN('root', 'folder') 
    GROUP BY category;
  SELECT sum(filesize) AS used_size FROM __tmp_manifest 
    WHERE owner_id = _uid AND category NOT IN('root', 'folder');

  DROP TABLE IF EXISTS __tmp_manifest;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_mark_as_seen` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_mark_as_seen`(
  IN _id     VARCHAR(16),
  IN _uid    VARCHAR(16),
  IN _show_results BOOLEAN
)
BEGIN
  DECLARE _md JSON;
  DECLARE _seen INT(11) DEFAULT NULL;
  SELECT metadata FROM media WHERE id=_id INTO _md;
  IF _md IS NULL THEN 
    UPDATE media SET metadata=JSON_OBJECT('_seen_', JSON_OBJECT(_uid, UNIX_TIMESTAMP())) WHERE id=_id;
  END IF;
  SELECT metadata FROM media WHERE id=_id INTO _md;
  IF NOT JSON_EXISTS(_md, CONCAT("$._seen_.", _uid)) THEN 
    UPDATE media SET metadata=JSON_MERGE(metadata, JSON_OBJECT('_seen_', JSON_OBJECT(_uid, UNIX_TIMESTAMP()))) WHERE id=_id;
  ELSE 
    UPDATE media SET metadata=JSON_REPLACE(metadata, CONCAT("$._seen_.", _uid), UNIX_TIMESTAMP()) WHERE id=_id;
  END IF;
  IF _show_results THEN 
    SELECT metadata FROM media WHERE id=_id;
  END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_media_replace` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_media_replace`(
  IN _origin_id       VARCHAR(16),
  IN _id              VARBINARY(16),
  IN _user_filename   VARCHAR(80),
  IN _category        VARCHAR(50),
  IN _extension       VARCHAR(100),
  IN _mimetype        VARCHAR(100),
  IN _filesize        INT(11) UNSIGNED,
  IN _geometry        VARCHAR(200),
  IN _metadata        VARCHAR(1024),
  IN _caption         VARCHAR(1024)
)
BEGIN
  DECLARE _ts   INT(11) DEFAULT 0;

  SELECT UNIX_TIMESTAMP() INTO _ts;
  UPDATE media SET 
    origin_id     = _origin_id,
    user_filename = _user_filename,
    category      = _category,
    extension     = _extension,
    mimetype      = _mimetype,
    filesize      = _filesize,
    geometry      = _geometry,
    metadata      = _metadata,
    caption       = _caption,
    upload_time   = _ts
  WHERE id = _id;

  SELECT 
    id, 
    origin_id, 
    parent_id,
    file_path, 
    user_filename,
    parent_path, extension, mimetype, category, isalink, filesize,
    geometry, publish_time, upload_time, last_download, download_count,
    metadata, caption, status, approval FROM media WHERE id = _id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_merge_tree` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_merge_tree`(
  IN _nid VARCHAR(16),
  IN _pid VARCHAR(16),
  IN _recipient_id VARCHAR(16)
)
BEGIN
   
  DECLARE _src_db VARCHAR(255);
  DECLARE _des_db VARCHAR(255); 


  DECLARE _origin_id      VARCHAR(16);   
  DECLARE _src_path       VARCHAR(1024); 
  DECLARE _des_path       VARCHAR(1024); 
  DECLARE _file_name      VARCHAR(512); 
  DECLARE _category       VARCHAR(50);   
  DECLARE _extension      VARCHAR(100); 
  DECLARE _mimetype       VARCHAR(100);      
  DECLARE _file_size      INT(20) UNSIGNED;
  DECLARE _geometry       VARCHAR(200);       
  DECLARE _status         VARCHAR(50); 
  DECLARE _finished       INTEGER DEFAULT 0;
  DECLARE _seq            INTEGER;  
  DECLARE _id             VARCHAR(16);  

  
  SELECT  database() INTO _src_db;  
  SELECT db_name FROM yp.entity WHERE id=_recipient_id OR ident =_recipient_id INTO _des_db;

  SET @sql = CONCAT( 
    "SELECT CONCAT(" ,_src_db ,".parent_path(id),user_filename, '/') FROM " ,_src_db ,".media WHERE id =" ,QUOTE( _nid),
    "INTO @srcpattern ");
  PREPARE stmt FROM @sql;
  EXECUTE stmt;


   SET @sql = CONCAT( 
    "SELECT CONCAT(" ,_des_db ,".parent_path(id),user_filename, '/') FROM " ,_des_db ,".media WHERE id =" ,QUOTE( _pid),
    "INTO @descpattern ");
  PREPARE stmt FROM @sql;
  EXECUTE stmt;  


  SET @sql = CONCAT( 
    "SELECT CONCAT(" ,_des_db ,".parent_path(id),user_filename) FROM " ,_des_db ,".media WHERE id =" ,QUOTE( _pid),
    "INTO @despath ");
  PREPARE stmt FROM @sql;
  EXECUTE stmt;

  SELECT  clean_path(@srcpattern) INTO @srcpattern; 
  SELECT  clean_path(@despath) INTO @srcpath; 
  SELECT  clean_path(@descpattern) INTO @descpattern;   
  
    DROP TABLE IF EXISTS  _src_media;
    CREATE TEMPORARY TABLE `_src_media` (
      `seq`  int NOT NULL AUTO_INCREMENT,
      `id` varchar(16) DEFAULT NULL,
      `origin_id` varchar(16) DEFAULT NULL,
      `user_filename` varchar(128) DEFAULT NULL,
      `category`      VARCHAR(50) DEFAULT NULL,
      `parent_id` varchar(16) DEFAULT '',
      `extension` varchar(100) NOT NULL DEFAULT '',
      `mimetype` varchar(100) NOT NULL,
      `filesize` int(20) unsigned NOT NULL DEFAULT '0',
      `geometry` varchar(200) NOT NULL DEFAULT '0x0',
      `xpath` varchar(5000) DEFAULT ''  ,
      `new_id` varchar(16) DEFAULT NULL,  
      `new_parent_id` varchar(16) DEFAULT '' , 
      `is_checked` boolean default 0 ,
       lvl int(3),
       PRIMARY KEY `seq`(`seq`)  
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
    
    DROP TABLE IF EXISTS _des_media;
    CREATE TEMPORARY TABLE `_des_media` (
      
      `id` varchar(16) DEFAULT NULL,
      `origin_id` varchar(16) DEFAULT NULL,
      `user_filename` varchar(128) DEFAULT NULL,
      `category`      VARCHAR(50) DEFAULT NULL,
      `parent_id` varchar(16) DEFAULT '',
      `extension` varchar(100) NOT NULL DEFAULT '',
      `mimetype` varchar(100) NOT NULL,
      `filesize` int(20) unsigned NOT NULL DEFAULT '0',
      `geometry` varchar(200) NOT NULL DEFAULT '0x0',
      `xpath` varchar(5000) DEFAULT '' 
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
    
   

  SET @sql = CONCAT(" 
    INSERT INTO _src_media 
    SELECT null, id,origin_id,user_filename,category,parent_id, extension,mimetype,filesize,geometry,
    clean_path(CONCAT(" ,_des_db ,".parent_path(id),'/',user_filename,'.', extension )) xpath     
    ,null,null,0,0
    FROM  " ,_src_db ,".media m 
    WHERE   m.category <> 'hub' AND CONCAT(" ,_src_db ,".parent_path(id),user_filename,'/' ) 
    LIKE CONCAT(@srcpattern,'%') ");
  PREPARE stmt FROM @sql;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;

  SET @sql = CONCAT(" 
    INSERT INTO _des_media
    SELECT  id,origin_id,user_filename,category,parent_id, extension,mimetype,filesize,geometry,
    clean_path(REPLACE (clean_path(CONCAT(" ,_des_db ,".parent_path(id),'/',user_filename,'.',extension )),@despath,'' )) xpath 
    FROM  " ,_des_db ,".media m      	
    WHERE id <> ", QUOTE( _pid) ,"
    AND CONCAT(" ,_des_db ,".parent_path(id),user_filename,'/' ) 
    LIKE CONCAT(@descpattern,'%')");
  PREPARE stmt FROM @sql;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;  

 UPDATE _src_media SET new_parent_id = _pid where id = _nid; 

 UPDATE _src_media s , _des_media d SET s.new_parent_id = d.parent_id , s.new_id=d.id
 WHERE  s.xpath = d.xpath;

 DROP TABLE IF EXISTS _src_temp_media;
 CREATE TABLE _src_temp_media as SELECT * FROM _src_media;

 UPDATE _src_media s , _src_temp_media d SET s.new_parent_id = d.new_id  WHERE  s.parent_id = d.id;

 UPDATE _src_media set lvl= (LENGTH(xpath)-LENGTH(REPLACE(xpath, '/', '')));

 BEGIN
    DECLARE dbcursor CURSOR FOR SELECT seq,id,origin_id,user_filename,category,extension,mimetype,`geometry`,filesize FROM _src_media WHERE new_id is null order by lvl asc;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET _finished = 1;
    OPEN dbcursor;
        STARTLOOP: LOOP
         FETCH dbcursor INTO _seq,_id,_origin_id,_file_name,_category,_extension,_mimetype,_geometry,_file_size;
         IF _finished = 1 THEN 
            LEAVE STARTLOOP;
         END IF;


    
        SET @s1 = CONCAT( "CREATE TEMPORARY TABLE IF NOT EXISTS  ",_des_db,".__register_stack LIKE template.tmp_media"); 
        PREPARE stmt FROM @s1;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

        SET @s1 = CONCAT( "DELETE FROM ",_des_db,".__register_stack"); 
        PREPARE stmt1 FROM @s1;
        EXECUTE stmt1;
        DEALLOCATE PREPARE stmt1;
        
        SELECT new_parent_id  FROM _src_media WHERE seq =_seq INTO _pid; 

        SET @s2 = CONCAT("CALL ",_des_db,".mfs_register(",
            "'"  , _origin_id     , "'," ,
            "'"  , _file_name     , "'," ,
            "'"  , _pid           , "'," ,
            "'"  , _category      , "'," ,
            "'"  , _extension     , "'," ,
            "'"  , _mimetype      , "'," ,
            "'"  , _geometry      , "'," ,
                   _file_size     , ", 0 )"          
          );
        PREPARE stmt2 FROM @s2;
        EXECUTE stmt2;
        DEALLOCATE PREPARE stmt2;  

        SET @s3 = CONCAT( "SELECT id ,parent_id FROM ",_des_db,".__register_stack INTO @temp_nid,@pid");
        PREPARE stmt3 FROM @s3;
        EXECUTE stmt3;
        DEALLOCATE PREPARE stmt3;

        UPDATE _src_media SET new_id =@temp_nid , new_parent_id = @pid  WHERE seq =_seq ; 
        UPDATE _src_media SET new_parent_id =  @temp_nid    WHERE parent_id = _id; 
    END LOOP STARTLOOP;
   CLOSE dbcursor; 

 END;   

  

  DROP TABLE IF EXISTS _final_media; 
      CREATE TEMPORARY TABLE `_final_media` (
      nid varchar(16) DEFAULT NULL,  
      new_id varchar(16) DEFAULT NULL,    
      action varchar(16) DEFAULT NULL,
      mfs_root varchar(1024)  DEFAULT NULL
      );   
        
 
  INSERT INTO   _final_media  
  SELECT new_id AS nid ,new_id AS dest_id, 'show'   AS action, null as mfs_root  FROM _src_media WHERE seq = 1 ;

  INSERT INTO   _final_media
  SELECT id   AS nid ,new_id AS dest_id, 'copy'   AS action, null as mfs_root  FROM _src_media WHERE category NOT IN ("folder","hub");

  SELECT * FROM  _final_media;  
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_move` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_move`(
  IN _nid VARCHAR(16),
  IN _pid VARCHAR(16)
)
BEGIN
  DECLARE _src_type VARCHAR(100);
  DECLARE _des_type VARCHAR(100);
  DECLARE _file_name VARCHAR(1024);
  DECLARE _file_path VARCHAR(1024);
  DECLARE _extension VARCHAR(100);
  DECLARE _parent_name VARCHAR(1024);
  DECLARE _parent_path VARCHAR(1024);
  DECLARE _hub_id VARCHAR(16);
  DECLARE _area VARCHAR(50);
  DECLARE _home_dir VARCHAR(512);
  DECLARE _home_id VARCHAR(16);
  DECLARE _src_db_name VARCHAR(50);
  DECLARE _accessibility VARCHAR(16);

  SELECT COUNT(*) FROM media WHERE parent_id = _pid INTO @_count;
  SELECT category, TRIM('/' FROM user_filename) FROM media 
    WHERE id=_pid INTO _des_type, _parent_name;

  SELECT TRIM('/' FROM user_filename), category, extension FROM media WHERE id=_nid 
    INTO _file_name, _src_type, _extension;

  SELECT e.id, e.area, e.home_dir, m.id, e.db_name, e.accessibility from media m 
    INNER JOIN yp.entity e  ON e.db_name=database()
    WHERE parent_id='0' 
    INTO _hub_id, _area, _home_dir, _home_id, _src_db_name, _accessibility;

  
  

  IF _des_type='folder' THEN   
    SELECT clean_path(parent_path(_pid)) INTO _parent_path;
    SELECT unique_filename(_pid, _file_name, _extension) INTO _file_name;
    SELECT clean_path(CONCAT(
      _parent_path, '/', _parent_name, '/', _file_name, '.', _extension
      ))INTO _file_path;

    SELECT REPLACE(file_path, CONCAT('.', extension), "/%")
      FROM media WHERE id=_nid INTO @_src_pattern;
    SELECT REPLACE(file_path, CONCAT('.', extension), "/%")
      FROM media WHERE id=_pid INTO @_des_pattern;

    UPDATE media SET parent_id = _pid , rank=@_count WHERE id = _nid;
    UPDATE media SET parent_path = parent_path(_nid) WHERE id = _nid;
    UPDATE media SET file_path = CONCAT(parent_path, '/', user_filename, '.', extension) 
      WHERE id = _nid;
    IF _src_type='folder' THEN
      UPDATE media m SET parent_path=parent_path(m.id) WHERE file_path LIKE @_src_pattern;
      UPDATE media m set file_path=concat(parent_path, '/', m.user_filename, '.', extension)
        WHERE file_path LIKE @_des_pattern;
    END IF;
    IF _src_type='hub' THEN
      SELECT area FROM yp.entity WHERE id = _nid INTO _area;
    END IF;
  END IF;

  SELECT 
    m.id, 
    m.id as nid, 
    concat(_home_dir, "/__storage__/") AS mfs_root,
    parent_id AS pid,
    parent_id,
    _hub_id AS holder_id,
    _home_id AS home_id,
    _home_dir AS home_dir,
    @perm  AS privilege,
    _hub_id AS owner_id,    
    _hub_id AS hub_id,    
    yp.vhost(_hub_id) AS vhost,    
    _area AS area,
    _accessibility AS accessibility,
    user_filename AS filename,
    filesize,
    caption,
    capability,
    m.extension,
    m.extension AS ext,
    m.category AS ftype,
    m.category AS filetype,
    m.mimetype,
    download_count AS view_count,
    geometry,
    upload_time AS ctime,
    publish_time AS ptime,
    firstname,
    lastname,
    m.category,
    user_filename,
    file_path, 
    parent_path
    FROM media m LEFT JOIN (yp.filecap, yp.drumate) ON 
    m.extension=filecap.extension AND origin_id=yp.drumate.id 
  WHERE m.id = _nid;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_move_all` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_move_all`(
  IN _nodes JSON,
  IN _uid VARCHAR(16),
  IN _dest_id VARCHAR(16),
  IN _recipient_id VARCHAR(16)
)
BEGIN
  DECLARE _idx INT(4) DEFAULT 0; 
  DECLARE _nid VARCHAR(16);
  DECLARE _hub_id VARCHAR(16);
  DECLARE _hub_db VARCHAR(40);
  DECLARE _home_dir VARCHAR(512);
  DECLARE _dest_db VARCHAR(50);
  DECLARE _dest_home_dir VARCHAR(512);
  DECLARE _temp_nid  VARCHAR(16);
  


  DECLARE _is_root tinyint(2) ;
  DECLARE _origin_id      VARCHAR(16);   
  DECLARE _file_name      VARCHAR(512); 
  DECLARE _metadata       JSON; 
  DECLARE _category       VARCHAR(50);   
  DECLARE _extension      VARCHAR(100); 
  DECLARE _mimetype       VARCHAR(100);      
  DECLARE _file_size      INT(20) UNSIGNED;
  DECLARE _geometry       VARCHAR(200);       
  DECLARE _status         VARCHAR(50); 
  DECLARE _finished       INTEGER DEFAULT 0;
  DECLARE _seq            INTEGER;  
  DECLARE _id             VARCHAR(16);   
  DECLARE _new_parent_id  VARCHAR(16);  
  DECLARE _mtime          INT(11) UNSIGNED;
  DECLARE _isalink TINYINT(2) UNSIGNED DEFAULT 0;

  SELECT unix_timestamp() INTO _mtime;

  SELECT db_name, home_dir FROM yp.entity WHERE id=_recipient_id  
    INTO _dest_db, _dest_home_dir;

  DROP TABLE IF EXISTS  `_src_media`;
  CREATE TEMPORARY TABLE `_src_media` (
    `seq`  int NOT NULL AUTO_INCREMENT,
    `is_root` boolean default 0 ,
    `id` varchar(16) DEFAULT NULL,
    `origin_id` varchar(16) DEFAULT NULL,
    `owner_id` varchar(16) DEFAULT NULL,
    `user_filename` varchar(128) DEFAULT NULL,
    `metadata` JSON,
    `status`  varchar(20) ,
    `isalink` tinyint(2) unsigned NOT NULL DEFAULT '0',
    `category` VARCHAR(50) DEFAULT NULL,
    `parent_id` varchar(16) DEFAULT null,
    `extension` varchar(100) NOT NULL DEFAULT '',
    `mimetype` varchar(100) NOT NULL,
    `filesize` int(20) unsigned NOT NULL DEFAULT '0',
    `geometry` varchar(200) NOT NULL DEFAULT '0x0',
    `new_id` varchar(16) DEFAULT NULL,  
    `new_parent_id` varchar(16) DEFAULT '' ,
    `is_checked` boolean default 0 ,
    `home_dir` VARCHAR(512) DEFAULT null,
    `db_name` VARCHAR(512) DEFAULT null,
    `hub_id` VARCHAR(16) DEFAULT null,
    `permission`   tinyint(4) unsigned, 
    PRIMARY KEY `seq`(`seq`)  
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8;


  DROP TABLE IF EXISTS _final_media; 
  CREATE TEMPORARY TABLE `_final_media` (
    nid varchar(16) DEFAULT NULL,  
    category varchar(50) DEFAULT NULL,  
    src_mfs_root varchar(1024) DEFAULT NULL,  
    src_db varchar(160) DEFAULT NULL,  
    des_id varchar(16) DEFAULT NULL,  
    des_mfs_root varchar(1024) DEFAULT NULL,  
    des_db varchar(160) DEFAULT NULL,  
    `type` varchar(10) DEFAULT 'cross' ,
    action varchar(16) DEFAULT NULL
  );

  WHILE _idx < JSON_LENGTH(_nodes) DO 
    DELETE FROM _src_media;
    SELECT get_json_array(_nodes, _idx) INTO @_node;
    SELECT get_json_object(@_node, "nid") INTO _nid;
    SELECT get_json_object(@_node, "hub_id") INTO _hub_id;

    SELECT db_name, home_dir FROM yp.entity WHERE id=_hub_id INTO _hub_db, _home_dir;
    
    IF _hub_id = _recipient_id   THEN

      SET @st = CONCAT("SELECT user_filename,extension FROM  ", _hub_db, ".media WHERE id =? INTO @user_filename,@extension ");
      PREPARE stmt3 FROM @st;
      EXECUTE stmt3 USING   _nid;
      DEALLOCATE PREPARE stmt3;

      SET @st = CONCAT("SELECT ", _hub_db, ".unique_filename ( ?, @user_filename, @extension) INTO @user_filename");
      PREPARE stmt3 FROM @st;
      EXECUTE stmt3 USING   _dest_id;
      DEALLOCATE PREPARE stmt3;

      SET @st = CONCAT("UPDATE ", _hub_db, ".media SET user_filename=@user_filename, upload_time=?, parent_id=? WHERE id =?");
      PREPARE stmt3 FROM @st;
      EXECUTE stmt3 USING _mtime, _dest_id, _nid;
      DEALLOCATE PREPARE stmt3;
	 
      SET @st = CONCAT("SELECT user_filename, ", _hub_db,".parent_path(id)  FROM ", _hub_db, ".media where id = ? INTO @parent_name , @parent_path");
      PREPARE stmt3 FROM @st;
      EXECUTE stmt3 USING  _dest_id;
      DEALLOCATE PREPARE stmt3;

      SET @st = CONCAT("UPDATE ", 
        _hub_db, ".media  m,(
          WITH RECURSIVE mytree AS (	
            SELECT sys_id,  id, parent_id , category ,user_filename,
            CONCAT(IFNULL(@parent_path,''), IFNULL(@parent_name,''),'/') parent_path,

            CASE WHEN  m.category ='folder' or extension = ''
            THEN 
              CONCAT(IFNULL(@parent_path,''), IFNULL(@parent_name,''),'/', IFNULL(m.user_filename,'')) 
            ELSE 
              CONCAT(IFNULL(@parent_path,''), IFNULL(@parent_name,''),'/', IFNULL(m.user_filename,''), '.',IFNULL(m.extension,''))  
            END file_path
            FROM ", _hub_db,".media m WHERE id =", QUOTE(_nid),"
            UNION ALL
            SELECT m.sys_id, m.id, m.parent_id ,m.category, m.user_filename,
            CONCAT(IFNULL(t.parent_path,''), IFNULL(t.user_filename,''),'/') parent_path,
            CASE WHEN  m.category ='folder' or extension = '' 
            THEN 
              CONCAT(IFNULL(t.parent_path,''), IFNULL(t.user_filename,''),'/', IFNULL(m.user_filename,'')) 
            ELSE 
              CONCAT(IFNULL(t.parent_path,''), IFNULL(t.user_filename,''),'/', IFNULL(m.user_filename,''), '.',IFNULL(m.extension,''))  
            END file_path
          FROM ", _hub_db,".media AS m JOIN mytree AS t ON m.parent_id = t.id )
          SELECT sys_id , parent_path,file_path FROM mytree) s 
        SET m.parent_path = s.parent_path,	 
        m.file_path = s.file_path	 
        WHERE m.sys_id= s.sys_id;");
      PREPARE stmt FROM @st;
      EXECUTE stmt ;
      DEALLOCATE PREPARE stmt;

      INSERT INTO _final_media (nid, category, src_db, des_db, `action`, `type`)
      SELECT _nid, NULL, _hub_db, _hub_db, 'show','same' ;


    ELSE 
      
      SET @st = CONCAT( "INSERT INTO _src_media SELECT 
      null, 1, id, origin_id, ?, user_filename, metadata, status, isalink, category, parent_id,  
      extension, mimetype, filesize, geometry, null, null, 0, ?, ?, ? ,0
      FROM ", _hub_db ,".media m  WHERE  m.id =?");  
      PREPARE stmt FROM @st;
      EXECUTE stmt USING _uid, _home_dir, _hub_db, _hub_id, _nid;
      DEALLOCATE PREPARE stmt;

      UPDATE _src_media SET new_parent_id = _dest_id  WHERE  id=_nid; 
      SELECT id FROM _src_media WHERE id = _nid INTO _temp_nid ;
    END IF ;

    WHILE _temp_nid IS NOT NULL DO
       
      SELECT seq, id, origin_id, user_filename, metadata,`status`, category,
        extension, mimetype, `geometry`, filesize, new_parent_id, is_root, 
        isalink
      FROM _src_media WHERE id =_temp_nid 
      INTO _seq,_id, _origin_id, _file_name, _metadata,_status, _category,
        _extension, _mimetype, _geometry, _file_size, _new_parent_id, _is_root,
        _isalink;        
     
      IF _category = 'hub' THEN
        
        IF _hub_id = _recipient_id   THEN
        
          SET @st = CONCAT("UPDATE ", _hub_db, ".media SET parent_id=? WHERE id =?");
          PREPARE stmt3 FROM @st;
          EXECUTE stmt3 USING _new_parent_id, _temp_nid;
          DEALLOCATE PREPARE stmt3;

          SET @st = CONCAT("UPDATE ", _hub_db,
            ".media SET parent_path=", _hub_db,".parent_path(?) WHERE id=?"
          );
          PREPARE stmt3 FROM @st;
          EXECUTE stmt3 USING _temp_nid, _temp_nid;
          DEALLOCATE PREPARE stmt3;

          SET @st = CONCAT("UPDATE ", _hub_db,
            ".media SET file_path=filepath(id) WHERE id =?"
          );
          PREPARE stmt3 FROM @st;
          EXECUTE stmt3 USING _temp_nid;
          DEALLOCATE PREPARE stmt3;

        END IF;
      
        IF _hub_id <> _recipient_id AND _is_root = 0  THEN
          SET @st = CONCAT( "UPDATE ",_hub_db,
            ".media m , (SELECT id FROM ",_hub_db,".media WHERE  parent_id = '0') p SET 
            m.parent_id =p.id,
            m.parent_path = parent_path(?),
            m.file_path =  filepath(?)
            WHERE m.id =?");
          PREPARE stmt3 FROM @st;
          EXECUTE stmt3 USING _temp_nid, _temp_nid, _temp_nid;
          DEALLOCATE PREPARE stmt3;
        END IF;

      ELSE 
        
        IF _category = 'folder' THEN
          SET @st = CONCAT( "INSERT INTO _src_media SELECT 
          null, 0, id, origin_id, ?, user_filename, metadata, status, isalink, category, parent_id, extension, 
          mimetype, filesize, geometry, null, null, 0, ?, ?, ?, 0 
          FROM ", _hub_db ,".media m WHERE m.parent_id =?");  
          PREPARE stmt FROM @st;
          EXECUTE stmt USING _uid, _home_dir, _hub_db, _hub_id, _temp_nid;
          DEALLOCATE PREPARE stmt; 
        END IF ;

        SET @st = CONCAT("UPDATE yp.disk_usage SET size = IFNULL(size,0) - 
            (SELECT IFNULL(filesize,0) FROM " ,_hub_db, ".media  WHERE id =", QUOTE(_nid) ,") WHERE hub_id =",QUOTE( _hub_id),";");
        PREPARE stmt FROM @st;
        EXECUTE stmt ;
        DEALLOCATE PREPARE stmt; 


        SET @st = CONCAT( "DELETE FROM ",_hub_db,".media WHERE category <> 'hub' AND id=?");
        PREPARE stmt3 FROM @st;
        EXECUTE stmt3 USING _temp_nid;
        DEALLOCATE PREPARE stmt3;

        SET @args = JSON_OBJECT(
          "owner_id", _uid,
          "origin_id", _origin_id,
          "filename",_file_name,
          "pid", _new_parent_id,
          "category", _category,
          "ext", _extension,
          "mimetype", _mimetype,
          "filesize", _file_size,
          "geometry", _geometry,
          "isalink", _isalink
        );

        SET @results = JSON_OBJECT();
        SET @st = CONCAT("CALL ", _dest_db, ".mfs_create_node(?, ?, @results)");

        PREPARE stmt2 FROM @st;
        EXECUTE stmt2 USING @args, _metadata;
        DEALLOCATE PREPARE stmt2;

        SELECT JSON_VALUE(@results, "$.id") INTO @temp_nid;
        SELECT JSON_VALUE(@results, "$.pid") INTO @pid;

        UPDATE _src_media SET new_id =@temp_nid  WHERE seq =_seq ; 
        UPDATE _src_media SET new_parent_id =  @temp_nid WHERE parent_id = _temp_nid; 
      END IF;

        
      UPDATE _src_media SET is_checked = 1 WHERE id = _temp_nid ;
      SELECT NULL,NULL,NULL INTO _temp_nid, @temp_nid, @pid;
      SELECT id FROM _src_media WHERE is_checked =0 AND new_parent_id IS NOT NULL LIMIT 1 INTO _temp_nid ;

    END WHILE;
    

    INSERT INTO _final_media (nid, category, src_db, des_db, `action`)
      SELECT IFNULL(new_id,id), category, _hub_db, _dest_db, 'showone' 
      FROM _src_media WHERE seq=1; 

    INSERT INTO _final_media (nid, category, src_db, des_db, `action`)
      SELECT IFNULL(new_id,id), category, _hub_db, _dest_db, 'show' 
      FROM _src_media WHERE is_root=1;

    INSERT INTO _final_media (nid, category, src_mfs_root, des_id, des_mfs_root, `action`)
      SELECT id, category, CONCAT(home_dir, "/__storage__/"), new_id, CONCAT(_dest_home_dir, "/__storage__/"), 'move'  
      FROM _src_media WHERE category NOT IN ("folder","hub") ; 

    
    
    
 

    SELECT _idx + 1 INTO _idx;
  END WHILE;
  SELECT * FROM _final_media;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_move_all_next` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_move_all_next`(
  IN _nodes JSON,
  IN _uid VARCHAR(16),
  IN _dest_id VARCHAR(16),
  IN _recipient_id VARCHAR(16)
)
BEGIN
  DECLARE _idx INT(4) DEFAULT 0; 
  DECLARE _nid VARCHAR(16);
  DECLARE _hub_id VARCHAR(16);
  DECLARE _hub_db VARCHAR(40);
  DECLARE _home_dir VARCHAR(512);
  DECLARE _dest_db VARCHAR(50);
  DECLARE _dest_home_dir VARCHAR(512);
  DECLARE _temp_nid  VARCHAR(16);
  


  DECLARE _is_root tinyint(2) ;
  DECLARE _origin_id      VARCHAR(16);   
  DECLARE _file_name      VARCHAR(512); 
  DECLARE _metadata       JSON; 
  DECLARE _category       VARCHAR(50);   
  DECLARE _extension      VARCHAR(100); 
  DECLARE _mimetype       VARCHAR(100);      
  DECLARE _file_size      INT(20) UNSIGNED;
  DECLARE _geometry       VARCHAR(200);       
  DECLARE _status         VARCHAR(50); 
  DECLARE _finished       INTEGER DEFAULT 0;
  DECLARE _seq            INTEGER;  
  DECLARE _id             VARCHAR(16);   
  DECLARE _new_parent_id  VARCHAR(16);  



  SELECT db_name, home_dir FROM yp.entity WHERE id=_recipient_id  
    INTO _dest_db, _dest_home_dir;

    DROP TABLE IF EXISTS  _src_media;
    CREATE TEMPORARY TABLE `_src_media` (
      `seq`  int NOT NULL AUTO_INCREMENT,
      `is_root` boolean default 0 ,
      `id` varchar(16) DEFAULT NULL,
      `origin_id` varchar(16) DEFAULT NULL,
      `owner_id` varchar(16) DEFAULT NULL,
      `user_filename` varchar(128) DEFAULT NULL,
      `metadata` JSON,
      `status`  varchar(20) ,
      `category` VARCHAR(50) DEFAULT NULL,
      `parent_id` varchar(16) DEFAULT null,
      `extension` varchar(100) NOT NULL DEFAULT '',
      `mimetype` varchar(100) NOT NULL,
      `filesize` int(20) unsigned NOT NULL DEFAULT '0',
      `geometry` varchar(200) NOT NULL DEFAULT '0x0',
      `new_id` varchar(16) DEFAULT NULL,  
      `new_parent_id` varchar(16) DEFAULT '' ,
      `is_checked` boolean default 0 ,
       home_dir VARCHAR(512) DEFAULT null,
       db_name VARCHAR(512) DEFAULT null,
       hub_id VARCHAR(16) DEFAULT null,
    
       permission   tinyint(4) unsigned , 
       PRIMARY KEY `seq`(`seq`)  
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8;


  DROP TABLE IF EXISTS _final_media; 
  CREATE TEMPORARY TABLE `_final_media` (
    nid varchar(16) DEFAULT NULL,  
    category varchar(50) DEFAULT NULL,  
    src_mfs_root varchar(1024) DEFAULT NULL,  
    src_db varchar(160) DEFAULT NULL,  
    des_id varchar(16) DEFAULT NULL,  
    des_mfs_root varchar(1024) DEFAULT NULL,  
    des_db varchar(160) DEFAULT NULL,  
    action varchar(16) DEFAULT NULL
  );


  
  SET @st = CONCAT( "CREATE TEMPORARY TABLE IF NOT EXISTS  ",
    _dest_db,".__register_stack LIKE template.__register_stack"
  ); 
  PREPARE stmt FROM @st;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;

  
  

  WHILE _idx < JSON_LENGTH(_nodes) DO 
    DELETE FROM _src_media;
    
    SELECT get_json_array(_nodes, _idx) INTO @_node;
    SELECT get_json_object(@_node, "nid") INTO _nid;
    SELECT get_json_object(@_node, "hub_id") INTO _hub_id;

    SELECT db_name, home_dir FROM yp.entity WHERE id=_hub_id INTO _hub_db, _home_dir;
    
      
      
    
      
      SET @st = CONCAT( "INSERT INTO _src_media SELECT 
      null, 1, id, origin_id, ?, user_filename, metadata,status, category, parent_id,  
      extension, mimetype, filesize, geometry, null, null, 0, ?, ?, ? ,0
      FROM ", _hub_db ,".media m  WHERE  m.id =?");  
      PREPARE stmt FROM @st;
      EXECUTE stmt USING _uid, _home_dir, _hub_db, _hub_id, _nid;
      DEALLOCATE PREPARE stmt;

      UPDATE _src_media SET new_parent_id = _dest_id  WHERE  id=_nid; 
      SELECT id FROM _src_media WHERE id = _nid INTO _temp_nid ;
    

    WHILE _temp_nid IS NOT NULL DO
       
      SELECT seq, id, origin_id, user_filename, metadata,`status`, category,
        extension, mimetype, `geometry`, filesize, new_parent_id, is_root
      FROM _src_media WHERE id =_temp_nid 
      INTO _seq,_id, _origin_id, _file_name, _metadata,_status, _category,
        _extension, _mimetype, _geometry, _file_size, _new_parent_id, _is_root;        
     

      IF _category = 'hub' THEN
        
        IF _hub_id = _recipient_id   THEN
        
          SET @st = CONCAT("UPDATE ", _hub_db, ".media SET file_path=?, parent_id=? WHERE id =?");
          PREPARE stmt3 FROM @st;
          EXECUTE stmt3 USING _temp_nid, _new_parent_id, _temp_nid;
          DEALLOCATE PREPARE stmt3;

          SET @st = CONCAT("UPDATE ", _hub_db,
            ".media SET parent_path=", _hub_db,".parent_path(?) WHERE id=?"
          );
          PREPARE stmt3 FROM @st;
          EXECUTE stmt3 USING _temp_nid, _temp_nid;
          DEALLOCATE PREPARE stmt3;

          SET @st = CONCAT("UPDATE ", _hub_db,
            ".media SET file_path =clean_path(concat(parent_path, '/', user_filename, '.', id)) WHERE id =?"
          );
          PREPARE stmt3 FROM @st;
          EXECUTE stmt3 USING _temp_nid;
          DEALLOCATE PREPARE stmt3;

        END IF;
      
        IF _hub_id <> _recipient_id AND _is_root = 0  THEN
          SET @st = CONCAT( "UPDATE ",_hub_db,
            ".media m , (SELECT id FROM ",_hub_db,".media WHERE  parent_id = '0') p SET 
            m.parent_id =p.id,
            m.parent_path ='/',
            m.file_path =  clean_path(CONCAT('/', m.user_filename, '.', m.id))
            WHERE m.id =?");
          PREPARE stmt3 FROM @st;
          EXECUTE stmt3 USING _temp_nid;
          DEALLOCATE PREPARE stmt3;
        END IF;

      ELSE 
        
        IF _category = 'folder' THEN
          SET @st = CONCAT( "INSERT INTO _src_media SELECT 
          null, 0, id, origin_id, ?, user_filename, metadata,status, category, parent_id, extension, 
          mimetype, filesize, geometry, null, null, 0, ?, ?, ?, 0 
          FROM ", _hub_db ,".media m WHERE m.parent_id =?");  
          PREPARE stmt FROM @st;
          EXECUTE stmt USING _uid, _home_dir, _hub_db, _hub_id, _temp_nid;
          DEALLOCATE PREPARE stmt; 
        END IF ;

        SET @st = CONCAT( "DELETE FROM ",_hub_db,".media WHERE category <> 'hub' AND id=?");
        PREPARE stmt3 FROM @st;
        EXECUTE stmt3 USING _temp_nid;
        DEALLOCATE PREPARE stmt3;


        SET @st = CONCAT( "DELETE FROM ",_dest_db,".__register_stack"); 
        PREPARE stmt1 FROM @st;
        EXECUTE stmt1;
        DEALLOCATE PREPARE stmt1;

        SET @st = CONCAT("CALL ", _dest_db, ".mfs_new_node(?,?,?,?,?,?,?,?,?,?)");
        PREPARE stmt2 FROM @st;
        EXECUTE stmt2 USING 
          _origin_id     ,
          _uid           ,
          _file_name     ,
          _new_parent_id ,
          _category      ,
          _extension     ,
          _mimetype      ,
          _geometry      ,
          _file_size     , 
          0;           
        DEALLOCATE PREPARE stmt2;

        SET @st = CONCAT( "SELECT id, parent_id FROM ",_dest_db,".__register_stack INTO @temp_nid, @pid");
        PREPARE stmt3 FROM @st;
        EXECUTE stmt3;
        DEALLOCATE PREPARE stmt3;   

        SET @st = CONCAT( "UPDATE ",_dest_db,".media SET metadata=?,status=? WHERE id=?");
        PREPARE stmt3 FROM @st;
        EXECUTE stmt3 USING _metadata, _status, @temp_nid;
        DEALLOCATE PREPARE stmt3;   

        UPDATE _src_media SET new_id =@temp_nid  WHERE seq =_seq ; 
        UPDATE _src_media SET new_parent_id =  @temp_nid WHERE parent_id = _temp_nid; 
      END IF;

        
      UPDATE _src_media SET is_checked = 1 WHERE id = _temp_nid ;
      SELECT NULL,NULL,NULL INTO _temp_nid, @temp_nid, @pid;
      SELECT id FROM _src_media WHERE is_checked =0 AND new_parent_id IS NOT NULL LIMIT 1 INTO _temp_nid ;

    END WHILE;
    

    INSERT INTO _final_media (nid, category, src_db, des_db, `action`)
      SELECT IFNULL(new_id,id), category, _hub_db, _dest_db, 'showone' 
      FROM _src_media WHERE seq=1; 

    INSERT INTO _final_media (nid, category, src_db, des_db, `action`)
      SELECT IFNULL(new_id,id), category, _hub_db, _dest_db, 'show' 
      FROM _src_media WHERE is_root=1;

    INSERT INTO _final_media (nid, category, src_mfs_root, des_id, des_mfs_root, `action`)
      SELECT id, category, CONCAT(home_dir, "/__storage__/"), new_id, CONCAT(_dest_home_dir, "/__storage__/"), 'move'  
      FROM _src_media WHERE category NOT IN ("folder","hub") ; 

    
    
    
 

    SELECT _idx + 1 INTO _idx;
  END WHILE;
  SELECT * FROM _final_media;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_move_merge_tree` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_move_merge_tree`(
  IN _nid VARCHAR(16),
  IN _pid VARCHAR(16),
  IN _recipient_id VARCHAR(16)
)
BEGIN
   
  DECLARE _src_db VARCHAR(255);
  DECLARE _des_db VARCHAR(255); 
  DECLARE _src_root_id  VARCHAR(16);
  DECLARE _cross_hub  INT;

  
  SELECT  database() INTO _src_db;  
  SELECT db_name FROM yp.entity WHERE id=_recipient_id OR ident =_recipient_id INTO _des_db;
  
  SELECT  0 INTO _cross_hub;
  SELECT CASE WHEN _src_db <> _des_db THEN 1 ELSE 0 END INTO _cross_hub;


  SELECT NULL ,NULL ,NULL ,NULL,NULL  INTO  @srcfilename ,@srcpattern,@srcpath ,@descpattern,@despath;


  SET @sql = CONCAT( 
    "SELECT user_filename FROM " ,_src_db ,".media WHERE id =" ,QUOTE( _nid),
    "INTO @srcfilename ");
  PREPARE stmt FROM @sql;
  EXECUTE stmt;

  SET @sql = CONCAT( 
    "SELECT CONCAT(" ,_src_db ,".parent_path(id),user_filename, '/') FROM " ,_src_db ,".media WHERE id =" ,QUOTE( _nid),
    "INTO @srcpattern ");
  PREPARE stmt FROM @sql;
  EXECUTE stmt;

  SET @sql = CONCAT( 
    "SELECT CONCAT(" ,_src_db ,".parent_path(id),'/',user_filename,'/') FROM " ,_src_db ,".media WHERE  id=
    ( SELECT parent_id FROM " ,_src_db ,".media
     WHERE id =" ,QUOTE( _nid),
    ") INTO @srcpath ");
  PREPARE stmt FROM @sql;
  EXECUTE stmt;

  SET @sql = CONCAT( 
    "SELECT CONCAT(" ,_des_db ,".parent_path(id),user_filename, '/') FROM " ,_des_db ,".media WHERE id =" ,QUOTE( _pid),
    "INTO @descpattern ");
  PREPARE stmt FROM @sql;
  EXECUTE stmt;  

  SET @sql = CONCAT( 
    "SELECT CONCAT(" ,_des_db ,".parent_path(id),'/',user_filename,'/') FROM " ,_des_db ,".media WHERE id =" ,QUOTE( _pid),
    "INTO @despath ");
  PREPARE stmt FROM @sql;
  EXECUTE stmt;


  SELECT  clean_path(@srcpattern) INTO @srcpattern;
  SELECT  clean_path(@descpattern) INTO @descpattern; 
  SELECT  clean_path(@srcpath) INTO @srcpath; 
  SELECT  clean_path(@despath) INTO @despath;
  
  


  DROP TABLE IF EXISTS  _src_media;
  CREATE TEMPORARY TABLE `_src_media` (
      `id` varchar(16) DEFAULT NULL,
      `origin_id` varchar(16) DEFAULT NULL,
      `user_filename` varchar(128) DEFAULT NULL,
      `category`      VARCHAR(50) DEFAULT NULL,
      `parent_id` varchar(16) DEFAULT '',
      `extension` varchar(100) NOT NULL DEFAULT '',
      `mimetype` varchar(100) NOT NULL,
      `filesize` int(20) unsigned NOT NULL DEFAULT '0',
      `geometry` varchar(200) NOT NULL DEFAULT '0x0',
      `xpath` varchar(5000) DEFAULT '' ,
      `new_id` varchar(16) DEFAULT NULL,  
      `new_parent_id` varchar(16) DEFAULT '' 
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

    DROP TABLE IF EXISTS _des_media;
    CREATE TEMPORARY TABLE `_des_media` (
      `id` varchar(16) DEFAULT NULL,
      `origin_id` varchar(16) DEFAULT NULL,
      `user_filename` varchar(128) DEFAULT NULL,
      `category`      VARCHAR(50) DEFAULT NULL,
      `parent_id` varchar(16) DEFAULT '',
      `extension` varchar(100) NOT NULL DEFAULT '',
      `mimetype` varchar(100) NOT NULL,
      `filesize` int(20) unsigned NOT NULL DEFAULT '0',
      `geometry` varchar(200) NOT NULL DEFAULT '0x0',
      `xpath` varchar(5000) DEFAULT '' 
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8;



  SET @sql = CONCAT(" 
    INSERT INTO _src_media 
    SELECT id,origin_id,user_filename,category,parent_id, extension,mimetype,filesize,geometry,
    TRIM(LEADING @srcpath  FROM clean_path(CONCAT(" ,_src_db ,".parent_path(id),'/',user_filename,'.',extension ))) xpath,NULL,NULL
    FROM  " ,_src_db ,".media m 
    WHERE  CONCAT(" ,_src_db ,".parent_path(id),user_filename,'/' ) 
    LIKE CONCAT(@srcpattern,'%') ");
  PREPARE stmt FROM @sql;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;
  
  SET @sql = CONCAT(" 
    INSERT INTO _des_media
    SELECT  id,origin_id,user_filename,category,parent_id, extension,mimetype,filesize,geometry,
    TRIM(LEADING @despath  FROM clean_path(CONCAT(" ,_des_db ,".parent_path(id),'/',user_filename,'.',extension ))) xpath
    FROM  " ,_des_db ,".media m      	
    WHERE id <> ", QUOTE( _pid) ,"
    AND CONCAT(" ,_des_db ,".parent_path(id),user_filename,'/' ) 
    LIKE CONCAT(@descpattern,@srcfilename,'/','%')");
  PREPARE stmt FROM @sql;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;

  UPDATE _src_media SET new_parent_id = _pid  WHERE id=_nid;
  UPDATE _src_media s,_des_media d SET s.new_parent_id = d.parent_id , s.new_id=d.id WHERE  s.xpath = d.xpath;
  DROP TABLE IF EXISTS _src_temp_media;
  CREATE TABLE _src_temp_media as SELECT * FROM _src_media;
  UPDATE _src_media s , _src_temp_media d SET s.new_parent_id = d.new_id  WHERE  s.parent_id = d.id;

  
  

  SELECT id FROM media WHERE parent_id = '0' INTO _src_root_id;
  UPDATE media SET parent_id = _src_root_id WHERE id IN (SELECT id FROM _src_media WHERE category ='hub');
  UPDATE media SET parent_path = parent_path(id) WHERE id IN (SELECT id FROM _src_media WHERE category ='hub');
  UPDATE media SET file_path = CONCAT(parent_path, '/', user_filename, '.', extension) WHERE id IN (SELECT id FROM _src_media WHERE category ='hub');
  

  SET @sql = CONCAT( "DELETE FROM _src_media WHERE id in (SELECT id from _des_media) ");
  PREPARE stmt FROM @sql;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;  

  SET @sql = CONCAT( "DELETE FROM ",_src_db,".media WHERE id in (SELECT id from _src_media where  category <> 'hub' ) ");
  PREPARE stmt FROM @sql;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;

  SET @sql = CONCAT( 
    'INSERT INTO ',_des_db,'.media (
    id,origin_id,user_filename,category,parent_id,parent_path, file_path,extension,mimetype,filesize,geometry,publish_time,upload_time,status,rank)
    SELECT IFNULL(new_id,id),origin_id,user_filename,category,IFNULL(new_parent_id,parent_id), IFNULL(new_id,id), IFNULL(new_id,id),extension,mimetype,filesize,geometry,UNIX_TIMESTAMP(),UNIX_TIMESTAMP(),"active",0
    FROM _src_media WHERE  category <> "hub"  AND xpath NOT IN (SELECT xpath FROM _des_media) ') ;
  PREPARE stmt FROM @sql ;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;

  SET @sql = CONCAT( 
     "UPDATE ",_des_db,".media SET parent_path = clean_path(  ",_des_db,".parent_path(id)) WHERE id IN (SELECT id FROM _src_media WHERE category <> 'hub')" );
  PREPARE stmt FROM @sql ;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt; 
  
  SET @sql = CONCAT( 
     "UPDATE ",_des_db,".media SET file_path = clean_path(concat(parent_path, '/', user_filename, '.', extension)) WHERE id IN (SELECT id FROM _src_media WHERE category <> 'hub')" );
  PREPARE stmt FROM @sql ;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt; 


  SET @s2 = CONCAT( "CALL ",_src_db,".mediaEnv(@_tmp, @_tmp, @_tmp, @src_home_dir, @_tmp, @_tmp, @_tmp)") ;
  PREPARE stmt2 FROM @s2;
  EXECUTE stmt2;
  DEALLOCATE PREPARE stmt2;

  SET @s2 = CONCAT( "CALL ",_des_db,".mediaEnv(@_tmp, @_tmp, @_tmp, @des_home_dir, @_tmp, @_tmp, @_tmp)") ;
  PREPARE stmt2 FROM @s2;
  EXECUTE stmt2;
  DEALLOCATE PREPARE stmt2;

  DROP TABLE IF EXISTS _final_media; 
      CREATE TEMPORARY TABLE `_final_media` (
      nid varchar(16) DEFAULT NULL,  
      src_mfs_root varchar(1024) DEFAULT NULL,  
      des_id varchar(16) DEFAULT NULL,  
      des_mfs_root varchar(1024) DEFAULT NULL,  
      action varchar(16) DEFAULT NULL
  );
  


  SELECT NULL ,NULL ,NULL ,NULL,NULL  INTO  @srcfilename ,@srcpattern,@srcpath ,@descpattern,@despath;

  INSERT INTO _final_media  
  SELECT IFNULL( new_id, id) ,NULL, NULL, NULL,'show'  FROM _src_media WHERE id=_nid ;

  IF _cross_hub = 1 THEN
  
    INSERT INTO _final_media
    SELECT id , CONCAT(@src_home_dir, "/__storage__/") ,new_id, CONCAT(@des_home_dir, "/__storage__/") ,'move'  
    FROM _src_media WHERE category NOT IN ("folder","hub")  AND new_id IS NOT NULL;

    INSERT INTO _final_media
    SELECT id , CONCAT(@src_home_dir, "/__storage__/") ,id, CONCAT(@des_home_dir, "/__storage__/") ,'move'  
    FROM _src_media WHERE category NOT IN ("folder","hub")  AND new_id IS NULL;
  
    INSERT INTO _final_media
    SELECT id , CONCAT(@src_home_dir, "/__storage__/") , NULL ,null,'delete'  FROM _src_media WHERE category NOT IN ("folder","hub") ;

  ELSE 
    
    INSERT INTO _final_media
    SELECT id , CONCAT(@src_home_dir, "/__storage__/") ,new_id, CONCAT(@des_home_dir, "/__storage__/") ,'move'  
    FROM _src_media WHERE category NOT IN ("folder","hub")  AND new_id IS NOT NULL;

    INSERT INTO _final_media
    SELECT id , CONCAT(@src_home_dir, "/__storage__/") , NULL ,null,'delete'  
    FROM _src_media WHERE category NOT IN ("folder","hub")  AND new_id IS NOT NULL;

  END IF; 
  SELECT * FROM _final_media;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_move_node` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_move_node`(
  IN _nid VARCHAR(16),
  IN _pid VARCHAR(16),
  IN _recipient_id VARCHAR(16)
)
BEGIN

DECLARE _dest_db        VARCHAR(50);
DECLARE _origin_id      VARCHAR(16);   
DECLARE _file_name      VARCHAR(512); 
DECLARE _category       VARCHAR(50);   
DECLARE _extension      VARCHAR(100); 
DECLARE _mimetype       VARCHAR(100);      
DECLARE _file_size      INT(20) UNSIGNED;
DECLARE _geometry       VARCHAR(200);       



SELECT db_name FROM yp.entity WHERE id=_recipient_id OR ident =_recipient_id INTO _dest_db;

SELECT origin_id,user_filename,category,extension,mimetype,geometry,filesize 
FROM media  WHERE id =_nid
INTO _origin_id,_file_name,_category,_extension,_mimetype,_geometry,_file_size;

DELETE FROM media WHERE id = _nid ; 

        SET @s1 = CONCAT( "CREATE TEMPORARY TABLE IF NOT EXISTS  ",_dest_db,".__register_stack LIKE template.tmp_media"); 
        PREPARE stmt FROM @s1;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;


        SET @s1 = CONCAT( "DELETE FROM ",_dest_db,".__register_stack"); 
        PREPARE stmt1 FROM @s1;
        EXECUTE stmt1;
        DEALLOCATE PREPARE stmt1;

        SET @s2 = CONCAT("CALL ",_dest_db,".mfs_register(",
            ""  ,   QUOTE(_origin_id )    , "," ,
            ""  ,   QUOTE( _file_name )    , "," ,
            ""  ,   QUOTE( _pid  )         , "," ,
            ""  ,   QUOTE( _category)      , "," ,
            ""  ,   QUOTE( _extension)     , "," ,
            ""  ,   QUOTE( _mimetype)      , "," ,
            ""  ,   QUOTE(_geometry)      , "," ,
                   _file_size     , ", 0 )"          
          );
        PREPARE stmt2 FROM @s2;
        EXECUTE stmt2;
        DEALLOCATE PREPARE stmt2;   
 

        SET @s3 = CONCAT( "SELECT id ,parent_id FROM ",_dest_db,".__register_stack INTO @temp_nid,@pid");
        PREPARE stmt3 FROM @s3;
        EXECUTE stmt3;
        DEALLOCATE PREPARE stmt3;


        CALL mediaEnv(@_tmp, @_tmp, @_tmp, @src_home_dir, @_tmp, @_tmp, @_tmp);
  
        SET @s2 = CONCAT( "CALL ",_dest_db,".mediaEnv(@_tmp, @_tmp, @_tmp, @des_home_dir, @_tmp, @_tmp, @_tmp)") ;
        PREPARE stmt2 FROM @s2;
        EXECUTE stmt2;
        DEALLOCATE PREPARE stmt2;


        DROP TABLE IF EXISTS _final_media; 
              CREATE TEMPORARY TABLE `_final_media` (
              nid varchar(16) DEFAULT NULL,  
              src_mfs_root varchar(1024) DEFAULT NULL,  
              des_id varchar(16) DEFAULT NULL,  
              des_mfs_root varchar(1024) DEFAULT NULL,  
              action varchar(16) DEFAULT NULL
          );   

        INSERT INTO _final_media  
        SELECT @temp_nid,NULL ,@temp_nid, NULL ,'show' ;
        INSERT INTO _final_media  
        SELECT _nid ,  CONCAT(@src_home_dir, "/__storage__/") ,  @temp_nid , CONCAT(@des_home_dir, "/__storage__/")  , 'move'  ;
        INSERT INTO _final_media
        SELECT _nid , CONCAT(@src_home_dir, "/__storage__/") , NULL ,NULL,'delete'  ;

        SELECT * FROM _final_media;


END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_move_replace_node` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_move_replace_node`(
  IN _nid VARCHAR(16),
  IN _pid VARCHAR(16),
  IN _recipient_id VARCHAR(16)
)
BEGIN
   
  DECLARE _src_db VARCHAR(255);
  DECLARE _des_db VARCHAR(255); 
  DECLARE _src_root_id  VARCHAR(16);
  DECLARE _cross_hub  INT;


  SELECT NULL,NULL,NULL INTO  @srcfilename, @descpattern, @destnid;

  SELECT  database() INTO _src_db;  
  SELECT db_name FROM yp.entity WHERE id=_recipient_id OR ident =_recipient_id INTO _des_db;
  
  SELECT  0 INTO _cross_hub;
  SELECT CASE WHEN _src_db <> _des_db THEN 1 ELSE 0 END INTO _cross_hub;
 
  SELECT concat(user_filename, '.', extension) FROM media WHERE id = _nid INTO @srcfilename ;
  

  SET @sql = CONCAT( 
    "SELECT CONCAT(" ,_des_db ,".parent_path(id),user_filename, '/') FROM " ,_des_db ,".media WHERE id =" ,QUOTE( _pid),
    "INTO @descpattern" );
  PREPARE stmt FROM @sql;
  EXECUTE stmt;

  SET @sql = CONCAT(" 
    SELECT id 
    FROM  ",_des_db ,".media m      	
    WHERE id <> ", QUOTE( _pid) ,"
    AND CONCAT(" ,_des_db ,".parent_path(id),user_filename,'.',extension ) 
    = CONCAT(@descpattern,@srcfilename) INTO @destnid");
   PREPARE stmt FROM @sql;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;

 
  DELETE FROM media WHERE id = _nid AND _nid <> @destnid;
 
  CALL mediaEnv(@_tmp, @_tmp, @_tmp, @src_home_dir, @_tmp, @_tmp, @_tmp);

  SET @s2 = CONCAT( "CALL ",_des_db,".mediaEnv(@_tmp, @_tmp, @_tmp, @des_home_dir, @_tmp, @_tmp, @_tmp)") ;
  PREPARE stmt2 FROM @s2;
  EXECUTE stmt2;
  DEALLOCATE PREPARE stmt2;


  DROP TABLE IF EXISTS _final_media; 
      CREATE TEMPORARY TABLE `_final_media` (
      nid varchar(16) DEFAULT NULL,  
      src_mfs_root varchar(1024) DEFAULT NULL,  
      des_id varchar(16) DEFAULT NULL,  
      des_mfs_root varchar(1024) DEFAULT NULL,  
      action varchar(16) DEFAULT NULL
  );
  
  INSERT INTO _final_media  SELECT IFNULL(@destnid,_nid) ,NULL, NULL, NULL,'show' ;
 
  INSERT INTO _final_media
    SELECT _nid , CONCAT(@src_home_dir, "/__storage__/") ,IFNULL(@destnid,_nid), CONCAT(@des_home_dir, "/__storage__/") ,'move' 
    WHERE _nid <> @destnid ; 
  
  INSERT INTO _final_media
    SELECT _nid , CONCAT(@src_home_dir, "/__storage__/") , NULL ,null,'delete' WHERE _nid <> @destnid ; 
  
  
  
  SELECT * FROM _final_media;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_move_replace_tree` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_move_replace_tree`(
  IN _nid VARCHAR(16),
  IN _pid VARCHAR(16),
  IN _recipient_id VARCHAR(16)
)
BEGIN
   
  DECLARE _src_db VARCHAR(255);
  DECLARE _des_db VARCHAR(255); 
  DECLARE _src_root_id  VARCHAR(16);
  DECLARE _cross_hub  INT;

  
  SELECT  database() INTO _src_db;  
  SELECT db_name FROM yp.entity WHERE id=_recipient_id OR ident =_recipient_id INTO _des_db;
  
  SELECT  0 INTO _cross_hub;
  SELECT CASE WHEN _src_db <> _des_db THEN 1 ELSE 0 END INTO _cross_hub;


  SELECT NULL ,NULL ,NULL ,NULL  INTO  @srcfilename ,@srcpattern ,@descpattern,@despath;


  SET @sql = CONCAT( 
    "SELECT user_filename FROM " ,_src_db ,".media WHERE id =" ,QUOTE( _nid),
    "INTO @srcfilename ");
  PREPARE stmt FROM @sql;
  EXECUTE stmt;

  SET @sql = CONCAT( 
    "SELECT CONCAT(" ,_src_db ,".parent_path(id),user_filename, '/') FROM " ,_src_db ,".media WHERE id =" ,QUOTE( _nid),
    "INTO @srcpattern ");
  PREPARE stmt FROM @sql;
  EXECUTE stmt;

  SET @sql = CONCAT( 
    "SELECT CONCAT(" ,_des_db ,".parent_path(id),user_filename, '/') FROM " ,_des_db ,".media WHERE id =" ,QUOTE( _pid),
    "INTO @descpattern ");
  PREPARE stmt FROM @sql;
  EXECUTE stmt;  

  SET @sql = CONCAT( 
    "SELECT CONCAT(" ,_des_db ,".parent_path(id),'/',user_filename,'/') FROM " ,_des_db ,".media WHERE id =" ,QUOTE( _pid),
    "INTO @despath ");
  PREPARE stmt FROM @sql;
  EXECUTE stmt;


  SELECT  clean_path(@srcpattern) INTO @srcpattern;
  SELECT  clean_path(@descpattern) INTO @descpattern; 
  SELECT  clean_path(@despath) INTO @despath;
  
  


  DROP TABLE IF EXISTS  _src_media;
  CREATE TEMPORARY TABLE `_src_media` (
      `id` varchar(16) DEFAULT NULL,
      `origin_id` varchar(16) DEFAULT NULL,
      `user_filename` varchar(128) DEFAULT NULL,
      `category`      VARCHAR(50) DEFAULT NULL,
      `parent_id` varchar(16) DEFAULT '',
      `extension` varchar(100) NOT NULL DEFAULT '',
      `mimetype` varchar(100) NOT NULL,
      `filesize` int(20) unsigned NOT NULL DEFAULT '0',
      `geometry` varchar(200) NOT NULL DEFAULT '0x0'
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

    DROP TABLE IF EXISTS _des_media;
    CREATE TEMPORARY TABLE `_des_media` (
      `id` varchar(16) DEFAULT NULL,
      `origin_id` varchar(16) DEFAULT NULL,
      `user_filename` varchar(128) DEFAULT NULL,
      `category`      VARCHAR(50) DEFAULT NULL,
      `parent_id` varchar(16) DEFAULT '',
      `extension` varchar(100) NOT NULL DEFAULT '',
      `mimetype` varchar(100) NOT NULL,
      `filesize` int(20) unsigned NOT NULL DEFAULT '0',
      `geometry` varchar(200) NOT NULL DEFAULT '0x0'

    ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

  SET @sql = CONCAT(" 
    INSERT INTO _src_media 
    SELECT id,origin_id,user_filename,category,parent_id, extension,mimetype,filesize,geometry
    FROM  " ,_src_db ,".media m 
    WHERE  CONCAT(" ,_src_db ,".parent_path(id),user_filename,'/' ) 
    LIKE CONCAT(@srcpattern,'%') ");
  PREPARE stmt FROM @sql;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;
  
  SET @sql = CONCAT(" 
    INSERT INTO _des_media
    SELECT  id,origin_id,user_filename,category,parent_id, extension,mimetype,filesize,geometry 
    FROM  " ,_des_db ,".media m      	
    WHERE id <> ", QUOTE( _pid) ,"
    AND CONCAT(" ,_des_db ,".parent_path(id),user_filename,'/' ) 
    LIKE CONCAT(@descpattern,@srcfilename,'/','%')");
  PREPARE stmt FROM @sql;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;

  UPDATE _src_media SET parent_id = _pid  WHERE id=_nid;
  
  SELECT id FROM media WHERE parent_id = '0' INTO _src_root_id;
  UPDATE media SET parent_id = _src_root_id WHERE id IN (SELECT id FROM _src_media WHERE category ='hub');
  UPDATE media SET parent_path = parent_path(id) WHERE id IN (SELECT id FROM _src_media WHERE category ='hub');
  UPDATE media SET file_path = clean_path(CONCAT(parent_path, '/', user_filename, '.', extension)) WHERE id IN (SELECT id FROM _src_media WHERE category ='hub');
  

  

  SET @sql = CONCAT( "DELETE FROM ",_des_db,".media WHERE id in (SELECT id from _des_media ) ");
  PREPARE stmt FROM @sql;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;

   

  SET @sql = CONCAT( "DELETE FROM ",_src_db,".media WHERE id in (SELECT id from _src_media where  category <> 'hub' ) ");
  PREPARE stmt FROM @sql;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;

  

  SET @sql = CONCAT( 
    'INSERT INTO ',_des_db,'.media (
    id,origin_id,user_filename,category,parent_id,parent_path, file_path,extension,mimetype,filesize,geometry,publish_time,upload_time,status,rank)
    SELECT id,origin_id,user_filename,category,parent_id, id, id,extension,mimetype,filesize,geometry,UNIX_TIMESTAMP(),UNIX_TIMESTAMP(),"active",0
    FROM _src_media WHERE  category <> "hub"') ;
  PREPARE stmt FROM @sql ;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;

  SET @sql = CONCAT( 
      "UPDATE ",_des_db,".media SET parent_path = clean_path(  ",_des_db,".parent_path(id)) WHERE id IN (SELECT id FROM _src_media WHERE category <> 'hub')" );
  PREPARE stmt FROM @sql ;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt; 
  
  SET @sql = CONCAT( 
     "UPDATE ",_des_db,".media SET file_path =clean_path(concat(parent_path, '/', user_filename, '.', extension)) WHERE id IN (SELECT id FROM _src_media WHERE category <> 'hub')" );
  PREPARE stmt FROM @sql ;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt; 


  SET @s2 = CONCAT( "CALL ",_src_db,".mediaEnv(@_tmp, @_tmp, @_tmp, @src_home_dir, @_tmp, @_tmp, @_tmp)") ;
  PREPARE stmt2 FROM @s2;
  EXECUTE stmt2;
  DEALLOCATE PREPARE stmt2;

  SET @s2 = CONCAT( "CALL ",_des_db,".mediaEnv(@_tmp, @_tmp, @_tmp, @des_home_dir, @_tmp, @_tmp, @_tmp)") ;
  PREPARE stmt2 FROM @s2;
  EXECUTE stmt2;
  DEALLOCATE PREPARE stmt2;

  DROP TABLE IF EXISTS _final_media; 
      CREATE TEMPORARY TABLE `_final_media` (
      nid varchar(16) DEFAULT NULL,  
      src_mfs_root varchar(1024) DEFAULT NULL,  
      des_id varchar(16) DEFAULT NULL,  
      des_mfs_root varchar(1024) DEFAULT NULL,  
      action varchar(16) DEFAULT NULL
  );
  


  SELECT NULL ,NULL ,NULL  INTO  @srcfilename ,@srcpattern,@descpattern;

  INSERT INTO _final_media  
  SELECT id ,NULL, NULL, NULL,'show'  FROM _src_media WHERE id=_nid ;

  IF _cross_hub = 1 THEN
    INSERT INTO _final_media
    SELECT id , CONCAT(@src_home_dir, "/__storage__/") ,id, CONCAT(@des_home_dir, "/__storage__/") ,'move'  
    FROM _src_media WHERE category NOT IN ("folder","hub");

    INSERT INTO _final_media
    SELECT id , CONCAT(@src_home_dir, "/__storage__/") , NULL ,null,'delete'  FROM _src_media WHERE category NOT IN ("folder","hub") ;
  END IF; 

  INSERT INTO _final_media 
  SELECT  id, CONCAT(@des_home_dir, "/__storage__/") ,null,null,'delete'  
  FROM _des_media WHERE category NOT IN ("folder","hub");
  
  SELECT * FROM _final_media;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_move_tree` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_move_tree`(
  IN _nid VARCHAR(16),
  IN _pid VARCHAR(16),
  IN _recipient_id VARCHAR(16)
)
BEGIN
   
    DECLARE  _temp_nid      VARCHAR(16);
    DECLARE  _lvl           INTEGER;
    DECLARE _dest_db        VARCHAR(50);


    DECLARE _origin_id      VARCHAR(16);   
    DECLARE _src_path       VARCHAR(1024); 
    DECLARE _des_path       VARCHAR(1024); 
    DECLARE _file_name      VARCHAR(512); 
    DECLARE _category       VARCHAR(50);   
    DECLARE _extension      VARCHAR(100); 
    DECLARE _mimetype       VARCHAR(100);      
    DECLARE _file_size      INT(20) UNSIGNED;
    DECLARE _geometry       VARCHAR(200);       
    DECLARE _status         VARCHAR(50); 
    DECLARE _finished       INTEGER DEFAULT 0;
    DECLARE _seq            INTEGER;  
    DECLARE _id             VARCHAR(16);   
    DECLARE _src_root_id    VARCHAR(16);  

    SELECT db_name FROM yp.entity WHERE id=_recipient_id OR ident =_recipient_id INTO _dest_db;
    SELECT id FROM media WHERE parent_id = '0' INTO _src_root_id;
    

    DROP TABLE IF EXISTS  _src_media;
    CREATE TEMPORARY TABLE `_src_media` (
      `seq`  int NOT NULL AUTO_INCREMENT,
      `id` varchar(16) DEFAULT NULL,
      `origin_id` varchar(16) DEFAULT NULL,
      `user_filename` varchar(128) DEFAULT NULL,
      `category`      VARCHAR(50) DEFAULT NULL,
      `parent_id` varchar(16) DEFAULT '',
      `extension` varchar(100) NOT NULL DEFAULT '',
      `mimetype` varchar(100) NOT NULL,
      `filesize` int(20) unsigned NOT NULL DEFAULT '0',
      `geometry` varchar(200) NOT NULL DEFAULT '0x0',
      `new_id` varchar(16) DEFAULT NULL,  
      `new_parent_id` varchar(16) DEFAULT '' ,
      `lvl` int default 0, 
      `is_checked` boolean default 0 ,
       PRIMARY KEY `seq`(`seq`)  
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

    SELECT _nid,0  INTO _temp_nid , _lvl;
   
    WHILE _temp_nid IS NOT NULL DO
      
      INSERT INTO _src_media
      SELECT 
      null, id,origin_id,user_filename,category,parent_id,extension,mimetype,filesize,geometry,null,null,_lvl ,0
      FROM media m1 WHERE  category <> "hub" AND CASE WHEN _lvl <> 0 THEN m1.parent_id ELSE m1.id END  =_temp_nid;
      
      UPDATE media m1 
      SET 
        parent_id = _src_root_id ,
        parent_path ='/',
        file_path =  clean_path(CONCAT('/', user_filename, '.', extension))

      WHERE  category = "hub" AND CASE WHEN _lvl <> 0 THEN m1.parent_id ELSE m1.id END  =_temp_nid;
      
      
      UPDATE _src_media SET is_checked = 1 WHERE id = _temp_nid and _lvl <> 0;
      SELECT NULL,_lvl+1 INTO _temp_nid,_lvl;
      SELECT id FROM _src_media WHERE is_checked = 0 LIMIT 1 INTO _temp_nid ;
  
    END WHILE;
 
  DELETE FROM media WHERE id in (SELECT id from _src_media ) ;  


  UPDATE _src_media SET new_parent_id = _pid  WHERE  seq=1;  
  
  BEGIN
    DECLARE dbcursor CURSOR FOR SELECT seq,id,origin_id,user_filename,category,extension,mimetype,`geometry`,filesize FROM _src_media order by seq;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET _finished = 1;
    OPEN dbcursor;
     
      STARTLOOP: LOOP
        FETCH dbcursor INTO _seq,_id,_origin_id,_file_name,_category,_extension,_mimetype,_geometry,_file_size;
         IF _finished = 1 THEN 
            LEAVE STARTLOOP;
         END IF;    

       

        SET @s1 = CONCAT( "CREATE TEMPORARY TABLE IF NOT EXISTS  ",_dest_db,".__register_stack LIKE template.tmp_media"); 
        PREPARE stmt FROM @s1;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;


        SET @s1 = CONCAT( "DELETE FROM ",_dest_db,".__register_stack"); 
        PREPARE stmt1 FROM @s1;
        EXECUTE stmt1;
        DEALLOCATE PREPARE stmt1;
        
        SELECT new_parent_id  FROM _src_media WHERE seq =_seq INTO _pid; 
       

        SET @s2 = CONCAT("CALL ",_dest_db,".mfs_register(",
            "'"  , _origin_id     , "'," ,
            "'"  , _file_name     , "'," ,
            "'"  , _pid           , "'," ,
            "'"  , _category      , "'," ,
            "'"  , _extension     , "'," ,
            "'"  , _mimetype      , "'," ,
            "'"  , _geometry      , "'," ,
                   _file_size     , ", 0 )"          
          );
        PREPARE stmt2 FROM @s2;
        EXECUTE stmt2;
        DEALLOCATE PREPARE stmt2;   
 

      
        SET @s3 = CONCAT( "SELECT id ,parent_id FROM ",_dest_db,".__register_stack INTO @temp_nid,@pid");
        PREPARE stmt3 FROM @s3;
        EXECUTE stmt3;
        DEALLOCATE PREPARE stmt3;   
        

        UPDATE _src_media SET new_id =@temp_nid , new_parent_id = @pid  WHERE seq =_seq ; 
        UPDATE _src_media SET new_parent_id =  @temp_nid    WHERE parent_id = _id; 

      END LOOP STARTLOOP;   

    CLOSE dbcursor;
  END;  
   

    CALL mediaEnv(@_tmp, @_tmp, @_tmp, @src_home_dir, @_tmp, @_tmp, @_tmp);
  
    SET @s2 = CONCAT( "CALL ",_dest_db,".mediaEnv(@_tmp, @_tmp, @_tmp, @des_home_dir, @_tmp, @_tmp, @_tmp)") ;
    PREPARE stmt2 FROM @s2;
    EXECUTE stmt2;
    DEALLOCATE PREPARE stmt2;


  


  DROP TABLE IF EXISTS _final_media; 
      CREATE TEMPORARY TABLE `_final_media` (
      nid varchar(16) DEFAULT NULL,  
      src_mfs_root varchar(1024) DEFAULT NULL,  
      des_id varchar(16) DEFAULT NULL,  
      des_mfs_root varchar(1024) DEFAULT NULL,  
      action varchar(16) DEFAULT NULL
  );   

  INSERT INTO _final_media  
  SELECT new_id,NULL ,new_id, NULL ,'show' FROM _src_media WHERE seq = 1 ;
  INSERT INTO _final_media  
  SELECT id ,  CONCAT(@src_home_dir, "/__storage__/") ,  new_id , CONCAT(@des_home_dir, "/__storage__/")  , 'move'  FROM _src_media WHERE category NOT IN ("folder","hub");
  INSERT INTO _final_media
  SELECT id , CONCAT(@src_home_dir, "/__storage__/") , NULL ,NULL,'delete'  FROM _src_media WHERE category NOT IN ("folder","hub") ;

  SELECT * FROM _final_media;
    

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_node_attr` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_node_attr`(
  IN _key VARCHAR(1024) 
)
BEGIN

  DECLARE _area VARCHAR(25);
  DECLARE _vhost VARCHAR(255);
  DECLARE _home_dir VARCHAR(500);
  DECLARE _hub_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _dom_id VARCHAR(16) ;
  DECLARE _home_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _parent_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _db_name VARCHAR(50);
  DECLARE _hub_name VARCHAR(150);
  DECLARE _hub_db VARCHAR(150);
  DECLARE _actual_home_id VARCHAR(150) CHARACTER SET ascii;
  DECLARE _actual_hub_id VARCHAR(150) CHARACTER SET ascii;
  DECLARE _actual_db VARCHAR(150);
  DECLARE _node_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _remit TINYINT(4) DEFAULT 0;

  IF _key regexp  '^\/.+' THEN 
    SELECT id FROM media 
      WHERE REPLACE(file_path, '/', '') = 
      REPLACE(IF(category='folder' OR category ='hub', CONCAT(_key, '.', extension), _key), '/','')
      INTO _node_id;
  ELSE 
    SELECT _key INTO _node_id;
  END IF;


  SELECT 
    COALESCE(h.name, dr.fullname) AS `name`,
    e.id,
    e.home_id,
    e.home_dir,
    d.id,
    e.area,
    v.fqdn,
    e.db_name
  FROM yp.entity e
    INNER JOIN yp.vhost v ON e.id = v.id 
    INNER JOIN yp.domain d ON d.id = e.dom_id
    LEFT JOIN yp.drumate dr ON e.id = dr.id 
    LEFT JOIN yp.hub h ON e.id = h.id 
  WHERE e.db_name = database() 
  INTO 
    _hub_name,
    _hub_id, 
    _home_id, 
    _home_dir,
    _dom_id, 
    _area,
    _vhost,
    _db_name;

  SELECT _home_id , _hub_id, _db_name
    INTO _actual_home_id, _actual_hub_id, _actual_db;



  SELECT
    m.id,
    m.id  AS nid,
    _actual_home_id AS actual_home_id, 
    _actual_hub_id AS actual_hub_id,
    _actual_db AS actual_db,
    _db_name AS db_name,
    concat(_home_dir, "/__storage__/") AS mfs_root,
    concat(_home_dir, "/__storage__/") AS home_dir,
    parent_id AS pid,
    parent_id AS parent_id,
    _hub_id AS hub_id,
    _vhost AS vhost,
    caption,
    _area AS accessibility,
    _area AS area,
    _home_id AS home_id,
    capability,
    m.status AS status,
    m.extension,
    m.extension AS ext,
    COALESCE(fc.category, m.category) ftype,
    COALESCE(fc.category, m.category) filetype,
    COALESCE(fc.mimetype, m.mimetype) mimetype,
    download_count AS view_count,
    isalink,
    IF(m.isalink =1 AND m.category NOT IN ('hub')  ,JSON_UNQUOTE(JSON_EXTRACT(m.metadata, "$.target.nid")), NULL) target_nid , 
    IF(m.isalink =1 AND m.category NOT IN ('hub')  ,JSON_UNQUOTE(JSON_EXTRACT(m.metadata, "$.target.hub_id")), NULL)  target_hub_id, 
    IF(m.isalink =1 AND m.category NOT IN ('hub')  ,JSON_UNQUOTE(JSON_EXTRACT(m.metadata, "$.target.mfs_root")), NULL)  target_mfs_root, 
    m.metadata metadata,
    geometry,
    upload_time AS ctime,
    publish_time AS ptime,
    publish_time AS mtime,
    CASE 
      WHEN m.category='hub' THEN _hub_name
      WHEN m.parent_id='0' THEN _hub_name
      ELSE user_filename
    END AS filename,
    parent_path,
    file_path,
    filesize,
    _remit AS remit
  FROM  media m LEFT JOIN (yp.filecap fc, yp.drumate) 
  ON m.extension=fc.extension AND origin_id=drumate.id 
  WHERE m.id=_node_id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_parent_node_attr` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_parent_node_attr`(
  IN _node_id VARCHAR(16)
)
BEGIN
  DECLARE _parent_id VARCHAR(16);
  SELECT parent_id FROM media WHERE id=_node_id INTO _parent_id;
  CALL mfs_node_attr(_parent_id);
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_post_chatfile` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_post_chatfile`(
  IN _in JSON , 
  OUT _out JSON
)
BEGIN
  DECLARE _message_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _author_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _origin_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _pid VARCHAR(16) CHARACTER SET ascii;
  DECLARE _file_name VARCHAR(1024);
  DECLARE _category VARCHAR(100) CHARACTER SET ascii;
  DECLARE _mimetype VARCHAR(100) CHARACTER SET ascii;
  DECLARE _geometry VARCHAR(100) CHARACTER SET ascii;
  DECLARE _ext VARCHAR(16) CHARACTER SET ascii ;
  DECLARE _filesize BIGINT UNSIGNED;
  DECLARE _isalink TINYINT(2) UNSIGNED DEFAULT 0;

  SELECT JSON_VALUE(_attributes, "$.message_id") INTO _message_id;
  SELECT JSON_VALUE(_attributes, "$.author_id") INTO _author_id;
  SELECT JSON_VALUE(_attributes, "$.origin_id") INTO _origin_id;
  SELECT JSON_VALUE(_attributes, "$.user_filename") INTO _file_name;
  SELECT JSON_VALUE(_attributes, "$.category") INTO _category;
  SELECT JSON_VALUE(_attributes, "$.extension") INTO _ext;
  SELECT JSON_VALUE(_attributes, "$.mimetype") INTO _mimetype;
  SELECT JSON_VALUE(_attributes, "$.geometry") INTO _geometry;
  SELECT JSON_VALUE(_attributes, "$.filesize") INTO _filesize;
  SELECT JSON_VALUE(_attributes, "$.isalink") INTO _isalink;

  CALL mfs_make_dir(node_id_from_path('/__chat__'), JSON_ARRAY(_message_id),0);
  SELECT node_id_from_path( CONCAT('/__chat__/',_message_id)) INTO _message_id;

  SET @args = JSON_OBJECT(
    "owner_id", _author_id,
    "origin_id", _origin_id,
    "filename",_file_name,
    "pid", _message_id,
    "category", _category,
    "ext", _ext,
    "mimetype", _mimetype,
    "filesize", _filesize,
    "geometry", _geometry,
    "isalink", 1
  );

  CALL mfs_create_node(@args, JSON_OBJECT(), _out);

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_pre_trash_next` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_pre_trash_next`(
  IN _nodes JSON,
  IN _uid VARCHAR(16) CHARACTER SET ascii,
  IN _modify_perm TINYINT(4)
)
BEGIN

  DECLARE _idx INT DEFAULT 0; 
  DECLARE _nid VARCHAR(16);
  DECLARE _shub_id VARCHAR(16);
  DECLARE _shub_db VARCHAR(40);
  DECLARE _user_db_name VARCHAR(255);


  DECLARE exit handler for sqlexception
  BEGIN
    ROLLBACK;
  END;
   

 START TRANSACTION;
  SELECT db_name FROM yp.entity WHERE id = _uid INTO _user_db_name;
  DROP TABLE IF EXISTS `_bin_media`; 
  CREATE TEMPORARY TABLE `_bin_media` (
        `filepath` VARCHAR(5000) NOT NULL DEFAULT '',
        `ownpath` VARCHAR(5000) NOT NULL DEFAULT '',
        `nid` varchar(16) CHARACTER SET ascii DEFAULT NULL,
        `pid` varchar(16) CHARACTER SET ascii DEFAULT NULL,
        `parent_id` varchar(16) CHARACTER SET ascii DEFAULT NULL,
        `home_id` varchar(16) CHARACTER SET ascii DEFAULT NULL,
        `capability` varchar(8) CHARACTER SET ascii DEFAULT '---',
        `owner_id` varchar(16) CHARACTER SET ascii DEFAULT NULL,
        `hub_id` varchar(16) CHARACTER SET ascii DEFAULT NULL,
        `status` varchar(20) NOT NULL DEFAULT 'active',
        `filename` varchar(128) DEFAULT NULL,
        `filesize` bigint(20) unsigned DEFAULT 0,
        `vhost` varchar(1024) DEFAULT NULL,
        `ext` varchar(100) CHARACTER SET ascii DEFAULT NULL,
        `ftype` varchar(16) NOT NULL DEFAULT 'other',
        `filetype` varchar(16) NOT NULL DEFAULT 'other',
        `mimetype` varchar(100) NOT NULL,
        `mtime` int(11) unsigned NOT NULL DEFAULT 0,
        `ctime` int(11) unsigned NOT NULL DEFAULT 0
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ;


  DROP TABLE IF EXISTS `_mytree`; 
  CREATE  TEMPORARY TABLE `_mytree` (
          id varchar(16)  CHARACTER SET ascii DEFAULT NULL,
          parent_id varchar(16)  CHARACTER SET ascii DEFAULT NULL,
          user_filename varchar(128) DEFAULT NULL,
          extension varchar(100) CHARACTER SET ascii DEFAULT NULL);


  WHILE _idx < JSON_LENGTH(_nodes) DO 

        SELECT JSON_UNQUOTE(JSON_EXTRACT(_nodes, CONCAT("$[", _idx, "]"))) INTO @_node;
        SELECT JSON_VALUE(@_node, "$.nid") INTO _nid;
        SELECT JSON_VALUE(@_node, "$.hub_id") INTO _shub_id;
        SELECT db_name FROM yp.entity WHERE id = _shub_id INTO _shub_db; 
        SELECT '' INTO @hub_path;
        SELECT '' INTO @hub_name;

        IF _uid != _shub_id THEN 
      
          SET @st = CONCAT("
            SELECT user_filename,parent_path
            FROM  ",_user_db_name,".media m 
            WHERE m.id='",_shub_id,"' INTO @hub_name , @parent_path"
          );

          PREPARE stmt FROM @st;
          EXECUTE stmt ;
          DEALLOCATE PREPARE stmt;
          SELECT CONCAT(@parent_path,'/',@hub_name) INTO @hub_path  ;
 
        END IF;  

        DELETE FROM _mytree;
        SET @st = CONCAT
        ( " 
           INSERT INTO _mytree
           WITH RECURSIVE mytree AS (
            SELECT id, parent_id ,user_filename, extension 
            FROM ",_shub_db,".media WHERE id =", QUOTE(_nid),"
            UNION ALL
            SELECT m.id, m.parent_id ,m.user_filename, m.extension
            FROM ",_shub_db,".media AS m JOIN mytree AS t ON m.parent_id = t.id
          )
         SELECT id, parent_id ,user_filename, extension FROM mytree;");
        PREPARE stmt FROM @st;
        EXECUTE stmt ;
        DEALLOCATE PREPARE stmt; 

        SET @st = CONCAT
        (
          "INSERT INTO ",_shub_db,".trash_media (sys_id,id,origin_id,owner_id,host_id,file_path,user_filename,parent_id,parent_path,extension,mimetype,
            category,isalink,filesize,geometry,publish_time,upload_time,last_download,download_count,
            metadata,caption,status,approval,rank)
           SELECT sys_id,id,origin_id,owner_id,host_id, file_path, user_filename ,parent_id,parent_path,extension,mimetype,
            category,isalink,filesize,geometry,publish_time,upload_time,last_download,download_count,
            metadata,caption,status,approval,rank
        FROM ",_shub_db,".media m WHERE id IN (SELECT id FROM _mytree);");
        PREPARE stmt FROM @st;
        EXECUTE stmt ;
        DEALLOCATE PREPARE stmt; 

        SET @st = CONCAT
        (" UPDATE ",_shub_db,".trash_media SET STATUS = 'deleted' WHERE  id =", QUOTE(_nid),";");
        PREPARE stmt FROM @st;
        EXECUTE stmt ;
        DEALLOCATE PREPARE stmt;

        SET @st = CONCAT ("DELETE FROM " ,_shub_db,".media WHERE id IN (SELECT id FROM _mytree);");
        PREPARE stmt FROM @st;
        EXECUTE stmt ;
        DEALLOCATE PREPARE stmt;


       SET @st = CONCAT("
              INSERT INTO _bin_media 
              (
              filepath,ownpath , nid, pid, parent_id, home_id, capability,
              owner_id, hub_id, status, filename, filesize,
              vhost, ext, ftype, filetype,
              mimetype, ctime, mtime
              )
              SELECT 
              CONCAT(@hub_path, m.file_path) as filepath,
              m.file_path as ownpath,
              m.id  AS nid,
              m.parent_id AS pid,
              m.parent_id AS parent_id,
              me.home_id AS home_id,
              ff.capability,
              me.id AS owner_id,
              me.id AS hub_id,
              m.status AS status,
              m.user_filename AS filename,
              m.filesize AS filesize,
              yp.vhost(me.id) AS vhost,
              m.extension AS ext,
              m.category AS ftype,
              m.category AS filetype,
              m.mimetype,
              m.upload_time AS ctime,
              m.publish_time AS mtime
            FROM ", _shub_db, ".trash_media m
              INNER JOIN yp.entity me ON me.db_name=", QUOTE(_shub_db),"
              LEFT JOIN yp.filecap ff ON m.extension=ff.extension
            WHERE m.status='deleted'  AND m.id =", QUOTE(_nid),"
            ");
         PREPARE stmt FROM @st;
         EXECUTE stmt ;
         DEALLOCATE PREPARE stmt;

      SELECT _idx + 1 INTO _idx;
  END WHILE; 
  COMMIT;
  SELECT * FROM _bin_media;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_purge` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_purge`(
  IN _id VARCHAR(16)
)
BEGIN
  DECLARE _node_path VARCHAR(255);
  DECLARE _category VARCHAR(40);
  DECLARE _filesize BIGINT UNSIGNED;
  DECLARE _hub_id VARCHAR(20);
  DECLARE _home_dir VARCHAR(1024);

  SELECT id ,home_dir FROM yp.entity WHERE db_name=database() INTO _hub_id, _home_dir;

  DROP TABLE IF EXISTS _mytree; 
  CREATE TEMPORARY TABLE _mytree (
      id varchar(16) DEFAULT NULL
  );

  INSERT INTO _mytree (id)  
    WITH RECURSIVE mytree AS (
      SELECT id, parent_id FROM media WHERE id = _id
      UNION ALL
      SELECT m.id,m.parent_id
      FROM media AS m JOIN mytree AS t ON m.parent_id = t.id
    )
    SELECT id FROM mytree;


  
  
  SELECT category, filesize FROM media WHERE id=_id into _category, _filesize;



  DROP TABLE IF EXISTS __purge_stack;
  CREATE TEMPORARY TABLE IF NOT EXISTS  __purge_stack LIKE template.tmp_id;

  IF _category='folder' THEN    
    SELECT SUM(filesize) FROM media 
    WHERE id IN (SELECT id FROM _mytree)
      AND category != 'hub' INTO _filesize;
  END IF;

  IF _category='form' THEN
    SET @s = CONCAT("DROP TABLE IF EXISTS `form_", _id, "`");
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;

  INSERT INTO __purge_stack SELECT id, CONCAT(_home_dir, "/__storage__/") 
  FROM media WHERE id IN ( SELECT id FROM _mytree);


  DELETE FROM media WHERE id IN (SELECT nid FROM __purge_stack);

  IF(SELECT count(*) FROM yp.disk_usage where hub_id=_hub_id) > 0 THEN 
    UPDATE yp.disk_usage SET size = (size - _filesize) WHERE hub_id = _hub_id;
  ELSE 
    INSERT INTO yp.disk_usage VALUES(null, _hub_id, 0);
  END IF;

  SELECT * FROM __purge_stack;
  DROP TABLE IF EXISTS __purge_stack;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_register` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_register`(
  IN _origin_id       VARCHAR(16),
  IN _user_filename   VARCHAR(512),
  IN _pid             VARCHAR(20),
  IN _category        VARCHAR(50),
  IN _extension       VARCHAR(100),
  IN _mimetype        VARCHAR(100),
  IN _geometry        VARCHAR(200),
  IN _file_size       INT(20) UNSIGNED,
  IN _show_results    BOOLEAN
)
BEGIN
  DECLARE _vhost VARCHAR(255);
  DECLARE _hub_id VARCHAR(16);
  DECLARE _area VARCHAR(50);
  DECLARE _home_dir VARCHAR(512);
  DECLARE _home_id VARCHAR(16);
  DECLARE _src_db_name VARCHAR(50);
  DECLARE _accessibility VARCHAR(20);

  DECLARE _fileid   VARCHAR(16) DEFAULT '';
  DECLARE _ts   INT(11) DEFAULT 0;
  DECLARE _parent_id TEXT;
  DECLARE _root_id VARCHAR(16);
  DECLARE _parent_path TEXT;
  DECLARE _parent_name VARCHAR(100) DEFAULT '';
  DECLARE _file_path   VARCHAR(1024);
  DECLARE _file_name VARCHAR(1024);

  SELECT UNIX_TIMESTAMP() INTO _ts;
  SELECT yp.uniqueId() INTO _fileid;

  CALL mediaEnv(_vhost, _hub_id, _area, _home_dir, _home_id, _src_db_name, _accessibility);

  IF IFNULL(_pid, '0') IN('', '0') THEN 
    SELECT id FROM media WHERE parent_id='0' INTO  _pid;
  END IF;

  SELECT id, TRIM('/' FROM user_filename) FROM media WHERE id=_pid 
    INTO _parent_id, _parent_name;
  IF _parent_id IS NULL OR _parent_id='' THEN 
    SELECT id FROM media m WHERE m.parent_id='0' INTO  _parent_id;
    
  END IF;
  

  SELECT COUNT(*) FROM media WHERE parent_id = _pid INTO @_count;

  SELECT parent_path(_parent_id) INTO _parent_path;
  SELECT REPLACE(_user_filename, CONCAT('.', _extension), '') INTO _file_name;
  SELECT unique_filename(_parent_id, _file_name, _extension) INTO _file_name;
  SELECT CONCAT(_parent_path, '/', _parent_name, '/', _file_name, '.', _extension) 
    INTO _file_path;


  INSERT INTO `media` (
    id, 
    origin_id, 

    file_path, 
    user_filename, 
    parent_id, 
    parent_path,

    extension, 
    mimetype, 
    category,
    isalink,

    filesize, 
    `geometry`, 
    publish_time, 
    upload_time, 

    `status`,
    rank
  ) VALUES (
    _fileid, 
    _origin_id, 

    clean_path(_file_path), 
    TRIM('/' FROM _file_name),
    _pid, 
    _parent_path,

    _extension, 
    _mimetype, 
    _category, 
    0,

    IFNULL(_file_size, 4096),
    IFNULL(_geometry, '0x0'), 
    _ts, 
    _ts, 

    IF(_category='stylesheet', 'idle', 'active'),
    @_count
  );
  
  
  DROP TABLE IF EXISTS __register_stack;
  CREATE TEMPORARY TABLE __register_stack LIKE template.tmp_media;
  INSERT INTO __register_stack VALUES (
    _fileid, 
    _origin_id, 

    clean_path(_file_path), 
    _file_name,
    _pid, 
    _parent_path,

    _extension, 
    _mimetype, 
    _category, 
    0,

    IFNULL(_file_size, 4096),
    IFNULL(_geometry, '0x0'), 
    _ts, 
    _ts, 

    'active',
    @_count
  );

  SET @perm = 0;
  SET @s = CONCAT(
    "SELECT " ,_src_db_name,".user_permission (", 
    QUOTE(_origin_id),",",QUOTE(_fileid), ") INTO @perm");
  PREPARE stmt FROM @s;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;   

  IF _category NOT IN ('hub', 'folder') THEN 
    UPDATE media SET metadata=JSON_MERGE(
      IFNULL(metadata, '{}'), 
      JSON_OBJECT('_seen_', JSON_OBJECT(_origin_id, 1))
    )
    WHERE id=_fileid;
  END IF; 

  IF IFNULL(_show_results, 0) != 0  THEN
    SELECT 
      m.id, 
      m.id as nid, 
      concat(_home_dir, "/__storage__/") AS mfs_root,
      parent_id AS pid,
      parent_id,
      _hub_id AS holder_id,
      _home_id AS home_id,
      _home_dir AS home_dir,
      @perm  AS privilege,
      _hub_id AS owner_id,    
      _hub_id AS hub_id,    
      _vhost AS vhost,    
      user_filename AS filename,
      filesize,
      _area AS area,
      caption,
      _accessibility AS accessibility,
      capability,
      m.extension,
      m.extension AS ext,
      m.category AS ftype,
      m.category AS filetype,
      m.mimetype,
      download_count AS view_count,
      geometry,
      upload_time AS ctime,
      publish_time AS ptime,
      firstname,
      lastname,
      m.category,
      user_filename,
      file_path, 
      parent_path
      FROM media m LEFT JOIN (yp.filecap, yp.drumate) ON 
      m.extension=filecap.extension AND origin_id=yp.drumate.id 
      WHERE m.id = _fileid;
  END IF ;

  IF(SELECT count(*) FROM yp.disk_usage where hub_id=_hub_id) > 0 THEN 
    UPDATE yp.disk_usage SET size = (size + _file_size) WHERE hub_id = _hub_id;
  ELSE 
    INSERT INTO yp.disk_usage VALUES(null, _hub_id, _file_size);
  END IF;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_remove_comment` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_remove_comment`(
  IN _id          VARBINARY(16)
)
BEGIN
  DELETE FROM comment WHERE id = _id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_rename` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_rename`(
  IN _nid VARCHAR(16),
  IN _new_name VARCHAR(255)
)
BEGIN

  DECLARE _category VARCHAR(40);
  DECLARE _parent_id VARCHAR(16);
  DECLARE _old_name VARCHAR(255);
  DECLARE _uniq_name VARCHAR(255);
  DECLARE _extension VARCHAR(255);

  SELECT category, parent_id, user_filename FROM media WHERE id=_nid 
    INTO _category, _parent_id, _old_name;  


  DROP TABLE IF EXISTS _mytree; 
  CREATE TEMPORARY TABLE _mytree (
    id varchar(16) DEFAULT NULL
  );

  INSERT INTO _mytree (id)  
  WITH RECURSIVE mytree AS (
    SELECT id, parent_id FROM media WHERE id = _nid
    UNION ALL
    SELECT m.id,m.parent_id
    FROM media AS m JOIN mytree AS t ON m.parent_id = t.id
  )
  SELECT id FROM mytree;

  IF _new_name != TRIM('/' FROM _old_name) THEN   
    UPDATE media SET 
      parent_path = parent_path(_nid), publish_time=UNIX_TIMESTAMP(),
      user_filename=unique_filename(_parent_id, _new_name, _extension) 
      WHERE id=_nid;
    UPDATE media SET parent_path = parent_path(id), file_path=filepath(id)
      WHERE id IN ( SELECT id FROM _mytree);
    
    
  END IF ;                    

  SELECT
    *,
    extension as ext,
    id as nid,
    origin_id as oid,
    parent_id as pid,
    IF(parent_id='0', 'root', 'branch') as npos,
    TRIM(TRAILING '/' FROM user_filename) as fname,
    TRIM(TRAILING '/' FROM user_filename) as filename,
    category AS filetype,
    upload_time AS ctime,
    publish_time AS mtime,
    file_path as filepath,
    category as ftype
  FROM media WHERE id=_nid;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_reorder` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_reorder`(
  IN _nodes JSON
)
BEGIN
  DECLARE _i INTEGER DEFAULT 0;
  DROP TABLE IF EXISTS __tmp_rank;
  CREATE TEMPORARY TABLE __tmp_rank(
    `rank` INTEGER,
    `id` varchar(16) CHARACTER SET utf8
  ); 

  WHILE _i < JSON_LENGTH(_nodes) DO 
     UPDATE media SET rank = _i 
       WHERE id = JSON_UNQUOTE(JSON_EXTRACT(_nodes, CONCAT("$[", _i, "]")));
    INSERT INTO __tmp_rank 
      SELECT _i, JSON_VALUE(_nodes, CONCAT("$[", _i, "]"));
    SELECT _i + 1 INTO _i;
  END WHILE;

  SELECT * FROM __tmp_rank;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_replace_tree` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_replace_tree`(
  IN _nid VARCHAR(16),
  IN _pid VARCHAR(16),
  IN _recipient_id VARCHAR(16)
)
BEGIN
   
  DECLARE _src_db VARCHAR(255);
  DECLARE _des_db VARCHAR(255); 


  DECLARE _origin_id      VARCHAR(16);   
  DECLARE _src_path       VARCHAR(1024); 
  DECLARE _des_path       VARCHAR(1024); 
  DECLARE _file_name      VARCHAR(512); 
  DECLARE _category       VARCHAR(50);   
  DECLARE _extension      VARCHAR(100); 
  DECLARE _mimetype       VARCHAR(100);      
  DECLARE _file_size      INT(20) UNSIGNED;
  DECLARE _geometry       VARCHAR(200);       
  DECLARE _status         VARCHAR(50); 
  DECLARE _finished       INTEGER DEFAULT 0;
  DECLARE _seq            INTEGER;  
  DECLARE _id             VARCHAR(16);  

  
  SELECT  database() INTO _src_db;  
  SELECT db_name FROM yp.entity WHERE id=_recipient_id OR ident =_recipient_id INTO _des_db;

  SET @sql = CONCAT( 
    "SELECT CONCAT(" ,_src_db ,".parent_path(id),user_filename, '/') FROM " ,_src_db ,".media WHERE id =" ,QUOTE( _nid),
    "INTO @srcpattern ");
  PREPARE stmt FROM @sql;
  EXECUTE stmt;


   SET @sql = CONCAT( 
    "SELECT CONCAT(" ,_des_db ,".parent_path(id),user_filename, '/') FROM " ,_des_db ,".media WHERE id =" ,QUOTE( _pid),
    "INTO @descpattern ");
  PREPARE stmt FROM @sql;
  EXECUTE stmt;  


  SET @sql = CONCAT( 
    "SELECT CONCAT(" ,_des_db ,".parent_path(id),user_filename) FROM " ,_des_db ,".media WHERE id =" ,QUOTE( _pid),
    "INTO @despath ");
  PREPARE stmt FROM @sql;
  EXECUTE stmt;

 SELECT  clean_path(@srcpattern) INTO @srcpattern; 
 SELECT  clean_path(@despath) INTO @srcpath; 
 SELECT  clean_path(@descpattern) INTO @descpattern;   
  
    DROP TABLE IF EXISTS  _src_media;
    CREATE TEMPORARY TABLE `_src_media` (
      `seq`  int NOT NULL AUTO_INCREMENT,
      `id` varchar(16) DEFAULT NULL,
      `origin_id` varchar(16) DEFAULT NULL,
      `user_filename` varchar(128) DEFAULT NULL,
      `category`      VARCHAR(50) DEFAULT NULL,
      `parent_id` varchar(16) DEFAULT '',
      `extension` varchar(100) NOT NULL DEFAULT '',
      `mimetype` varchar(100) NOT NULL,
      `filesize` int(20) unsigned NOT NULL DEFAULT '0',
      `geometry` varchar(200) NOT NULL DEFAULT '0x0',
      `xpath` varchar(5000) DEFAULT ''  ,
      `new_id` varchar(16) DEFAULT NULL,  
      `new_parent_id` varchar(16) DEFAULT '' , 
      `is_checked` boolean default 0 ,
       lvl int(3),
       PRIMARY KEY `seq`(`seq`)  
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
    
    DROP TABLE IF EXISTS _des_media;
    CREATE TEMPORARY TABLE `_des_media` (
      
      `id` varchar(16) DEFAULT NULL,
      `origin_id` varchar(16) DEFAULT NULL,
      `user_filename` varchar(128) DEFAULT NULL,
      `category`      VARCHAR(50) DEFAULT NULL,
      `parent_id` varchar(16) DEFAULT '',
      `extension` varchar(100) NOT NULL DEFAULT '',
      `mimetype` varchar(100) NOT NULL,
      `filesize` int(20) unsigned NOT NULL DEFAULT '0',
      `geometry` varchar(200) NOT NULL DEFAULT '0x0',
      `xpath` varchar(5000) DEFAULT '' 
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
    
   

  SET @sql = CONCAT(" 
    INSERT INTO _src_media 
    SELECT null, id,origin_id,user_filename,category,parent_id, extension,mimetype,filesize,geometry,
    clean_path(CONCAT(" ,_des_db ,".parent_path(id),'/',user_filename,'.', extension )) xpath     
    ,null,null,0,0
    FROM  " ,_src_db ,".media m 
    WHERE m.category <> 'hub'  AND CONCAT(" ,_src_db ,".parent_path(id),user_filename,'/' ) 
    LIKE CONCAT(@srcpattern,'%') ");
  PREPARE stmt FROM @sql;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;

  SET @sql = CONCAT(" 
    INSERT INTO _des_media
    SELECT  id,origin_id,user_filename,category,parent_id, extension,mimetype,filesize,geometry,
    clean_path(REPLACE (clean_path(CONCAT(" ,_des_db ,".parent_path(id),'/',user_filename,'.',extension )),@despath,'' )) xpath 
    FROM  " ,_des_db ,".media m      	
    WHERE id <> ", QUOTE( _pid) ,"
    AND CONCAT(" ,_des_db ,".parent_path(id),user_filename,'/' ) 
    LIKE CONCAT(@descpattern,'%')");
  PREPARE stmt FROM @sql;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;  
 
 
 UPDATE _src_media SET new_parent_id = _pid where id = _nid; 

 UPDATE _src_media s,_des_media d SET s.new_parent_id = d.parent_id , s.new_id=d.id WHERE  s.xpath = d.xpath;

 DROP TABLE IF EXISTS _src_temp_media;
 CREATE TABLE _src_temp_media as SELECT * FROM _src_media;

 UPDATE _src_media s , _src_temp_media d SET s.new_parent_id = d.new_id  WHERE  s.parent_id = d.id;

 
 UPDATE _src_media set lvl= (LENGTH(xpath)-LENGTH(REPLACE(xpath, '/', '')));

 BEGIN
    DECLARE dbcursor CURSOR FOR SELECT seq,id,origin_id,user_filename,category,extension,mimetype,`geometry`,filesize FROM _src_media WHERE new_id is null order by lvl asc;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET _finished = 1;
    OPEN dbcursor;
        STARTLOOP: LOOP
         FETCH dbcursor INTO _seq,_id,_origin_id,_file_name,_category,_extension,_mimetype,_geometry,_file_size;
         IF _finished = 1 THEN 
            LEAVE STARTLOOP;
         END IF;


    
        SET @s1 = CONCAT( "CREATE TEMPORARY TABLE IF NOT EXISTS  ",_des_db,".__register_stack LIKE template.tmp_media"); 
        PREPARE stmt FROM @s1;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

        SET @s1 = CONCAT( "DELETE FROM ",_des_db,".__register_stack"); 
        PREPARE stmt1 FROM @s1;
        EXECUTE stmt1;
        DEALLOCATE PREPARE stmt1;
        
        SELECT new_parent_id  FROM _src_media WHERE seq =_seq INTO _pid; 

        SET @s2 = CONCAT("CALL ",_des_db,".mfs_register(",
            "'"  , _origin_id     , "'," ,
            "'"  , _file_name     , "'," ,
            "'"  , _pid           , "'," ,
            "'"  , _category      , "'," ,
            "'"  , _extension     , "'," ,
            "'"  , _mimetype      , "'," ,
            "'"  , _geometry      , "'," ,
                   _file_size     , ", 0 )"          
          );
        PREPARE stmt2 FROM @s2;
        EXECUTE stmt2;
        DEALLOCATE PREPARE stmt2;  

        SET @s3 = CONCAT( "SELECT id ,parent_id FROM ",_des_db,".__register_stack INTO @temp_nid,@pid");
        PREPARE stmt3 FROM @s3;
        EXECUTE stmt3;
        DEALLOCATE PREPARE stmt3;

        UPDATE _src_media SET new_id =@temp_nid , new_parent_id = @pid  WHERE seq =_seq ; 
        UPDATE _src_media SET new_parent_id =  @temp_nid    WHERE parent_id = _id; 
    END LOOP STARTLOOP;
   CLOSE dbcursor; 

 END;   



    SET @s3 = CONCAT( "DELETE FROM ",_des_db,".media WHERE id in (SELECT id from _des_media WHERE xpath NOT IN ( SELECT xpath FROM _src_media)) ");
    PREPARE stmt3 FROM @s3;
    EXECUTE stmt3;
    DEALLOCATE PREPARE stmt3;



    CALL mediaEnv(@_tmp, @tmp, @_tmp, @home_dir, @_tmp, @_tmp, @_tmp);   
    
    SET @s2 = CONCAT( "CALL ",_des_db,".mediaEnv(@_tmp, @_tmp, @_tmp, @des_home_dir, @_tmp, @_tmp, @_tmp)") ;
     PREPARE stmt2 FROM @s2;
     EXECUTE stmt2;
     DEALLOCATE PREPARE stmt2; 



  DROP TABLE IF EXISTS _final_media; 
      CREATE TEMPORARY TABLE `_final_media` (
      nid varchar(16) DEFAULT NULL,  
      new_id varchar(16) DEFAULT NULL,    
      action varchar(16) DEFAULT NULL,
      mfs_root varchar(1024)  DEFAULT NULL
      );   
        
 

  INSERT INTO   _final_media  
  SELECT new_id AS nid ,new_id AS dest_id, 'show'   AS action, null as mfs_root  FROM _src_media WHERE seq = 1 ;

  INSERT INTO   _final_media
  SELECT id   AS nid ,new_id AS dest_id, 'copy'   AS action, null as mfs_root  FROM _src_media WHERE category NOT IN ("folder","hub");

  INSERT INTO   _final_media
  SELECT id   AS nid ,null   AS dest_id, 'delete' AS action, CONCAT(@des_home_dir, "/__storage__/") as mfs_root  FROM _des_media WHERE xpath NOT IN ( SELECT xpath FROM  _src_media) AND category NOT IN ("folder","hub");

  SELECT * FROM  _final_media;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_restore` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_restore`(
  IN _id VARCHAR(16)
)
BEGIN
  
  DECLARE _category VARCHAR(40);
  DECLARE _node_path VARCHAR(6000);
  DECLARE _trash_parent_parent_path VARCHAR(6000);
  DECLARE _trash_parent_id VARCHAR(16);
  DECLARE _restore_parent_id VARCHAR(16);
  DECLARE _home_id VARCHAR(16);
  
  DECLARE _temp_id VARCHAR(16);
  DECLARE _trash_home_id VARCHAR(16);

  DECLARE _lvl INT;

  SELECT node_id_from_path('/__trash__') INTO _trash_home_id;
  
  SELECT category INTO _category FROM media t WHERE id = _id;
  SELECT id INTO _home_id FROM media t WHERE ( parent_id IS NULL OR parent_id="" OR parent_id='0');

  IF _id <> _home_id THEN 
    SELECT 
      id,
      clean_path(concat(parent_path(t.id), '/', t.user_filename))
    INTO 
      _trash_parent_id, 
      _trash_parent_parent_path 
    FROM media t WHERE id=(SELECT parent_id FROM media WHERE id = _id); 
    

    IF _trash_parent_id = _trash_home_id THEN 
      SELECT id FROM media WHERE ( parent_id IS NULL OR parent_id="" OR parent_id='0') INTO _restore_parent_id;
    ELSE  
      SELECT node_id_from_path(REPLACE(_trash_parent_parent_path,'/__trash__','')) INTO _restore_parent_id;
    END IF; 


    UPDATE media SET parent_id=_restore_parent_id, status='active' WHERE id=_id;  
    UPDATE media SET parent_path = parent_path(id),file_path = clean_path(concat(parent_path(id), '/', user_filename, '.', extension)) 
    WHERE id = _id;

    IF _category='folder' THEN
      SELECT CONCAT(parent_path(id),user_filename) FROM media WHERE id=_id INTO _node_path;
      UPDATE media 
        SET parent_path = parent_path(id),file_path = clean_path(concat(parent_path(id), '/', user_filename, '.', extension)), status='active'
      WHERE CONCAT(parent_path(id),user_filename ) LIKE concat(_node_path, '/%'); 
    END IF;

    WHILE  _trash_parent_id <> _trash_home_id AND IFNULL(_lvl,0) < 1000 DO 
      SELECT NULL INTO _temp_id;
      SELECT parent_id FROM media WHERE id =_trash_parent_id INTO _temp_id; 
      DELETE FROM media WHERE id = _trash_parent_id  AND  CONCAT(parent_path(id),user_filename ) LIKE concat('/__trash__', '/%'); 
      SELECT _temp_id INTO _trash_parent_id;
      SELECT IFNULL(_lvl,0) +1  INTO _lvl;
    END WHILE;
  ELSE 
    SELECT 1 failed, "Could not restore root itself";
  END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_restore_into_next` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_restore_into_next`(
  IN _nodes JSON,
  IN _uid VARCHAR(16) CHARACTER SET ascii 
)
BEGIN

  DECLARE _idx INT(4) DEFAULT 0; 
  DECLARE _nid VARCHAR(16) CHARACTER SET ascii;
  DECLARE _dest_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _recipient_id VARCHAR(16);
  DECLARE _shub_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _shub_db VARCHAR(40);
  DECLARE _dhub_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _dhub_db VARCHAR(40);
  DECLARE _dhome_dir VARCHAR(512) DEFAULT null;
  DECLARE _shome_dir VARCHAR(512) DEFAULT null;


  DECLARE exit handler for sqlexception
  BEGIN
    ROLLBACK;
  END;
   
  DECLARE exit handler for sqlwarning
  BEGIN
    ROLLBACK;
  END;

  START TRANSACTION;


 DROP TABLE IF EXISTS _mytree; 
    CREATE  TEMPORARY TABLE _mytree (
          id varchar(16)  CHARACTER SET ascii DEFAULT NULL,
          parent_id varchar(16)  CHARACTER SET ascii DEFAULT NULL,
          user_filename varchar(128) DEFAULT NULL,
          extension varchar(100) CHARACTER SET ascii DEFAULT NULL,
          category varchar(16) NOT NULL DEFAULT 'other',
          flag  TINYINT default 0,
          shub_id varchar(16)  CHARACTER SET ascii DEFAULT NULL,
          dhub_id varchar(16)  CHARACTER SET ascii DEFAULT NULL,
          shome_dir VARCHAR(512) DEFAULT null,
          dhome_dir VARCHAR(512) DEFAULT null,
          shub_db VARCHAR(40),
          dhub_db VARCHAR(40),
          is_show INT DEFAULT 0,
          nid varchar(16)  CHARACTER SET ascii DEFAULT NULL
        );


  WHILE _idx < JSON_LENGTH(_nodes) DO 

        SELECT JSON_UNQUOTE(JSON_EXTRACT(_nodes, CONCAT("$[", _idx, "]"))) INTO @_node;
        SELECT JSON_VALUE(@_node, "$.nid") INTO _nid;
        SELECT JSON_VALUE(@_node, "$.hub_id") INTO _shub_id;
        SELECT JSON_VALUE(@_node, "$.pid") INTO _dest_id;
        SELECT JSON_VALUE(@_node, "$.recipient_id") INTO _dhub_id;
        
        SELECT db_name,home_dir FROM yp.entity WHERE id = _shub_id INTO _shub_db,_shome_dir; 
        SELECT db_name,home_dir FROM yp.entity WHERE id = _dhub_id INTO _dhub_db,_dhome_dir; 


        SET @st = CONCAT
        (
          "INSERT INTO _mytree (id,parent_id,user_filename,extension,category,flag,nid)
           WITH RECURSIVE mytree AS 
          (
            SELECT id, ",QUOTE(_dest_id), " parent_id ,user_filename, extension,category,0 flag,", QUOTE(_nid ) ," nid   
            FROM  ",_shub_db,".trash_media WHERE id = ", QUOTE(_nid) , "
              UNION ALL
            SELECT m.id, m.parent_id ,m.user_filename, m.extension,m.category ,0 ,", QUOTE(_nid)," 
            FROM ",_shub_db,".trash_media AS m JOIN mytree AS t ON m.parent_id = t.id
          )
          SELECT id,parent_id,user_filename,extension,category,flag,nid FROM mytree;"
        );
        PREPARE stmt FROM @st;
        EXECUTE stmt ;
        DEALLOCATE PREPARE stmt; 


        SET @st = CONCAT
        (
        "UPDATE _mytree m
        INNER JOIN ",_dhub_db,".media t  ON t.parent_id = m.parent_id 
              AND t.user_filename = m.user_filename 
              AND t.extension = m.extension
              AND m.nid =",QUOTE(_nid),"
        SET m.flag = 1;"
        );
        PREPARE stmt FROM @st;
        EXECUTE stmt ;
        DEALLOCATE PREPARE stmt;

        SET @st = CONCAT
        (
        "INSERT INTO ",_dhub_db,".media 
            (sys_id,id,origin_id,owner_id,host_id,file_path,user_filename,parent_id,parent_path,extension,mimetype,
            category,isalink,filesize,geometry,publish_time,upload_time,last_download,download_count,
            metadata,caption,status,approval,rank)
         SELECT 
            m.sys_id,m.id,m.origin_id,m.owner_id,m.host_id,m.id file_path, m.user_filename ,s.parent_id,m.id parent_path,m.extension,m.mimetype,
            m.category,m.isalink,m.filesize,m.geometry,m.publish_time,m.upload_time,m.last_download,m.download_count,
            m.metadata,m.caption,'active',m.approval,m.rank
         FROM ",_shub_db,".trash_media m 
        INNER JOIN _mytree s ON s.id = m.id
        WHERE s.flag =0  AND s.nid =",QUOTE(_nid),";"
        );
        PREPARE stmt FROM @st;
        EXECUTE stmt ;
        DEALLOCATE PREPARE stmt;

        SET @st = CONCAT
        (
          "INSERT INTO ",_dhub_db,".media (sys_id,id,origin_id,owner_id,host_id,file_path,user_filename,parent_id,parent_path,extension,mimetype,
              category,isalink,filesize,geometry,publish_time,upload_time,last_download,download_count,
              metadata,caption,status,approval,rank)
          SELECT m.sys_id,m.id,m.origin_id,m.owner_id,m.host_id,m.id file_path, ",_dhub_db,".unique_filename(s.parent_id, m.user_filename, m.extension) ,s.parent_id,m.parent_path,m.extension,m.mimetype,
              m.category,m.isalink,m.filesize,m.geometry,m.publish_time,m.upload_time,m.last_download,m.download_count,
              m.metadata,m.caption,'active',m.approval,m.rank
          FROM ",_shub_db,".trash_media m 
          INNER JOIN _mytree s ON s.id = m.id
          WHERE flag =1 AND s.nid =",QUOTE(_nid),";"
          );
        PREPARE stmt FROM @st;
        EXECUTE stmt ;
        DEALLOCATE PREPARE stmt;


        SET @st = CONCAT("UPDATE ", _dhub_db, 
              ".media SET parent_path=",_dhub_db,".parent_path(id) WHERE id IN (SELECT id FROM _mytree  WHERE nid =",QUOTE(_nid) ,");"
            );
        PREPARE stmt FROM @st;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

        SET @st = CONCAT("UPDATE ", _dhub_db, 
              ".media SET file_path =clean_path(concat(parent_path, '/', user_filename, '.', extension)) WHERE id IN (SELECT id FROM _mytree  WHERE nid =", QUOTE(_nid),");"
            );
        PREPARE stmt FROM @st;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;


        SET @st = CONCAT("UPDATE yp.disk_usage SET size = IFNULL(size,0) - (SELECT IFNULL(SUM(filesize),0) FROM " ,_shub_db, ".trash_media  WHERE id IN (SELECT id FROM _mytree  WHERE nid =", QUOTE(_nid) ,")) WHERE hub_id =",QUOTE( _shub_id),";");
        PREPARE stmt FROM @st;
        EXECUTE stmt ;
        DEALLOCATE PREPARE stmt; 


        SET @st = CONCAT("UPDATE yp.disk_usage SET size = IFNULL(size,0) + (SELECT IFNULL(SUM(filesize),0) FROM " ,_shub_db, ".trash_media  WHERE id IN (SELECT id FROM _mytree  WHERE nid =", QUOTE(_nid) ,")) WHERE hub_id =",QUOTE( _dhub_id),";");
        PREPARE stmt FROM @st;
        EXECUTE stmt ;
        DEALLOCATE PREPARE stmt; 


        SET @st = CONCAT
        (
        "DELETE FROM ",_shub_db,".trash_media WHERE id IN (SELECT id FROM _mytree  WHERE nid =", QUOTE(_nid) ,");"
        );
        PREPARE stmt FROM @st;
        EXECUTE stmt ;
        DEALLOCATE PREPARE stmt;

      UPDATE  _mytree SET is_show = 1  WHERE id =_nid;
      
      
      
        DELETE FROM _mytree WHERE category IN ("hub") AND is_show =0;
        UPDATE _mytree 
            SET  shub_db = _shub_db,shome_dir = _shome_dir ,shub_id =_shub_id,
                dhub_db = _dhub_db,dhome_dir = _dhome_dir,dhub_id=_dhub_id
            WHERE nid =_nid;
      

      SELECT NULL,NULL INTO _dhub_db ,_shub_db;
      SELECT _idx + 1 INTO _idx;
  END WHILE; 

  COMMIT;

  SELECT id nid,  CONCAT(_shome_dir, "/__storage__/") src_mfs_root,  id des_id , CONCAT(_dhome_dir, "/__storage__/") des_mfs_root,
      dhub_id dest_hub_id, dhub_db dest_db_name , 'move' `action`
  FROM _mytree WHERE category NOT IN ("folder","hub") 
    UNION ALL
  SELECT id nid,  CONCAT(_shome_dir, "/__storage__/") src_mfs_root,  id des_id , CONCAT(_dhome_dir, "/__storage__/") des_mfs_root,
      dhub_id dest_hub_id, dhub_db dest_db_name , 'show' `action`
  FROM _mytree WHERE is_show = 1 ; 

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_root_conflict_files` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_root_conflict_files`(
  IN _src_ids VARCHAR(5000),
  IN _dest_pids VARCHAR(5000),
  IN _des_entity_id VARCHAR(16)
  )
BEGIN
  DECLARE _category VARCHAR(40);
  DECLARE _src_db   VARCHAR(255);
  DECLARE _des_db   VARCHAR(255);
 
  
  SELECT DATABASE()  INTO _src_db;
  SELECT db_name from yp.entity WHERE id=_des_entity_id INTO _des_db;

  
    SELECT ',' INTO @dlm;
    SELECT _src_ids INTO @lst;
    DROP TABLE IF EXISTS _src_lsttbl; 
    CREATE TEMPORARY TABLE _src_lsttbl(`id` varchar(16) DEFAULT NULL); 
    SELECT  LENGTH(@lst) - LENGTH(REPLACE(@lst, @dlm, '')) into @lmt;
    SELECT @lmt+1 into @lmt;
    
    INSERT INTO _src_lsttbl
    SELECT
      SUBSTRING_INDEX(SUBSTRING_INDEX(mytbl.id, @dlm, cnt.n), @dlm, -1) id
    FROM
      (
        SELECT (ons + 10*tns +100*hrds) +1 n FROM 
        (SELECT 0 ons UNION SELECT 1  UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) a,
        (SELECT 0 tns UNION SELECT 1  UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) b,
            (SELECT 0 hrds UNION SELECT 1  UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) c
        WHERE (ons + 10*tns +100*hrds +1)<=@lmt
        ) cnt 
    INNER JOIN (SELECT @lst as id) mytbl ON CHAR_LENGTH(mytbl.id)-CHAR_LENGTH(REPLACE(mytbl.id, @dlm, ''))>=cnt.n-1;
  
  
  
    SELECT ',' INTO @dlm;
    SELECT _dest_pids INTO @lst;
    DROP TABLE IF EXISTS _dest_lsttbl; 
    CREATE TEMPORARY TABLE _dest_lsttbl(`id` varchar(16) DEFAULT NULL); 
    SELECT  LENGTH(@lst) - LENGTH(REPLACE(@lst, @dlm, '')) into @lmt;
    SELECT @lmt+1 into @lmt;
    
    INSERT INTO _dest_lsttbl
    SELECT
      SUBSTRING_INDEX(SUBSTRING_INDEX(mytbl.id, @dlm, cnt.n), @dlm, -1) id
    FROM
      (
        SELECT (ons + 10*tns +100*hrds) +1 n FROM 
        (SELECT 0 ons UNION SELECT 1  UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) a,
        (SELECT 0 tns UNION SELECT 1  UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) b,
            (SELECT 0 hrds UNION SELECT 1  UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) c
        WHERE (ons + 10*tns +100*hrds +1)<=@lmt
        ) cnt 
    INNER JOIN (SELECT @lst as id) mytbl ON CHAR_LENGTH(mytbl.id)-CHAR_LENGTH(REPLACE(mytbl.id, @dlm, ''))>=cnt.n-1;
  


    SET @sql = CONCAT(
    '   SELECT 
          s.id source_id,
          s.category ,
          s.user_filename name,
          dp.id dest_id,
          dp.user_filename availablein

        FROM ',_src_db,' .media s
            INNER JOIN ',_des_db,'.media d ON d.user_filename= s.user_filename
            AND s.category = d.category
            INNER JOIN _dest_lsttbl dl on d.parent_id = dl.id
            INNER JOIN _src_lsttbl sl on sl.id = s.id
            INNER JOIN ',_des_db,'.media dp on dp.id=dl.id
            ');
        
    PREPARE stmt FROM @sql ;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

  
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_root_is_exist` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_root_is_exist`(
  IN _src_id VARCHAR(16),
  IN _dest_pid VARCHAR(16),
  IN _des_entity_id VARCHAR(16)
  )
BEGIN
  DECLARE _category VARCHAR(40);
  DECLARE _src_db   VARCHAR(255);
  DECLARE _des_db   VARCHAR(255);

  SELECT DATABASE()  INTO _src_db;
  SELECT db_name from yp.entity WHERE id=_des_entity_id INTO _des_db;

    SET @sql = CONCAT(
    ' SELECT 
          CASE 
              WHEN source.category in ("folder") THEN  2 
              ELSE 1 END status, source.id as nid, destination.id as dest_id
        FROM ',_src_db,' .media source
            INNER JOIN ',_des_db,'.media destination ON destination.user_filename= source.user_filename
            AND source.category = destination.category AND destination.status  = "active"
        WHERE 
          (source.id =''',_src_id,''') AND
          destination.parent_id=''',_dest_pid,'''');
    PREPARE stmt FROM @sql ;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

  
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_search` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_search`(
  IN _pattern VARCHAR(84),
  IN _cat VARCHAR(84),
  IN _page TINYINT(4)
)
BEGIN

  DECLARE _range bigint;
  DECLARE _offset bigint;
  CALL pageToLimits(_page, _offset, _range);

  SELECT   
    media.id   as nid,
    origin_id  AS origin_id,
    @entity_id AS oid,
    extension as ext,
    media.category as filetype,
    user_filename as filename,
    firstname,
    lastname,
    caption,
    filesize,
    upload_time as mtime,
    download_count as views,
    MATCH(`caption`,`user_filename`,`file_path`,`metadata`)
      against(_pattern IN NATURAL LANGUAGE MODE WITH QUERY EXPANSION)
    + IF(MATCH(`caption`,`user_filename`,`file_path`,`metadata`)
      against(concat(_pattern, '*') IN BOOLEAN MODE), 30, 0)
    + IF(user_filename = _pattern, 100, 0)
    + IF(user_filename LIKE concat("%", _pattern, "%"), 27, 0) AS score
    FROM media INNER JOIN yp.drumate ON origin_id=drumate.id HAVING  score > 25 
    AND media.category=_cat
    ORDER BY score DESC, mtime ASC LIMIT _offset, _range;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_set_attr` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_set_attr`(
  IN _id        VARCHAR(16),
  IN _column    VARCHAR(200),
  IN _value     JSON
)
BEGIN
  IF _column='metadata' THEN
    IF NOT JSON_VALID(_value) THEN
      SELECT '{}' INTO _value;
    END IF;
    IF JSON_VALID(_value) THEN 
      UPDATE media SET metadata=_value where id=_id;
    END IF;
  ELSE 
    SET @s = CONCAT("UPDATE media SET `", _column, "`='", _value, "' WHERE id='", _id, "'");
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;
  CALL mfs_node_attr(_id);
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_set_home_id` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_set_home_id`(
)
BEGIN
  DECLARE _i INT(4) DEFAULT 0; 
  DECLARE _pid VARCHAR(16);
  DECLARE _status VARCHAR(16);
  DECLARE _path TEXT;
  SELECT id FROM media WHERE parent_id='0' INTO _pid;
  UPDATE yp.entity SET home_id=_pid WHERE db_name=database(); 
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_set_metadata` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_set_metadata`(
  IN _id        VARCHAR(16),
  IN _value     JSON,
  IN _show_res BOOLEAN    
)
BEGIN

  DECLARE _idx INTEGER DEFAULT 0;
  DECLARE _key VARCHAR(100);
  DECLARE _val JSON;

  IF JSON_VALID(_value) THEN
    SELECT JSON_KEYS(_value) INTO @_keys;
    WHILE _idx < JSON_LENGTH(@_keys) DO
      SELECT JSON_VALUE(@_keys, CONCAT("$[", _idx, "]")) INTO _key;
      SELECT IFNULL( JSON_VALUE(_value, CONCAT("$.", _key)) , JSON_QUERY(_value, CONCAT("$.", _key))) INTO _val;

      IF _key = "fingerprint"  AND  _val <> '' THEN
        SELECT sha2(_val, 512) INTO _val;
      END IF;
      IF _key = "expiry" THEN
        SELECT IF(IFNULL(_val, 0) = 0, 0,
          UNIX_TIMESTAMP(TIMESTAMPADD(HOUR,_val, FROM_UNIXTIME(UNIX_TIMESTAMP())))) INTO _val;
      END IF;
     
      UPDATE media SET metadata=JSON_SET(
        IF(JSON_VALID(metadata), metadata, "{}"), CONCAT("$.", _key), _val) WHERE id=_id;
      SELECT _idx + 1 INTO _idx;
    END WHILE;
  END IF;
  
  UPDATE media SET publish_time = UNIX_TIMESTAMP() WHERE id=_id;
  IF _show_res THEN
    CALL mfs_node_attr(_id);
  END IF;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_set_node_attr` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_set_node_attr`(
  IN _id    VARBINARY(16),
  IN _data  JSON,
  IN _show      BOOLEAN
)
BEGIN
  DECLARE _value VARCHAR(5000);
  DECLARE _field VARCHAR(5000);
  DECLARE _fields VARCHAR(5000);
  DECLARE _i TINYINT(4) DEFAULT 0;


  SELECT JSON_ARRAY(
    "origin_id",
    "owner_id",
    "host_id",
    "file_path",
    "user_filename",
    "parent_id",
    "parent_path",
    "extension",
    "mimetype",
    "category",
    "filesize",
    "geometry",
    "publish_time",
    "upload_time",
    "last_download",
    "download_count",
    "metadata",
    "caption",
    "status",
    "approval",
    "rank"
  ) INTO _fields;
  WHILE _i < JSON_LENGTH(_fields) DO
    SELECT read_json_array(_fields, _i) INTO _field;
    SELECT JSON_VALUE(_data, CONCAT("$.",_field)) INTO _value;
    IF _value IS NOT NULL THEN
      SET @s = CONCAT("UPDATE media SET ", _field, "=? WHERE id=", QUOTE(_id));
      PREPARE stmt FROM @s;
      EXECUTE stmt USING _value;
      DEALLOCATE PREPARE stmt;
    END IF;
    SELECT _i + 1 INTO _i;
  END WHILE;
  IF _show THEN 
    CALL mfs_node_attr(_id);
  END IF;  

  
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_share_file` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_share_file`(
  IN _node_id VARCHAR(16),
  IN _dest_id VARCHAR(16),
  IN _dest_hub VARCHAR(100)
)
BEGIN

  DECLARE _id VARCHAR(16);
  DECLARE _ts   INT(11) DEFAULT 0;
  DECLARE _offset bigint;
  DECLARE _vhost VARCHAR(255);
  DECLARE _hub_id VARCHAR(16);
  DECLARE _area VARCHAR(50);
  DECLARE _home_dir VARCHAR(512);
  DECLARE _db_name VARCHAR(30);

  SELECT db_name  FROM yp.entity 
    WHERE id=_dest_id OR ident=_dest_id OR utils.vhost(ident)=_dest_id INTO _db_name;

  SELECT yp.uniqueId() INTO _id;
  SELECT UNIX_TIMESTAMP() INTO _ts;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_show_bin` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_show_bin`(
  IN _page TINYINT(4)
)
BEGIN
  DECLARE _hub_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _db_name VARCHAR(60) CHARACTER SET ascii;
  DECLARE _home_dir VARCHAR(300) CHARACTER SET ascii;
  DECLARE _home_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _range bigint;
  DECLARE _offset bigint;


  CALL pageToLimits(_page, _offset, _range);

  DROP TABLE IF EXISTS `_hubs`; 
  CREATE  TEMPORARY TABLE `_hubs` 
    (
      hub_id varchar(16)  CHARACTER SET ascii DEFAULT NULL,
      db_name varchar(60)  CHARACTER SET ascii DEFAULT NULL,
      home_dir varchar(300)  CHARACTER SET ascii DEFAULT NULL,
      is_checked int default 0      
    );

  DROP TABLE IF EXISTS _bin_media;
  CREATE TEMPORARY TABLE _bin_media  AS
    SELECT
      m.id  AS nid,
      m.parent_id AS pid,
      m.parent_id AS parent_id,
      _home_id AS home_id,
      ff.capability,
      me.id AS owner_id,
      me.id AS hub_id,
      m.status AS status,
      m.user_filename AS filename,
      m.filesize AS filesize,
      yp.vhost(me.id) AS vhost,
      m.extension AS ext,
      m.category AS ftype,
      m.category AS filetype,
      m.mimetype,
      m.upload_time AS mtime,
      m.publish_time AS ctime
    FROM  trash_media m
      INNER JOIN yp.entity me  ON me.db_name=database()
      LEFT JOIN yp.filecap ff ON m.extension=ff.extension
    WHERE m.status='deleted';

  INSERT INTO _hubs
  SELECT id hub, db_name,home_dir,0 FROM 
  yp.entity WHERE id IN(
  SELECT id FROM media m INNER JOIN permission p 
  ON p.resource_id = m.id AND p.permission>=15 AND m.status='active' );

  SELECT hub_id,db_name,home_dir  FROM _hubs WHERE is_checked = 0 LIMIT 1 INTO _hub_id ,_db_name , _home_dir;
  WHILE  _hub_id IS NOT NULL DO 

    SET @sql = CONCAT("
      INSERT INTO _bin_media 
      (
      nid, pid, parent_id, home_id, capability,
      owner_id, hub_id, status, filename, filesize,
      vhost, ext, ftype, filetype,
      mimetype, ctime, mtime
      )
      SELECT 
      m.id  AS nid,
      m.parent_id AS pid,
      m.parent_id AS parent_id,
      me.home_id AS home_id,
      ff.capability,
      me.id AS owner_id,
      me.id AS hub_id,
      m.status AS status,
      m.user_filename AS filename,
      m.filesize AS filesize,
      yp.vhost(me.id) AS vhost,
      m.extension AS ext,
      m.category AS ftype,
      m.category AS filetype,
      m.mimetype,
      m.upload_time AS ctime,
      m.publish_time AS mtime
    FROM ", _db_name, ".trash_media m
      INNER JOIN yp.entity me ON me.db_name=", QUOTE(_db_name),"
      LEFT JOIN yp.filecap ff ON m.extension=ff.extension
    WHERE m.status='deleted'
    ");

    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;       
    
    UPDATE _hubs SET is_checked = 1 WHERE _hub_id =hub_id;
    SELECT NULL,NULL,NULL INTO _hub_id ,_db_name , _home_dir;
    SELECT hub_id,db_name,home_dir  FROM _hubs WHERE is_checked = 0 LIMIT 1 INTO _hub_id ,_db_name , _home_dir;
  END WHILE;

  IF _offset < 0 THEN 
    SELECT * FROM _bin_media WHERE filename!='__trash__' ORDER BY ctime DESC;
  ELSE
    SELECT *, _page AS page FROM _bin_media WHERE filename!='__trash__' 
      ORDER BY ctime, filename DESC LIMIT _offset, _range;
  END IF;

  DROP TABLE IF EXISTS _bin_media;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_show_bin_next` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_show_bin_next`(
  IN _page TINYINT(4)
)
BEGIN

  DECLARE _hub_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _db_name VARCHAR(60) CHARACTER SET ascii;
  DECLARE _home_dir VARCHAR(300) CHARACTER SET ascii;
  DECLARE _home_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _range bigint;
  DECLARE _offset bigint;


  CALL pageToLimits(_page, _offset, _range);

  DROP TABLE IF EXISTS `_hubs`; 
  CREATE  TEMPORARY TABLE `_hubs` 
    (
      hub_id varchar(16)  CHARACTER SET ascii DEFAULT NULL,
      db_name varchar(60)  CHARACTER SET ascii DEFAULT NULL,
      home_dir varchar(300)  CHARACTER SET ascii DEFAULT NULL,
      is_checked int default 0      
    );

    DROP TABLE IF EXISTS _bin_media;
    CREATE TEMPORARY TABLE _bin_media  AS
     SELECT
        m.id  AS nid,
        m.parent_id AS pid,
        m.parent_id AS parent_id,
        _home_id AS home_id,
        ff.capability,
        me.id AS owner_id,
        me.id AS hub_id,
        m.status AS status,
        m.user_filename AS filename,
        m.filesize AS filesize,
        yp.vhost(me.id) AS vhost,
        m.extension AS ext,
        m.category AS ftype,
        m.category AS filetype,
        m.mimetype,
        m.upload_time AS mtime,
        m.publish_time AS ctime
      FROM  trash_media m
        INNER JOIN yp.entity me  ON me.db_name=database()
        LEFT JOIN yp.filecap ff ON m.extension=ff.extension
      WHERE m.status='deleted';




    INSERT INTO _hubs
    SELECT id hub, db_name,home_dir,0 FROM 
    yp.entity WHERE id IN(
    SELECT id FROM media m INNER JOIN permission p 
    ON p.resource_id = m.id AND p.permission>=15 AND m.status='active' );



    SELECT hub_id,db_name,home_dir  FROM _hubs WHERE is_checked = 0 LIMIT 1 INTO _hub_id ,_db_name , _home_dir;
    WHILE  _hub_id IS NOT NULL DO 



     SET @sql = CONCAT("
        INSERT INTO _bin_media 
        (
        nid, pid, parent_id, home_id, capability,
        owner_id, hub_id, status, filename, filesize,
        vhost, ext, ftype, filetype,
        mimetype, ctime, mtime
        )
        SELECT 
        m.id  AS nid,
        m.parent_id AS pid,
        m.parent_id AS parent_id,
        me.home_id AS home_id,
        ff.capability,
        me.id AS owner_id,
        me.id AS hub_id,
        m.status AS status,
        m.user_filename AS filename,
        m.filesize AS filesize,
        yp.vhost(me.id) AS vhost,
        m.extension AS ext,
        m.category AS ftype,
        m.category AS filetype,
        m.mimetype,
        m.upload_time AS ctime,
        m.publish_time AS mtime
      FROM ", _db_name, ".trash_media m
        INNER JOIN yp.entity me ON me.db_name=", QUOTE(_db_name),"
        LEFT JOIN yp.filecap ff ON m.extension=ff.extension
      WHERE m.status='deleted'
      ");

      PREPARE stmt FROM @sql;
      EXECUTE stmt;
      DEALLOCATE PREPARE stmt;       
     
      UPDATE _hubs SET is_checked = 1 WHERE _hub_id =hub_id;
      SELECT NULL,NULL,NULL INTO _hub_id ,_db_name , _home_dir;
      SELECT hub_id,db_name,home_dir  FROM _hubs WHERE is_checked = 0 LIMIT 1 INTO _hub_id ,_db_name , _home_dir;
    END WHILE;

  SELECT *, _page AS page FROM _bin_media WHERE filename!='__trash__' 
    ORDER BY ctime, filename DESC LIMIT _offset, _range;

  DROP TABLE IF EXISTS _bin_media;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_show_bin_tmp` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_show_bin_tmp`(
  IN _page TINYINT(4)
)
BEGIN

  DECLARE _range bigint;
  DECLARE _offset bigint;
  DECLARE _vhost VARCHAR(255);
  DECLARE _hub_id VARCHAR(16);
  DECLARE _area VARCHAR(50);
  DECLARE _home_dir VARCHAR(512);
  DECLARE _home_id VARCHAR(16);
  DECLARE _sb_db_name VARCHAR(255);  
  DECLARE _db_name VARCHAR(50);
  DECLARE _accessibility VARCHAR(16);
  DECLARE _finished       INTEGER DEFAULT 0;
  DECLARE _id          VARCHAR(16); 

  SELECT s.db_name FROM yp.entity e 
    INNER JOIN yp.share_box sb on sb.owner_id=e.id 
    INNER JOIN yp.entity s on s.id=sb.id  
  WHERE e.db_name = DATABASE() INTO _sb_db_name; 

  CALL pageToLimits(_page, _offset, _range);
  CALL mediaEnv(_vhost, _hub_id, _area, _home_dir, _home_id, _db_name, _accessibility);

  DROP TABLE IF EXISTS  _bin_media;  
      CREATE TEMPORARY TABLE `_bin_media` (
      `nid` varchar(16) DEFAULT NULL,
      `pid` varchar(16) NOT NULL DEFAULT '',
      `parent_id` varchar(16) NOT NULL DEFAULT '',
      `hub_id` varchar(16) DEFAULT NULL,
      `home_id` varchar(16) DEFAULT NULL,
      `oid` varchar(16) DEFAULT NULL,
      `caption` varchar(1024) DEFAULT NULL,
      `capability` varchar(8) DEFAULT '---',
      `accessibility` varchar(20),
      `status` varchar(20) DEFAULT NULL,
      `ext` varchar(100) NOT NULL DEFAULT '',
      `ftype` enum('hub', 'web' ,'folder','link','video','image','audio','document','stylesheet','script','vector','other') NOT NULL DEFAULT 'other',
      `filetype` enum('hub', 'web' ,'folder','link','video','image','audio','document','stylesheet','script','vector','other') NOT NULL DEFAULT 'other',
      `mimetype` varchar(100) NOT NULL,
      `view_count` mediumint(8) unsigned NOT NULL DEFAULT '0',
      `geometry` varchar(200) NOT NULL DEFAULT '0x0',
      `ctime` int(11) unsigned NOT NULL DEFAULT '0',
      `ptime` int(11) unsigned NOT NULL DEFAULT '0',
      `parent_path` varchar(1024) NOT NULL,
      `user_path` text NOT NULL,
      `filename` varchar(128) DEFAULT NULL,
      `filesize` double DEFAULT NULL,
      `firstname` char(200) DEFAULT NULL,
      `lastname` char(200) DEFAULT NULL,
      `remit` tinyint(4) DEFAULT '0',
      `vhost` varchar(512) DEFAULT NULL,
      `page` int(4) DEFAULT NULL,
      `area` varchar(100) DEFAULT NULL
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8;   


  INSERT INTO _bin_media
  SELECT
    media.id  AS nid,
    media.parent_id AS pid,
    media.parent_id AS parent_id,
    _hub_id AS holder_id,
    _home_id AS home_id,
    IF(media.category='hub', 
      (SELECT id FROM yp.entity WHERE entity.id=media.id), _hub_id
    ) AS oid,    
    media.caption,
    capability,
    IF(media.category='hub', (
      SELECT accessibility FROM yp.entity WHERE entity.id=media.id), _accessibility
    ) AS accessibility,
    media.status,
    
    
    
    media.extension AS ext,
    media.category AS ftype,
    media.category AS filetype,
    media.mimetype,
    media.download_count AS view_count,
     media.geometry,
    media.upload_time AS ctime,
    media.publish_time AS ptime,
     media.parent_path,
    IF(media.parent_path='' or media.parent_path is NULL , '/', media.parent_path) AS user_path,
    IF(media.category='hub', (
      SELECT `name` FROM yp.hub WHERE hub.id=media.id), media.user_filename
    ) AS filename,
    IF(media.category='hub', (
      SELECT space FROM yp.entity WHERE entity.id=media.id), media.filesize
    ) AS filesize,
    firstname,
    lastname,
    remit,
    IF(media.category='hub', (
      SELECT utils.vhost(ident) FROM yp.entity WHERE entity.id=media.id), _vhost
    ) AS vhost,    
   
    _page as page,
    IF(media.category='hub', media.extension, _area) AS area
  FROM  media media 
  LEFT JOIN (yp.filecap, yp.drumate) ON  media.extension=filecap.extension AND media.origin_id=yp.drumate.id 
  WHERE 
  parent_id NOT IN (SELECT id FROM media WHERE status='deleted')
  AND media.status='deleted';
 

  SET @sql = CONCAT("
    INSERT INTO _bin_media 
    (
    nid,pid,parent_id,user_path,parent_path,filename,
    status,ext,ftype,filetype,mimetype,
    ctime,ptime, hub_id, home_id,vhost
    )
    SELECT 
    m.id,parent_id,parent_id,IF(parent_path='' or parent_path is NULL , '/', parent_path),parent_path,user_filename,
    m.status,m.extension,m.category,m.category,mimetype,
    upload_time,publish_time,
    me.id,me.id, utils.vhost(me.ident)
    FROM " ,_sb_db_name ,".media m
    INNER JOIN yp.entity me  ON me.db_name=", QUOTE(_sb_db_name),"
    WHERE 
     parent_id NOT IN (SELECT id FROM " ,_sb_db_name , ".media WHERE status='deleted')
    AND m.status='deleted'");

  PREPARE stmt FROM @sql ;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;  


  BEGIN
    DECLARE dbcursor CURSOR FOR  SELECT db_name FROM  yp.entity WHERE id IN(SELECT id FROM media WHERE category = 'hub' AND status='active');
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET _finished = 1;
    OPEN dbcursor;
     
      STARTLOOP: LOOP
        FETCH dbcursor INTO _db_name ;
         IF _finished = 1 THEN 
            LEAVE STARTLOOP;
         END IF;    

            SET @sql = CONCAT("
            INSERT INTO _bin_media 
            (
            nid,pid,parent_id,user_path,parent_path,filename,
            status,ext,ftype,filetype,mimetype,
            ctime,ptime, hub_id, home_id,vhost
            )
            SELECT 
            m.id,parent_id,parent_id,IF(parent_path='' or parent_path is NULL , '/', parent_path),parent_path,user_filename,
            m.status,m.extension,m.category,m.category,mimetype,
            upload_time,publish_time,
            me.id,me.id, utils.vhost(me.ident)
            FROM " ,_db_name ,".media m
            INNER JOIN yp.entity me  ON me.db_name=", QUOTE(_db_name),"
            LEFT JOIN " ,_db_name ,".permission p on p.entity_id = ",QUOTE(_hub_id)," AND  p.resource_id = m.id
            WHERE 
            ( IFNULL(p.expiry_time,0) = 0 OR   IFNULL(p.expiry_time,0) > UNIX_TIMESTAMP() )
            AND parent_id NOT IN (SELECT id FROM " ,_db_name , ".media WHERE status='deleted')
            AND m.status='deleted'");

            

            PREPARE stmt FROM @sql ;
            EXECUTE stmt;
            DEALLOCATE PREPARE stmt;       
      END LOOP STARTLOOP;   

    CLOSE dbcursor;
  END;  


  SELECT * FROM _bin_media ORDER BY ctime, filename DESC LIMIT _offset, _range;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_show_branch` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_show_branch`(
  IN _nid VARCHAR(16)
)
BEGIN
  DECLARE _file_path TEXT DEFAULT NULL;
  DECLARE _db_name VARCHAR(80) DEFAULT NULL;
  DECLARE _home_dir VARCHAR(2000) DEFAULT NULL;
  DECLARE _eid VARCHAR(16) DEFAULT NULL;
  DECLARE _name VARCHAR(80) DEFAULT NULL;

  DROP TABLE IF EXISTS __tmp_tree;
  SELECT e.home_dir, e.id, COALESCE(h.name, d.fullname) FROM yp.entity e
    LEFT JOIN yp.hub h ON e.id = h.id AND e.type='hub'
    LEFT JOIN yp.drumate d ON e.id = d.id AND e.type='drumate'
    WHERE e.db_name=database() INTO _home_dir, _eid, _name;

  CREATE TEMPORARY TABLE __tmp_tree AS SELECT 
    id, 
    _home_dir AS home_dir, 
    _eid AS hub_id, 
    file_path, 
    parent_path, 
    parent_id AS pid, 
    status, 
    filesize,
    user_filename, 
    extension, 
    isalink,
    upload_time AS ctime,
    publish_time AS mtime,
    category
  FROM media where 1=2;
  INSERT INTO __tmp_tree
    WITH RECURSIVE __parent_tree AS
    (
      SELECT
        m.id, 
        _home_dir AS home_dir, 
        _eid AS hub_id,
        m.file_path,
        m.parent_path,
        m.parent_id,
        m.status, 
        m.filesize,
        m.user_filename, 
        m.extension, 
        m.isalink,
        m.upload_time AS ctime,
        m.publish_time AS mtime,
        m.category
      FROM
        media m
        WHERE m.id = _nid 
      UNION ALL
        SELECT
        m.id, 
        _home_dir AS home_dir, 
        _eid AS hub_id,
        m.file_path,
        m.parent_path,
        m.parent_id,
        m.status, 
        m.filesize,
        m.user_filename, 
        m.extension, 
        m.isalink,
        m.upload_time AS ctime,
        m.publish_time AS mtime,
        m.category
      FROM
        media AS m
      INNER JOIN __parent_tree AS t ON m.parent_id = t.id AND 
        t.category IN('folder', 'hub', 'root')
    )
    SELECT * FROM __parent_tree WHERE status IN('active', 'locked') ORDER BY category ASC;
  BEGIN
    DECLARE _finished INTEGER DEFAULT 0;
    DECLARE dbcursor CURSOR FOR SELECT e.id, e.home_dir, 
      REGEXP_REPLACE(file_path, CONCAT('\\\.', extension, '$'), ''),
      db_name FROM __tmp_tree m
      INNER JOIN (yp.entity e, permission p) ON m.id=e.id AND p.resource_id=m.id 
      WHERE m.category='hub' AND permission&2;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET _finished = 1; 
    OPEN dbcursor;
      STARTLOOP: LOOP
        FETCH dbcursor INTO _eid, _home_dir, _file_path, _db_name;
        IF _finished = 1 THEN 
          LEAVE STARTLOOP;
        END IF;    
        SET @s = CONCAT("INSERT INTO __tmp_tree SELECT id, ", 
          QUOTE(_home_dir),
          ",",
          QUOTE(_eid),
          ", clean_path(CONCAT(", 
          QUOTE(_file_path), 
          ", file_path)), 
          parent_path, 
          parent_id, 
          status, 
          filesize, 
          user_filename, 
          extension, 
          isalink,
          upload_time AS ctime,
          publish_time AS mtime,
          category FROM ", 
          _db_name, 
          ".media WHERE extension !='root' AND status IN('active', 'locked')");
        
        IF @s IS NOT NULL THEN 
          PREPARE stmt FROM @s;
          EXECUTE stmt;
          DEALLOCATE PREPARE stmt;
        END IF;
       END LOOP STARTLOOP;
    CLOSE dbcursor;
  END;

  SELECT 
    id, 
    TRIM(TRAILING '/' FROM home_dir) home_dir, 
    IF(category IN('hub', 'folder'),
      REGEXP_REPLACE(REGEXP_REPLACE(file_path, CONCAT('\\\.', extension, '$'), ''), '^/+', ''), 
      REGEXP_REPLACE(file_path, '^/+', '')
    ) AS file_path,
    hub_id,
    status, 
    filesize, 
    user_filename, 
    parent_path,
    pid,
    extension, 
    isalink,
    ctime,
    mtime,
    category
  FROM __tmp_tree WHERE isalink=0 AND NOT file_path REGEXP '/__trash__/';

  SELECT sum(filesize) AS size FROM __tmp_tree;
  SELECT IF(user_filename = '' OR user_filename IS NULL, _name, user_filename) AS filename 
    FROM media WHERE id=_nid;
  SELECT count(*) AS amount, sum(filesize) AS size, category 
    FROM __tmp_tree GROUP BY category;

  DROP TABLE IF EXISTS __tmp_tree;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_show_folders` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_show_folders`(
  IN _node_id VARCHAR(16),
  IN _uid VARCHAR(16),
  IN _sort_by VARCHAR(20),
  IN _order   VARCHAR(20),
  IN _page    TINYINT(4)
)
BEGIN
 
  DECLARE _range bigint;
  DECLARE _offset bigint;
  DECLARE _home_id VARCHAR(16);
  DECLARE _src_db_name VARCHAR(255);
  DECLARE _finished       INTEGER DEFAULT 0; 
  DECLARE _nid VARCHAR(16);  
  DECLARE _hub_db_name VARCHAR(255);
  DECLARE _ftype VARCHAR(255);

 

  CALL pageToLimits(_page, _offset, _range);  
  
  SELECT id  from media where parent_id='0' INTO _home_id;
  IF _node_id IS NULL OR _node_id='0' THEN 
    SELECT _home_id INTO _node_id;
  END IF;
    

  DROP TABLE IF EXISTS _show_node;
  CREATE TEMPORARY TABLE _show_node  AS  
  SELECT 
    m.id  AS nid,
    m.parent_id AS pid,
    m.parent_id AS parent_id,
    m.file_path as filepath,
    me.id  AS holder_id,    
    _home_id  AS home_id,   
    ff.capability,
    COALESCE(sbx.db_name, database()) src_db_name,
    he.db_name   hub_db_name,
    COALESCE(he.accessibility,me.accessibility) AS  accessibility,
    COALESCE(he.id,me.id) AS owner_id,
    COALESCE(he.id,me.id) AS hub_id,
    utils.vhost(COALESCE(sbx.ident,he.ident,me.ident)) AS vhost,
    COALESCE(he.status,m.status) AS status,
    COALESCE(hh.name,m.user_filename) AS filename,
    COALESCE(me.space,m.filesize) AS filesize,
    IF(m.category='hub', m.extension, me.area) AS area,
    m.caption,
    m.extension AS ext,
    m.category AS ftype,
    m.category AS filetype,
    m.mimetype,
    m.metadata,
    m.download_count AS view_count,
    m.geometry,
    m.upload_time AS ctime,
    m.publish_time AS ptime,
    d.firstname,
    d.lastname,
    _page as page,
    m.rank,
    CASE 
      WHEN m.file_path REGEXP "^/__Outbound__" THEN 'outbound' 
      WHEN m.file_path REGEXP "^/__Inbound__" THEN 'inbound' 
      ELSE 'nobound' 
    END shared
    
    
    
  FROM media m
    INNER JOIN yp.entity me  ON me.db_name=database()
    LEFT  JOIN yp.filecap ff ON m.extension=ff.extension
    LEFT  JOIN yp.drumate d ON  m.origin_id=d.id 

    LEFT  JOIN yp.entity he ON m.id = he.id AND m.category='hub'
    LEFT  JOIN yp.hub hh ON m.id = hh.id AND m.category='hub'

    LEFT JOIN yp.entity sbx on m.origin_id = sbx.id  AND parent_path(m.id) LIKE CONCAT('/__Inbound__/','%','/') 
  WHERE m.parent_id=_node_id AND m.status='active' AND (m.category='folder' OR m.category='hub');
  

  ALTER table _show_node ADD privilege  tinyint(4) unsigned ;
  ALTER table _show_node ADD  expiry_time int(11) ;
  ALTER table _show_node ADD  actual_home_id VARCHAR(16) ;

  BEGIN
    DECLARE dbcursor CURSOR FOR SELECT  nid, src_db_name ,ftype,hub_db_name FROM _show_node;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET _finished = 1; 
    OPEN dbcursor;
      STARTLOOP: LOOP
        FETCH dbcursor INTO _nid,_src_db_name ,_ftype,_hub_db_name;
        
          IF _finished = 1 THEN 
            LEAVE STARTLOOP;
          END IF;
        
          SET @perm = 0;
          SET @s = CONCAT("SELECT " ,_src_db_name,".user_permission (", QUOTE(_uid),",",QUOTE(_nid), ") INTO @perm");
          PREPARE stmt FROM @s;
          EXECUTE stmt;
          DEALLOCATE PREPARE stmt; 
          
          SET @resexpiry = null;    
          SET @s = CONCAT("SELECT " ,_src_db_name,".user_expiry (", QUOTE(_uid),",",QUOTE(_nid), ") INTO @resexpiry");
          PREPARE stmt FROM @s;
          EXECUTE stmt;
          DEALLOCATE PREPARE stmt;

          
          SELECT NULL INTO @actual_home_id ;
          IF _ftype = 'hub' AND _hub_db_name IS NOT NULL  THEN 
            SET @s = CONCAT("SELECT id from ", _hub_db_name ," .media where parent_id='0' INTO @actual_home_id");
            PREPARE stmt FROM @s;
            EXECUTE stmt;
            DEALLOCATE PREPARE stmt;
          END IF ;
                 
          UPDATE _show_node s SET privilege = @perm, expiry_time = @resexpiry, 
            actual_home_id = IFNULL(@actual_home_id , home_id)
          WHERE nid = _nid;

        END LOOP STARTLOOP; 
    CLOSE dbcursor;
  END; 
  
  SELECT 
    nid, 
    pid,
    parent_id, 
    holder_id,    
    home_id, 
    actual_home_id,
    capability,
    privilege,
    accessibility,
    owner_id,
    hub_id,
    vhost,
    status,
    filename,
    filesize,
    area,
    caption,
    ext,
    ftype,
    filetype,
    mimetype,
    metadata,
    view_count,
    geometry,
    ctime,
    ptime,
    firstname,
    lastname,
    page,
    rank,
    shared
    
  FROM 
    _show_node
  WHERE (expiry_time = 0 OR expiry_time > UNIX_TIMESTAMP())
  ORDER BY 
    CASE WHEN LCASE(_sort_by) = 'date' and LCASE(_order) = 'asc' THEN ctime END ASC,
    CASE WHEN LCASE(_sort_by) = 'date' and LCASE(_order) = 'desc' THEN ctime END DESC,
    CASE WHEN LCASE(_sort_by) = 'name' and LCASE(_order) = 'asc' THEN filename END ASC,
    CASE WHEN LCASE(_sort_by) = 'name' and LCASE(_order) = 'desc' THEN filename END DESC,
    CASE WHEN LCASE(_sort_by) = 'rank' and LCASE(_order) = 'asc' THEN rank END ASC,
    CASE WHEN LCASE(_sort_by) = 'rank' and LCASE(_order) = 'desc' THEN rank END DESC
      
    
  LIMIT _offset, _range;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_show_new` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_show_new`(
  IN _node_id VARCHAR(16) CHARACTER SET utf8,
  IN _uid VARCHAR(16),
  IN _page    TINYINT(4)
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  DECLARE _tempid VARCHAR(16);
  DECLARE _category VARCHAR(16);
  DECLARE _lvl INT;
  DECLARE _hub_db_name VARCHAR(255);
  DECLARE _hubs MEDIUMTEXT DEFAULT NULL;
  DECLARE _hub_id VARCHAR(16);
  DECLARE _type VARCHAR(255);
    CALL pageToLimits(_page, _offset, _range);
    SELECT type,id FROM yp.entity WHERE db_name = database() INTO  _type,_hub_id;
  
    DROP TABLE IF EXISTS __output_count; 
    CREATE TEMPORARY TABLE `__output_count` (
      seq  int NOT NULL AUTO_INCREMENT,
      id varchar(16),
      owner_id varchar(16) DEFAULT NULL, 
      hub_id varchar(16) DEFAULT NULL, 
      preview varchar(1000),
      category enum('media','chat') DEFAULT 'media',
      PRIMARY KEY `seq`(`seq`),
      UNIQUE KEY `id`(`hub_id`,`id`)
    );


    DROP TABLE IF EXISTS _show_node; 
    CREATE TEMPORARY TABLE _show_node (
     `seq`  int NOT NULL AUTO_INCREMENT,
     `id` varchar(16),
     `parent_id` varchar(16), 
     `category` varchar(16) ,
      PRIMARY KEY `seq`(`seq`) 
    );

    INSERT INTO _show_node 
    (id, parent_id ,category)
    WITH RECURSIVE mytree AS 
    ( 
      SELECT id, parent_id ,category
      FROM media WHERE id = _node_id 
        AND category IN('hub', 'folder')
        UNION ALL
      SELECT m.id,m.parent_id ,m.category
      FROM media AS m JOIN mytree AS t ON m.parent_id = t.id
        AND m.category IN('hub', 'folder')
    )SELECT id, parent_id ,category FROM mytree;
 
     
    SELECT MAX(seq) FROM _show_node  INTO _lvl; 
    SELECT id,category FROM _show_node WHERE seq = _lvl 
      INTO _tempid  ,_category;


    WHILE ( _lvl >= 1 AND  _tempid IS NOT NULL) DO
      IF (_category = 'hub') THEN
        SELECT db_name FROM yp.entity WHERE id = _tempid
        INTO _hub_db_name; 

 
        SET @s = CONCAT(
            "REPLACE INTO __output_count (id, owner_id, hub_id, preview, category) ",
            "SELECT message_id, author_id, ?, SUBSTRING(`message`, 1, 80), 'chat' FROM 
            ", _hub_db_name,".channel where sys_id >(SELECT 
            IFNULL((SELECT ref_sys_id FROM ", _hub_db_name,".read_channel 
            WHERE uid = ?),0))"
          );
        PREPARE stmt FROM @s;
        EXECUTE stmt USING _hub_id,  _uid;
        DEALLOCATE PREPARE stmt;

        SET @s = CONCAT(
            "REPLACE INTO __output_count (id, owner_id, hub_id, preview) ",
            "SELECT id, owner_id, ?, file_path FROM ", _hub_db_name ,
            ".media WHERE file_path not REGEXP '^/__(chat|trash)__' AND ",
            "is_new(metadata, owner_id, ?)"
         );
        PREPARE stmt FROM @s;
        EXECUTE stmt USING _tempid,_uid;
        DEALLOCATE PREPARE stmt;
      END IF;
      SELECT _lvl - 1  INTO _lvl; 
      SELECT NULL, NULL INTO _tempid,_category;
      SELECT id,category FROM _show_node WHERE seq = _lvl 
      INTO _tempid,_category;
    END WHILE;
 
    REPLACE INTO __output_count (id, owner_id, hub_id, preview)
    SELECT  m.id, m.owner_id, _hub_id, file_path FROM _show_node 
    INNER JOIN media m USING(id)  
    WHERE JSON_EXISTS(m.metadata, '$._seen_') AND 
    NOT JSON_EXISTS(metadata, CONCAT('$._seen_.', _uid));

  IF _type='hub' AND _category IN('hub', 'folder') THEN 
    REPLACE INTO __output_count (id, owner_id, hub_id, preview, category) 
    SELECT message_id, author_id, _hub_id, SUBSTRING(`message`, 1, 80), 'chat' FROM 
    channel where sys_id >(SELECT 
    IFNULL((SELECT ref_sys_id FROM read_channel WHERE uid = _uid),0));
  END IF;


  DROP TABLE IF EXISTS __output; 
  CREATE TEMPORARY TABLE __output  AS 
  SELECT o.category, COUNT(DISTINCT o.id) new_media, 0 new_message,
    IF(firstname IS NULL AND lastname IS NULL, email, 
      CONCAT(IFNULL(firstname, ''), ' ', IFNULL(lastname, ''))
    ) fullname, 
    IFNULL(firstname, '') firstname,
    IFNULL(lastname, '') lastname,
    hh.name hubname,
    GROUP_CONCAT(
      JSON_OBJECT(
        "hub_id", o.hub_id, 
        "nid", o.id,
        "type", o.category,
        "preview", o.preview
    )) nodes,
    ',{}' messages,
    o.owner_id `uid` 
    FROM __output_count o 
    INNER JOIN yp.drumate d ON o.owner_id = d.id 
    LEFT JOIN yp.hub hh ON o.hub_id = hh.id 
    WHERE o.owner_id != _uid AND o.category ='media' GROUP BY(d.id)
    
    
  UNION
  SELECT o.category, COUNT(DISTINCT o.id) new_media, 0 new_message,
    d.email fullname, 
    IFNULL(d.email, '') firstname,
    IFNULL(d.email, '') lastname,
    hh.name hubname,
    GROUP_CONCAT(
      JSON_OBJECT(
        "hub_id", o.hub_id, 
        "nid", o.id,
        "type", o.category,
        "preview", o.preview
    )) nodes,
    ',{}' messages,
    o.owner_id `uid` 
    FROM __output_count o 
    INNER JOIN yp.dmz_user d ON o.owner_id = d.id 
    LEFT JOIN yp.hub hh ON o.hub_id = hh.id 
    WHERE o.owner_id != _uid AND o.category ='media' GROUP BY(d.id)
  UNION
  SELECT o.category, 0 new_media, COUNT(DISTINCT o.id) new_message, 
    IF(firstname IS NULL AND lastname IS NULL, email, 
      CONCAT(IFNULL(firstname, ''), ' ', IFNULL(lastname, ''))
    ) fullname, 
    IFNULL(firstname, '') firstname,
    IFNULL(lastname, '') lastname,
    hh.name hubname,
    '{},' nodes,
    GROUP_CONCAT(
      JSON_OBJECT(
        "hub_id", o.hub_id, 
        "nid", o.id,
        "type", o.category,
        "preview", o.preview
    )) messages,
    o.owner_id `uid` 
    FROM __output_count o INNER JOIN yp.drumate d ON o.owner_id = d.id 
    LEFT JOIN yp.hub hh ON o.hub_id = hh.id 
    WHERE o.owner_id != _uid AND o.category ='chat' 
    GROUP BY(d.id);
  
  SELECT GROUP_CONCAT(
      nodes, 
      messages
      SEPARATOR '+++'
    ) notifications, 
    SUM(new_message) new_message, 
    SUM(new_media) new_media,
    SUM(new_message) new_chat, 
    SUM(new_media) new_file,
    `uid`,
    hubname,
    fullname,
    firstname,
    lastname
  FROM __output GROUP BY(uid);
 
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_show_nodes` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_show_nodes`(
  IN _nodes MEDIUMTEXT,
  IN _uid VARCHAR(16) 
)
BEGIN
  DECLARE _i INTEGER DEFAULT 0;
  DECLARE _pattern VARCHAR(1024);
  DECLARE _nid VARCHAR(16);

  DROP TABLE IF EXISTS __tmp_recursive;
  CREATE TEMPORARY TABLE __tmp_recursive(
    `nid` varchar(16) DEFAULT NULL,
    `parent_path` varchar(1024) DEFAULT NULL,
    `filename` varchar(128) DEFAULT NULL,
    `extension` varchar(128),
    `permission` tinyint(4) unsigned,
    `ttl` int(11),
    `category` enum('hub', 'web' ,'folder','link','video','image','audio','document','stylesheet','script','vector','other'),
    UNIQUE nid (nid)
  ); 
  WHILE _i < JSON_LENGTH(_nodes) DO 
    SELECT JSON_UNQUOTE(JSON_EXTRACT(_nodes, CONCAT("$[", _i, "]"))) INTO _nid;
    SELECT replace(clean_path(file_path), concat('.', extension), '/%') 
      FROM media where id=_nid
    INTO _pattern;
    REPLACE INTO __tmp_recursive SELECT 
      m.id, 
      parent_path(m.id) AS parent_path,
      
      m.user_filename, 
      m.extension, 
      user_permission(_uid, m.id),
      media_ttl(_uid, m.id),
      m.category
    FROM media m WHERE file_path LIKE _pattern OR id=_nid;
    SELECT _i + 1 INTO _i;
  END WHILE;
  SELECT * FROM __tmp_recursive;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_show_node_by` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_show_node_by`(
  IN _node_id VARCHAR(16) CHARACTER SET ascii,
  IN _uid VARCHAR(16) CHARACTER SET ascii,
  IN _sort_by VARCHAR(20),
  IN _order   VARCHAR(20),
  IN _page    TINYINT(4)
)
BEGIN
 
  DECLARE _range bigint;
  DECLARE _offset bigint;
  DECLARE _home_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _src_db_name VARCHAR(255);
  DECLARE _finished       INTEGER DEFAULT 0; 
  DECLARE _nid VARCHAR(16) CHARACTER SET ascii;  
  DECLARE _parent_id VARCHAR(16) CHARACTER SET ascii;  
  DECLARE _hub_db_name VARCHAR(255);
  DECLARE _ftype VARCHAR(255);

  DECLARE _sys_id INT;
  DECLARE _temp_sys_id INT;
  DECLARE _db VARCHAR(400);


  DECLARE _tempid VARCHAR(16) CHARACTER SET ascii;
  DECLARE _category VARCHAR(16);
  DECLARE _area VARCHAR(30);
  DECLARE _hub_area VARCHAR(30);
  DECLARE _flag_expiry VARCHAR(30);
  DECLARE _lvl INT;
  DECLARE _hubs MEDIUMTEXT DEFAULT NULL;
  DECLARE _hub_id VARCHAR(16);
  DECLARE _username VARCHAR(100);
  DECLARE _org VARCHAR(500);
  DECLARE _ts INT(11);
  DECLARE _expiry_time INT(11);
  DECLARE _root_hub_id VARCHAR(16) CHARACTER SET ascii ;
  DECLARE _hub_name VARCHAR(5000) ;
  DECLARE _user_db_name VARCHAR(255);

  SELECT UNIX_TIMESTAMP() INTO _ts;

  CALL pageToLimits(_page, _offset, _range);  
  SELECT database() INTO _src_db_name;
  SELECT id  from media where parent_id='0' INTO _home_id;

  SELECT  h.id, e.area 
    FROM yp.hub h INNER JOIN yp.entity e on e.id = h.id 
    WHERE db_name=_src_db_name INTO _root_hub_id, _hub_area;
  SELECT '' INTO _hub_name;

  IF _root_hub_id IS NOT NULL THEN
    SELECT db_name FROM yp.entity WHERE id = _uid INTO _user_db_name;
    SELECT '' INTO @hub_name;
    IF _user_db_name IS NOT NULL THEN 
      SET @s = CONCAT("
          SELECT user_filename,parent_path
          FROM  ",_user_db_name,".media m 
          WHERE m.id='",_root_hub_id,"' INTO @hub_name , @parent_path"
        );
      PREPARE stmt FROM @s;
      EXECUTE stmt ;
      DEALLOCATE PREPARE stmt;
      SELECT CONCAT(@parent_path,'/',@hub_name) INTO _hub_name  WHERE @hub_name  <>  '';
    END IF;
  END IF;

  SELECT yp.get_sysconf('guest_id') INTO @guest_id;

  IF _node_id IS NULL OR _node_id='0' THEN 
    SELECT _home_id INTO _node_id;
  END IF;
  
  IF _node_id REGEXP "^/.+" THEN 
    SELECT id FROM media WHERE file_path = clean_path(_node_id) INTO _node_id;
  END IF;

  DROP TABLE IF EXISTS _temp_show_node;
  CREATE TEMPORARY TABLE _temp_show_node  AS  
  SELECT 
    m.id AS nid,
    m.parent_id AS pid,
    m.parent_id AS parent_id,
    CONCAT(_hub_name, m.file_path) as filepath,
    IF(m.category = 'hub', '/', m.file_path) AS ownpath,
    me.id  AS holder_id,    
    _home_id  AS home_id,   
    null capability,
    _src_db_name AS src_db_name,
    he.db_name hub_db_name,
    hh.name hubname,
    COALESCE(he.accessibility,me.accessibility) AS  accessibility,
    COALESCE(he.id, hh.owner_id) AS owner_id,
    COALESCE(he.id, me.id) AS hub_id,
    COALESCE(he.status, m.status) AS status,
    m.user_filename AS filename,
    m.filesize AS filesize,
    COALESCE(vv.fqdn, v.fqdn) AS vhost,
    he.area AS area,
    m.caption,
    m.extension AS ext,
    m.category AS ftype,
    m.mimetype mimetype,
    m.metadata,
    m.download_count AS view_count,
    m.geometry,
    m.upload_time AS ctime,
    m.publish_time AS mtime,
    is_new(m.metadata, COALESCE(he.id, hh.owner_id) , _uid)  new_file,
    isalink,
     _page as page,
     m.rank,
    IF(m.category = 'hub' , null, user_permission(_uid, m.id )) privilege,
    IF(m.category = 'hub' , null, user_expiry(_uid, m.id )) expiry_time
  FROM media m
    INNER JOIN yp.entity me  ON me.db_name=database()
    LEFT JOIN yp.vhost v ON  v.id=me.id
    LEFT JOIN yp.vhost vv ON  vv.id=m.id
    LEFT JOIN yp.entity he ON m.id = he.id AND m.category='hub'
    LEFT JOIN yp.hub hh ON m.id = hh.id AND m.category='hub'
  WHERE m.parent_id=_node_id AND 
    m.file_path not REGEXP '^/__(chat|trash|upload)__' AND 
    m.`status` NOT IN ('hidden', 'deleted') ;

  ALTER TABLE _temp_show_node ADD sys_id INT PRIMARY KEY AUTO_INCREMENT;
  ALTER TABLE _temp_show_node ADD flag_expiry VARCHAR(30) DEFAULT 'na';
  ALTER TABLE _temp_show_node modify  new_file int DEFAULT 0;

  SELECT sys_id, IF(ftype = 'hub', hub_db_name, null), IF(ftype = 'hub', nid, null) , area
    FROM _temp_show_node WHERE sys_id > 0  AND  (hub_db_name is not null) ORDER BY sys_id ASC LIMIT 1 
    INTO _sys_id , _db, _nid,_area;


  WHILE _sys_id <> 0 DO

    SET @perm = 0;
    SET @resexpiry = NULL;
    SET @s = CONCAT("SELECT ",
      _db,".user_permission (?, ?) INTO @perm"
    );
    PREPARE stmt FROM @s;
    EXECUTE stmt USING _uid, _nid;
    DEALLOCATE PREPARE stmt; 

    
    SET @resexpiry = null;    
    SET @s = CONCAT("SELECT ",
      _db,".user_expiry (?, ?) INTO @resexpiry"
    );
    PREPARE stmt FROM @s;
    EXECUTE stmt USING _uid, _nid;
    DEALLOCATE PREPARE stmt;

   SELECT 'na' INTO _flag_expiry ;

    IF _area = 'share' THEN
        SET @expiry_time = NULL;
        SET @s = CONCAT("
          SELECT p.expiry_time
          FROM  ",_db,".permission p 
          INNER JOIN yp.dmz_token t ON p.entity_id = t.guest_id
          INNER JOIN yp.dmz_user u ON p.entity_id = u.id
          INNER JOIN yp.entity e ON e.id=  t.hub_id AND  e.home_id = t.node_id
          WHERE e.db_name='",_db,"' AND  u.id = @guest_id  INTO @expiry_time"
        );
        PREPARE stmt FROM @s;
        EXECUTE stmt ;
        DEALLOCATE PREPARE stmt;
        SELECT 
          CASE 
            WHEN IFNULL(@expiry_time,0) = 0 THEN  'infinity' 
            WHEN (@expiry_time - _ts) <= 0  THEN 'expired'
            ELSE 'active'
        END INTO  _flag_expiry; 
      
    END IF;

    
    UPDATE _temp_show_node s SET privilege = @perm, expiry_time = @resexpiry ,flag_expiry =_flag_expiry 
      WHERE sys_id = _sys_id;
    SELECT _sys_id INTO  _temp_sys_id ;  
    SELECT 0 , NULL,NULL INTO  _sys_id, _db , _area; 

    SELECT IFNULL(sys_id,0), IF(ftype = 'hub', hub_db_name, src_db_name), nid ,area
    FROM _temp_show_node WHERE sys_id >_temp_sys_id AND ftype = 'hub' AND hub_db_name IS NOT NULL ORDER BY sys_id ASC LIMIT 1 
    INTO _sys_id, _db, _nid,_area;

  END WHILE;


  DROP TABLE IF EXISTS _show_node;
  CREATE TEMPORARY TABLE _show_node  AS 
    SELECT * FROM _temp_show_node WHERE 
      (expiry_time = 0 OR expiry_time > UNIX_TIMESTAMP()) AND 
      privilege > 0 ORDER BY 
      CASE WHEN LCASE(_sort_by) = 'date' and LCASE(_order) = 'asc' THEN ctime END ASC,
      CASE WHEN LCASE(_sort_by) = 'date' and LCASE(_order) = 'desc' THEN ctime END DESC,
      CASE WHEN LCASE(_sort_by) = 'name' and LCASE(_order) = 'asc' THEN filename END ASC,
      CASE WHEN LCASE(_sort_by) = 'name' and LCASE(_order) = 'desc' THEN filename END DESC,
      CASE WHEN LCASE(_sort_by) = 'rank' and LCASE(_order) = 'asc' THEN rank END ASC,
      CASE WHEN LCASE(_sort_by) = 'rank' and LCASE(_order) = 'desc' THEN rank END DESC,
      CASE WHEN LCASE(_sort_by) = 'size' and LCASE(_order) = 'asc' THEN filesize END ASC,
      CASE WHEN LCASE(_sort_by) = 'size' and LCASE(_order) = 'desc' THEN filesize END DESC
    LIMIT _offset ,_range;

  ALTER table _show_node ADD hubs MEDIUMTEXT ;
  ALTER table _show_node ADD nodes MEDIUMTEXT ;
  ALTER table _show_node ADD actual_home_id VARCHAR(16) ;

  DROP TABLE IF EXISTS _node_tree; 
  CREATE TEMPORARY TABLE _node_tree (
    `seq`  int NOT NULL AUTO_INCREMENT,
    `heritage_id` varchar(16) CHARACTER SET ascii,
    `id` varchar(16) CHARACTER SET ascii,
    `parent_id` varchar(16) CHARACTER SET ascii, 
    `category` varchar(16) ,
    `new_file` int default 0, 
    PRIMARY KEY `seq`(`seq`)
  );

  INSERT INTO _node_tree 
  (heritage_id, id, parent_id ,category)
  WITH RECURSIVE mytree AS 
  ( 
    SELECT id heritage_id , id, parent_id ,category
    FROM media WHERE id IN  (
      SELECT nid from _show_node WHERE category in ('folder','hub' ) 
    ) AND   category in ('folder','hub' )
    UNION ALL
    SELECT t.heritage_id,m.id,m.parent_id ,m.category
    FROM media AS m JOIN mytree AS t ON m.parent_id = t.id AND
      t.category IN ('folder','hub' ) 
  ) SELECT heritage_id, id, parent_id ,category  FROM mytree;


  SELECT MAX(seq) FROM _node_tree  INTO _lvl; 
  SELECT id,category FROM _node_tree WHERE seq = _lvl 
  INTO _tempid  ,_category;

  WHILE ( _lvl >= 1 AND  _tempid IS NOT NULL) DO
    IF (_category = 'hub') THEN
      SET @_temp_read_cnt = 0; 
      SELECT db_name, home_id FROM yp.entity WHERE id = _tempid INTO _hub_db_name, @actual_home_id; 
      IF (_hub_db_name IS NOT NULL) THEN 
        SET @s = CONCAT(
          "SELECT IFNULL(SUM(is_new(metadata, owner_id, ?)), 0) FROM ", _hub_db_name ,
          ".media WHERE file_path not REGEXP '^/__(chat|trash)__' AND category != 'root' INTO @_temp_file_count"
        );
        PREPARE stmt FROM @s;
        EXECUTE stmt USING _uid;
        DEALLOCATE PREPARE stmt;
        UPDATE  _node_tree   SET new_file = @_temp_file_count WHERE id = _tempid;
        
        
        
        
        
        
        
        UPDATE _show_node SET actual_home_id=@actual_home_id WHERE nid = _tempid;

      END IF;
    END IF;
    SELECT _lvl - 1  INTO _lvl; 
    SELECT NULL, NULL INTO _tempid,_category;
    SELECT id,category FROM _node_tree WHERE seq = _lvl 
    INTO _tempid,_category;
  END WHILE;

  UPDATE  _node_tree t 
  INNER JOIN media m USING(id) 
  SET t.new_file=is_new(m.metadata, owner_id, _uid)
  WHERE t.category <>  'hub'  AND t.category != 'root';

  UPDATE _show_node t 
  INNER JOIN ( SELECT  heritage_id , 
    SUM(new_file) new_file ,
    GROUP_CONCAT( CASE WHEN id <> heritage_id THEN  id  ELSE NULL END ) nodes,
    GROUP_CONCAT(CASE WHEN category = 'hub' AND id <> heritage_id THEN  id  ELSE NULL END ) hubs
  FROM _node_tree GROUP by heritage_id ) h ON nid = heritage_id

  SET t.new_file =h.new_file, t.nodes = h.nodes,t.hubs = h.hubs;

  SELECT
    nid,
    pid,
    parent_id,
    REGEXP_REPLACE(filepath, '/+', '/') filepath, 
    REGEXP_REPLACE(ownpath, '/+', '/') ownpath,
    holder_id,
    home_id,
    fc.capability capability,
    src_db_name,
    hub_db_name,
    hubname,
    accessibility,
    owner_id,
    status,
    filename,
    hub_id,
    IFNULL(area, _hub_area) area,
    filesize,
    vhost,
    isalink,
    caption,
    ext,
    metadata,
    view_count,
    geometry,
    ctime,
    mtime,
    COALESCE(fc.category, m.ftype) ftype,
    COALESCE(fc.category, m.ftype) filetype,
    COALESCE(fc.mimetype, m.mimetype) mimetype,
    JSON_VALUE(metadata, "$.md5Hash") AS md5Hash,
    new_file,
    page,
    rank,
    privilege,
    expiry_time,
    m.sys_id sys_id,
    hubs,
    nodes,
    IFNULL(actual_home_id, _home_id) actual_home_id,
    flag_expiry dmz_expiry
  FROM _show_node m 
    LEFT JOIN yp.filecap fc ON m.ext=fc.extension
  
  ORDER BY 
    CASE WHEN LCASE(_sort_by) = 'date' and LCASE(_order) = 'asc' THEN ctime END ASC,
    CASE WHEN LCASE(_sort_by) = 'date' and LCASE(_order) = 'desc' THEN ctime END DESC,
    CASE WHEN LCASE(_sort_by) = 'name' and LCASE(_order) = 'asc' THEN filename END ASC,
    CASE WHEN LCASE(_sort_by) = 'name' and LCASE(_order) = 'desc' THEN filename END DESC,
    CASE WHEN LCASE(_sort_by) = 'rank' and LCASE(_order) = 'asc' THEN rank END ASC,
    CASE WHEN LCASE(_sort_by) = 'rank' and LCASE(_order) = 'desc' THEN rank END DESC,
    CASE WHEN LCASE(_sort_by) = 'size' and LCASE(_order) = 'asc' THEN filesize END ASC,
    CASE WHEN LCASE(_sort_by) = 'size' and LCASE(_order) = 'desc' THEN filesize END DESC;

  DROP TABLE IF EXISTS _temp_show_node;
  DROP TABLE IF EXISTS _show_node;
  DROP TABLE IF EXISTS _node_tree;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_ticket_init` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_ticket_init`()
BEGIN

 SELECT node_id_from_path('/__ticket__') INTO @temp_chat_id;
 IF @temp_chat_id IS NULL THEN 
    call mfs_make_dir("0", JSON_ARRAY('__ticket__'), 0);
    UPDATE media SET status='hidden' where file_path='/__ticket__.folder';
 END IF;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_trash` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_trash`(
  IN _id VARCHAR(16)
)
BEGIN
  DECLARE _node_path VARCHAR(255);
  DECLARE _category VARCHAR(40);
  DECLARE _uid VARCHAR(16);
  DECLARE _owner_id VARCHAR(16);
  DECLARE _hub_id VARCHAR(16);
  DECLARE _hub_db VARCHAR(40);
  
  SELECT category from media WHERE id=_id into _category;
  
  IF _category='folder' THEN
    SELECT CONCAT(parent_path(id),user_filename) from media WHERE id=_id into _node_path;
    UPDATE media SET status='deleted' WHERE CONCAT(parent_path(id),user_filename ) LIKE concat(_node_path, '/%');
  END IF;
  UPDATE media SET status='deleted' WHERE id=_id;
  
  IF _category='hub' THEN
    
    SELECT id FROM yp.entity WHERE db_name = database() INTO _uid;
    SELECT owner_id FROM yp.hub WHERE id = _id INTO _owner_id;
    SELECT db_name FROM yp.entity WHERE id = _id INTO _hub_db;
   
    IF _uid = _owner_id THEN
      
      SET @sql = CONCAT(
        "CALL  ", _hub_db, ".remove_all_members (", quote(_owner_id), ");"
      );
        
      PREPARE stmt1 FROM @sql;
      EXECUTE stmt1;
      DEALLOCATE PREPARE stmt1;
    END IF;
 
    
  END IF;

  CALL mfs_node_attr(_id);

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_trash_child_hub` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_trash_child_hub`(
  IN _nid VARCHAR(16),
  IN _uid VARCHAR(16),
  OUT _output VARCHAR(1000)
)
BEGIN
  DECLARE _tempid VARCHAR(16);

  DECLARE _owner_id VARCHAR(16);
  DECLARE _node_hub_db VARCHAR(40);
  DECLARE _user_hub_db VARCHAR(40);
  DECLARE _cum_output MEDIUMTEXT;
  DROP TABLE IF EXISTS _myhub; 
  CREATE TEMPORARY TABLE `_myhub` (
      id varchar(16) DEFAULT NULL,
    is_checked boolean default 0
  );              

  INSERT INTO _myhub (id ,is_checked ) 
  WITH RECURSIVE myhub AS (
  SELECT id, category  , _nid nid FROM media WHERE id = _nid
  UNION ALL
  SELECT m.id,m.category, t.nid 
  FROM media AS m JOIN myhub AS t ON m.parent_id =t.id
  )
  SELECT id,0 FROM myhub WHERE  category ='hub';

  SELECT `db_name` FROM yp.entity WHERE id = _uid INTO _user_hub_db;                

  SELECT  id FROM _myhub where is_checked =0 LIMIT 1 INTO _tempid ;

  
  WHILE (_tempid IS NOT NULL) do
    SELECT owner_id FROM yp.hub WHERE id = _tempid INTO _owner_id;
    SELECT `db_name` FROM yp.entity WHERE id = _tempid INTO _node_hub_db;

    IF _uid = _owner_id THEN
      SET @sql = CONCAT(
        "CALL  ", _node_hub_db, ".remove_all_members (", quote(_owner_id), ")" );
      PREPARE hub_stmt FROM @sql;
      EXECUTE hub_stmt;
      DEALLOCATE PREPARE hub_stmt;
    ELSE 

      SET @sql = CONCAT(
        "CALL  ", _user_hub_db, ".leave_hub (", quote(_tempid), ")" );
      PREPARE hub_stmt FROM @sql;
      EXECUTE hub_stmt;
      DEALLOCATE PREPARE hub_stmt;

      SET @sql = CONCAT("CALL  " , _node_hub_db ,".hub_add_action_log (?,?,?,?,?,?)");
      PREPARE hub_stmt FROM @sql;
      EXECUTE hub_stmt USING _tempid,'left','member','admin',null,'has been left';
      DEALLOCATE PREPARE hub_stmt;



      SELECT NULL  INTO @huboutput;
      SET @sql = CONCAT(
        " SELECT user_filename FROM ", _user_hub_db, ".media where id= ", quote(_tempid), "INTO @child_hub" );
      PREPARE hub_stmt FROM @sql;
      EXECUTE hub_stmt;
      DEALLOCATE PREPARE hub_stmt;

      SELECT 
        CASE 
        WHEN _cum_output IS NOT NULL  AND @child_hub IS NOT NULL     THEN CONCAT (_cum_output ,',',@child_hub )
        WHEN _cum_output IS NULL      AND @child_hub IS NOT NULL     THEN @child_hub 
        WHEN _cum_output IS NOT NULL  AND @child_hub IS NULL         THEN _cum_output
        WHEN _cum_output IS NULL      AND @child_hub IS NULL         THEN NULL
        END
      INTO _cum_output;

    END IF;
    UPDATE _myhub SET is_checked = 1 WHERE id = _tempid ;
    SELECT NULL INTO _tempid ;
    SELECT id FROM _myhub WHERE is_checked =0 LIMIT 1 INTO _tempid ;

  END WHILE;

  SELECT _cum_output  INTO _output;

  DROP TABLE IF EXISTS _myhub;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_trash_cross_node` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_trash_cross_node`(
  IN _nid VARCHAR(16),
  IN _uid VARCHAR(16),
  IN _modify_perm TINYINT(4),
  OUT _output VARCHAR(1000)
)
BEGIN
  DECLARE _actual_perm TINYINT(4);
  DECLARE _ts INT(11) DEFAULT 0;
  

  

  



  
    
  
  
  
  
    
  
  
  
  
  
  
     CALL mfs_trash_node (_nid);


     SET @st = CONCAT("SELECT  
      user_filename,category, extension 
      FROM  media WHERE id = ?
      INTO  @hub_file_name,@hub_category,@hub_extension" ) ; 
      PREPARE stmt3 FROM @st;
      EXECUTE stmt3 using _nid;
      DEALLOCATE PREPARE stmt3;  


      SET @st = CONCAT("CALL  hub_add_action_log (?,?,?,?,?,?)");
      PREPARE stamt FROM @st;
      EXECUTE stamt USING _uid,'deleted','media','all',null,CONCAT('The ',@hub_file_name, ' ',@hub_category,' has been deleted');
      DEALLOCATE PREPARE stamt;


    
  


END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_trash_hub` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_trash_hub`(
  IN _nid VARCHAR(16),
  IN _uid VARCHAR(16),
  OUT _output VARCHAR(1000)
)
BEGIN

  DECLARE _owner_id VARCHAR(16);
  DECLARE _node_hub_db VARCHAR(40);
  DECLARE _user_hub_db VARCHAR(40);

  
  SELECT owner_id FROM yp.hub WHERE id = _nid INTO _owner_id;
  SELECT `db_name` FROM yp.entity WHERE id = _nid INTO _node_hub_db;
  SELECT `db_name` FROM yp.entity WHERE id = _uid INTO _user_hub_db;
  
  IF _uid = _owner_id THEN
    SET @sql = CONCAT(
      "CALL  ", _node_hub_db, ".remove_all_members (", quote(_owner_id), ")" );
    PREPARE hub_stmt FROM @sql;
    EXECUTE hub_stmt;
    DEALLOCATE PREPARE hub_stmt;

    SET @sql = CONCAT(
      "CALL  ", _user_hub_db, ".mfs_trash_node (", quote(_nid), ")" );
    PREPARE hub_stmt FROM @sql;
    EXECUTE hub_stmt;
    DEALLOCATE PREPARE hub_stmt;
  ELSE 
    
    SET @sql = CONCAT(
      "CALL  ", _user_hub_db, ".leave_hub (", quote(_nid), ")" );
    PREPARE hub_stmt FROM @sql;
    EXECUTE hub_stmt;
    DEALLOCATE PREPARE hub_stmt;
    
    SET @sql = CONCAT("CALL  " , _node_hub_db ,".hub_add_action_log (?,?,?,?,?,?)");
    PREPARE hub_stmt FROM @sql;
    EXECUTE hub_stmt USING _nid,'left','member','admin',null,'has been left';
    DEALLOCATE PREPARE hub_stmt;

    SELECT NULL  INTO @huboutput;
    SET @sql = CONCAT(
      " SELECT user_filename FROM ", _user_hub_db, ".media where id= ", quote(_nid), "INTO @huboutput" );
    PREPARE hub_stmt FROM @sql;
    EXECUTE hub_stmt;
    DEALLOCATE PREPARE hub_stmt;
    

    SELECT @huboutput  INTO _output;
  END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_trash_init` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_trash_init`(
)
BEGIN
  DECLARE _file_path VARCHAR(400) DEFAULT NULL;
  DECLARE _home_id VARCHAR(400) DEFAULT NULL;
  SELECT id FROM media WHERE parent_id='0' INTO _home_id;
  UPDATE media SET file_path='/', category='root' WHERE id=_home_id;
  
  SELECT file_path from media WHERE file_path='/__trash__' INTO _file_path;
  IF _file_path IS NULL THEN 
    CALL mfs_make_dir(_home_id, JSON_ARRAY('__trash__'), 1);
    UPDATE media SET status='hidden' WHERE file_path='/__trash__';
  END IF;
  
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_trash_sb` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_trash_sb`(
  IN _rid VARCHAR(16),
  IN _oid VARCHAR(16),
  OUT _output VARCHAR(1000)
)
BEGIN
  DECLARE _bound VARCHAR(16);
  DECLARE _finished INTEGER DEFAULT 0;
  DECLARE _db_name VARCHAR(50);
  DECLARE _uid     VARCHAR(16);
  DECLARE _status VARCHAR(50);
  SELECT "" INTO  _status;
  SELECT status FROM media WHERE id =  _rid INTO _status ;  
  SELECT '__Outbound__' FROM media WHERE id=_rid AND parent_path(id) LIKE CONCAT("/__Outbound__","%")  INTO _bound;  
    
  IF _bound IS NOT NULL THEN 
    BEGIN
      DECLARE dbcursor CURSOR FOR  SELECT DISTINCT b.db_name , p.entity_id as uid
      FROM 
      media m
      INNER JOIN permission p ON  p.resource_id=m.id 
      INNER JOIN yp.entity b on b.area='restricted'
      INNER join yp.hub e on e.id = b.id AND e.owner_id = p.entity_id 
      INNER JOIN media ch ON
        CASE WHEN m.category = 'folder' 
            THEN  REPLACE(CONCAT(parent_path(ch.id),ch.user_filename,'/'), '(',')')  regexp REPLACE(CONCAT(parent_path(m.id),m.user_filename,'/'), '(',')') 
            ELSE m.id=ch.id
          END = 1 
      WHERE ch.id = _rid ;
      DECLARE CONTINUE HANDLER FOR NOT FOUND SET _finished = 1;
      OPEN dbcursor;
        STARTLOOP: LOOP
          FETCH dbcursor INTO _db_name,_uid ;
          IF _finished = 1 THEN 
            LEAVE STARTLOOP;
          END IF;
          CALL sbx_remove (_oid,  _rid, _uid );
          CALL permission_revoke (_rid, null);
          CALL yp.yp_notification_remove (_rid, null);
        END LOOP STARTLOOP;   
      CLOSE dbcursor;
    END;
    CALL mfs_trash_node (_rid);
    SELECT concat(user_filename,'-out') FROM media where id= _rid INTO _output;
  ELSE 
    SELECT user_filename FROM media where id= _rid INTO _output;
      IF _status <> 'deleted' THEN 
         CALL mfs_delete_node (_rid);
      END IF;
  END IF;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_unique_filename` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_unique_filename`(
  _pid VARCHAR(16) CHARACTER SET ascii,
  _file_name VARCHAR(200),
  _ext VARCHAR(20)
)
BEGIN
  DECLARE _r VARCHAR(2000);
  DECLARE _fname VARCHAR(1024);
  DECLARE _base VARCHAR(1024);
  DECLARE _exten VARCHAR(1024);
  
    SELECT _file_name INTO _fname;
    SELECT _fname INTO _base;
    SELECT '' INTO   _exten;

    IF _fname regexp '\\\([0-9]+\\\)$'  THEN 
      SELECT SUBSTRING_INDEX(_fname, '(', 1) INTO _base;
      SELECT  SUBSTRING_INDEX(_fname, ')', -1) INTO _exten;
    END IF;

    WITH RECURSIVE chk as
      (
        SELECT @de:=0 as n ,  _fname fname,
        (SELECT COUNT(1) FROM media WHERE parent_id = _pid 
          AND user_filename = _fname AND extension=IFNULL(_ext, '')
        ) cnt
      UNION ALL 
        SELECT @de:= n+1 n , CONCAT(_base, "(", n+1, ")", _exten) fname ,
        (SELECT COUNT(1) FROM media WHERE parent_id = _pid 
          AND user_filename = CONCAT(_base, "(", n+1, ")", _exten)
          AND extension=IFNULL(_ext, '') 
        ) cnt
        FROM chk c 
        WHERE n<1000 AND cnt >=1
      )
    SELECT fname FROM chk WHERE n =@de  INTO _r ;

  SELECT  _r user_filename;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_update_metadata` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_update_metadata`(
  IN _id    VARBINARY(16),
  IN _data  JSON
)
BEGIN
  DECLARE _value mediumtext;
  DECLARE _path VARCHAR(5000);
  DECLARE _paths VARCHAR(5000);
  DECLARE _i TINYINT(4) DEFAULT 0;


  SELECT JSON_ARRAY(
    "sharebox",
    "branch",
    "fingerprint",
    "expiry",
    "email",
    "message",
    "otp",
    "otp_mail",
    "otp_mail_verified",
    "sender_lang"
  ) INTO _paths;
  WHILE _i < JSON_LENGTH(_paths) DO
    SELECT read_json_array(_paths, _i) INTO _path;
    SELECT get_json_object(_data, _path) INTO _value;
    IF _value IS NOT NULL THEN
      IF _path = "fingerprint"  AND  _value <> '' THEN
        SELECT sha2(_value, 512) INTO _value;
      END IF;
      IF _path = "expiry" THEN
        SELECT IF(IFNULL(_value, 0) = 0, 0,
          UNIX_TIMESTAMP(TIMESTAMPADD(HOUR,_value, FROM_UNIXTIME(UNIX_TIMESTAMP())))) INTO _value;
       END IF;
      UPDATE media SET `metadata` =
        JSON_SET( IFNULL(metadata, '{}'), CONCAT("$.",_path), _value) WHERE id=_id;
    END IF;
    SELECT _i + 1 INTO _i;
  END WHILE;
  SELECT * FROM media WHERE id=_id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_update_rank` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_update_rank`(
  IN _node_id VARBINARY(16),
  IN _rank TINYINT(4)
)
BEGIN
  UPDATE media SET rank=_rank WHERE id=_node_id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `mfs_wicket_home` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `mfs_wicket_home`(
  IN _uid VARCHAR(16)
)
BEGIN
  DECLARE _wicket_db_name VARCHAR(255);
  DECLARE _wicket_id VARCHAR(16);

    
    

    SELECT h.id FROM 
      yp.hub h INNER JOIN yp.entity e on e.id=h.id
    WHERE h.owner_id=_uid AND `serial`=0
    INTO _wicket_id;

  
  
  

    SELECT db_name FROM yp.entity WHERE id=_wicket_id INTO _wicket_db_name;
    SET @st = CONCAT('CALL ', _wicket_db_name ,'.mfs_home()');
    PREPARE stamt FROM @st;
    EXECUTE stamt;
    DEALLOCATE PREPARE stamt;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `move_media` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `move_media`(
  IN _src_id VARCHAR(16),
  IN _dest_pid VARCHAR(16),
  IN _des_entity_id VARCHAR(16),
  IN _option  smallint   
  
  )
BEGIN
  DECLARE _id varchar(16);
  DECLARE _temp_filename varchar(1024);
  DECLARE _lvl int;
  DECLARE _des_db   VARCHAR(255);
  DECLARE _area VARCHAR(25);
  DECLARE _vhost VARCHAR(255);
  DECLARE _home_dir VARCHAR(500);
  DECLARE _hub_id VARCHAR(16);
  
  DECLARE _is_src_folder boolean; 
  SELECT 0 INTO _is_src_folder;
  SELECT 1 FROM media m WHERE category ='folder' AND  m.id =_src_id AND  _is_src_folder; 
  
  SELECT utils.vhost(ident), home_dir, id,db_name FROM yp.entity WHERE id=_des_entity_id
  INTO _vhost, _home_dir, _hub_id,_des_db;

    DROP TABLE IF EXISTS  _src_media;
    CREATE TEMPORARY TABLE _src_media (
    `id` varchar(16) DEFAULT NULL,
    `origin_id` varchar(16) DEFAULT NULL,
    `owner_id` varchar(16) NOT NULL,
    `host_id` varchar(16) NOT NULL,
    `file_path` varchar(512) DEFAULT NULL,
    `user_filename` varchar(128) DEFAULT NULL,
    `parent_id` varchar(16)  NULL DEFAULT '',
    `parent_path` varchar(1024) NOT NULL,
    `extension` varchar(100) NOT NULL DEFAULT '',
    `mimetype` varchar(100) NOT NULL,
    `category`  varchar(16) NOT NULL,
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
	  `lvl` int default 0,
    `is_checked` boolean default 0,
    `is_matched` boolean default 0,
    `is_delete` boolean default 0,
    `is_update` boolean default 0,
    `update_file_path`   varchar(1024)  NULL,
    `update_parent_path`   varchar(1024)  NULL
    
    );

    DROP TABLE IF EXISTS  _des_media;
    CREATE TEMPORARY TABLE _des_media AS SELECT  * from _src_media where 1=2;
    
    
    
    
    INSERT INTO _src_media (id,file_path,user_filename,parent_id,parent_path,category,
    origin_id,owner_id,host_id,extension,mimetype,isalink,filesize,geometry,publish_time,upload_time,
    last_download,download_count,metadata,caption,status,approval,rank,
    is_checked,relative_path,lvl)
    SELECT id,file_path,user_filename,parent_id ,parent_path,category,
    origin_id,owner_id,host_id,extension,mimetype,isalink,filesize,geometry,publish_time,upload_time,
    last_download,download_count,metadata,caption,status,approval,rank,
    0, user_filename,0
    FROM media m WHERE m.id =_src_id;
   


    SELECT  id ,relative_path ,lvl FROM _src_media WHERE is_checked =0 LIMIT 1 INTO _id ,_temp_filename  ,_lvl;
    SET  _temp_filename =IFNULL(_temp_filename,'');

    WHILE _id is not null DO
      
        INSERT INTO _src_media (id,file_path,user_filename,parent_id ,parent_path,category,
        origin_id,owner_id,host_id,extension,mimetype,isalink,filesize,geometry,publish_time,upload_time,
        last_download,download_count,metadata,caption,status,approval,rank,
        is_checked,relative_path,lvl)
        SELECT  
          id,file_path,user_filename,parent_id,parent_path,category,
          origin_id,owner_id,host_id,extension,mimetype,isalink,filesize,geometry,publish_time,upload_time,
          last_download,download_count,metadata,caption,status,approval,rank,
          0,CONCAT(_temp_filename,"/",user_filename ) ,_lvl+1
        FROM media WHERE  parent_id =_id;
        
        UPDATE _src_media SET is_checked = 1 WHERE id = _id;
        SELECT NULL INTO _id;
        SELECT id ,relative_path ,lvl FROM _src_media WHERE is_checked =0 LIMIT 1 INTO _id,_temp_filename ,_lvl ;
        SET  _temp_filename =IFNULL(_temp_filename,"");
    END WHILE;




    
    SELECT NULL,NULL INTO _id,_temp_filename;
    SET @sql = CONCAT('
    INSERT INTO _des_media 
      (id,file_path,user_filename,parent_id ,parent_path,category,
      origin_id,owner_id,host_id,extension,mimetype,isalink,filesize,geometry,publish_time,upload_time,
      last_download,download_count,metadata,caption,status,approval,rank,
      is_checked,relative_path,lvl)
    SELECT
      m.id,m.file_path,m.user_filename,m.parent_id ,m.parent_path,m.category,
      origin_id,owner_id,host_id,extension,mimetype,isalink,filesize,geometry,publish_time,upload_time,
      last_download,download_count,metadata,caption,status,approval,rank,
      0, m.user_filename,0
    FROM ' ,_des_db ,'.media m
    WHERE 
      parent_id ="', _dest_pid ,'" AND 
      category = ', CASE WHEN _is_src_folder =1 THEN "'folder'" ELSE "category" END ,'     AND 
      user_filename  = ( SELECT  user_filename  FROM _src_media sm WHERE sm.id ="', _src_id,'")');

    PREPARE stmt FROM @sql ;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

  
    SELECT  id ,relative_path,lvl FROM _des_media WHERE is_checked =0 LIMIT 1 INTO _id ,_temp_filename,_lvl; 
    SET  _temp_filename =IFNULL(_temp_filename,'''');

    WHILE _id is not null DO
         SET @sql = CONCAT('
        INSERT INTO _des_media (id,file_path,user_filename,parent_id ,parent_path,category,
        origin_id,owner_id,host_id,extension,mimetype,isalink,filesize,geometry,publish_time,upload_time,
        last_download,download_count,metadata,caption,status,approval,rank,
        is_checked,relative_path,lvl)
        SELECT  
          id,file_path,user_filename,parent_id,parent_path,category,
          origin_id,owner_id,host_id,extension,mimetype,isalink,filesize,geometry,publish_time,upload_time,
          last_download,download_count,metadata,caption,status,approval,rank,
          0,','CONCAT("',_temp_filename,'","/",user_filename ) ,',_lvl+1,
                ' FROM ' ,_des_db,'.media WHERE  parent_id ="',_id,'"');
        PREPARE stmt FROM @sql ;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
        UPDATE _des_media SET is_checked = 1 WHERE id = _id;
        SELECT NULL INTO _id;
        SELECT id ,relative_path,lvl FROM _des_media WHERE is_checked =0 LIMIT 1 INTO _id,_temp_filename,_lvl ;
        SET  _temp_filename =IFNULL(_temp_filename,"");
    END WHILE;
    
    
    UPDATE _des_media dm,_src_media sm SET dm.is_matched = 1 , sm.is_matched =1
	  WHERE  dm.relative_path = sm.relative_path AND dm.category=sm.category;


	  
	  UPDATE _des_media set is_delete=1 WHERE _option =0 ; 
    UPDATE _src_media set is_update=1 WHERE _option =0 ; 
	 
	  
	  UPDATE _des_media SET is_delete=1 WHERE _option =1 and is_matched= 1;  
    UPDATE _des_media SET is_update=1 WHERE _option =1 and is_matched= 0;  
    UPDATE _src_media SET is_update=1 WHERE _option =1;   


	  
	  

    SET @sql = CONCAT('SELECT file_path INTO @temp_parent_path FROM ', _des_db, '.media WHERE id = "', _dest_pid,'"');
    PREPARE stmt FROM @sql ;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
      
	  UPDATE _src_media SET update_file_path=concat(@temp_parent_path,"/",relative_path);
	  UPDATE _src_media SET update_parent_path= left(update_file_path , LENGTH(update_file_path)- LENGTH(user_filename)-1) ;	
     
     
    
	  
	  UPDATE _des_media SET update_file_path=concat(@temp_parent_path,"/",relative_path);
	  UPDATE _des_media SET update_parent_path= left(update_file_path , LENGTH(update_file_path)- LENGTH(user_filename)-1) ;	

	  
    UPDATE _src_media SET parent_id = _dest_pid WHERE lvl=0;
    
	  
    UPDATE _src_media sm, _des_media dm SET dm.parent_id = sm.id 
    WHERE  dm.is_matched=0 AND dm.is_delete=0 AND dm.update_parent_path = sm.update_file_path AND dm.lvl=sm.lvl+1 AND _option = 1 ;
    


    update _src_media set 
    update_file_path =  CONCAT( update_parent_path,"/", id ,"-orig.",extension)
    WHERE category NOT IN ("folder","hub");

    update _des_media set 
    update_file_path =  CONCAT( update_parent_path,"/", id ,"-orig.",extension)
    WHERE category NOT IN ("folder","hub");


	  
   
      DELETE FROM media WHERE id in (SELECT  id FROM _src_media );
      
      SET @sql = CONCAT('DELETE FROM ', _des_db , '.media WHERE id in (SELECT  id FROM _des_media )');
      PREPARE stmt FROM @sql ;
      EXECUTE stmt;
      DEALLOCATE PREPARE stmt;
      
      
      SET @sql = CONCAT( 'INSERT INTO ',_des_db,'.media (id,file_path,user_filename,parent_id ,parent_path,category,
      origin_id,owner_id,host_id,extension,mimetype,isalink,filesize,geometry,publish_time,upload_time,
      last_download,download_count,metadata,caption,status,approval,rank)
      SELECT id,update_file_path,user_filename,parent_id ,update_parent_path,category,
      origin_id,owner_id,host_id,extension,mimetype,isalink,filesize,geometry,UNIX_TIMESTAMP(),UNIX_TIMESTAMP(),
      last_download,download_count,metadata,caption,status,approval,rank FROM _src_media where is_update =1') ;
      PREPARE stmt FROM @sql ;
      EXECUTE stmt;
      DEALLOCATE PREPARE stmt;


      SET @sql = CONCAT( 'INSERT INTO ',_des_db,'.media (id,file_path,user_filename,parent_id ,parent_path,category,
      origin_id,owner_id,host_id,extension,mimetype,isalink,filesize,geometry,publish_time,upload_time,
      last_download,download_count,metadata,caption,status,approval,rank)
      SELECT id,update_file_path,user_filename,parent_id ,update_parent_path,category,
      origin_id,owner_id,host_id,extension,mimetype,isalink,filesize,geometry,UNIX_TIMESTAMP(),UNIX_TIMESTAMP(),
      last_download,download_count,metadata,caption,status,approval,rank FROM _des_media where is_update =1') ;
      PREPARE stmt FROM @sql ;
      EXECUTE stmt;
      DEALLOCATE PREPARE stmt;
      
  
    
    
    SELECT 
      id, 
      id nid,
      parent_id pid,
      concat(_home_dir, "/__storage__/", parent_path) parent_path,
      concat(_home_dir, "/__storage__/", parent_path) sys_parent_path,
      file_path,
      user_filename filename,
      extension ext,
      category filetype,
      category
    FROM _des_media 
    WHERE 
      category NOT IN ("folder","hub")  AND
      is_delete =1  AND
      is_matched= 1 AND
      _option =1;
    
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `node_from_path` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `node_from_path`(
  IN _path VARCHAR(1024)
)
BEGIN
  DECLARE _r VARCHAR(16);
  DECLARE _id VARCHAR(16);
  DECLARE _count INT(6);
  DECLARE _file_path VARCHAR(1024);

  SELECT id FROM media 
    WHERE TRIM('/' FROM file_path) = TRIM('/' FROM _path) AND category='folder'  LIMIT 1
    INTO _id;
  IF _id IS NOT NULL THEN 
    SELECT _path, _id INTO _file_path, _id;
  ELSE 
    SELECT TRIM('/' FROM _path) INTO @path;
    SET @node = @path;
    WHILE @path regexp  '.+\/.+' AND _id IS NULL DO 
      SELECT SUBSTRING_INDEX(@path, '/', -1) INTO @node;

      SELECT TRIM('/' FROM REPLACE(@path, @nodeh, '')) INTO @path;
      SELECT NULL INTO _id;
      SELECT @path AS parent_path, id FROM media 
        WHERE TRIM('/' FROM file_path) = @path AND category='folder'  LIMIT 1 
        INTO _file_path, _id;
    END WHILE;
    IF _id IS NULL THEN 
      SELECT TRIM('/' FROM REPLACE(_path, @node, '')) INTO @path;
      SELECT CONCAT('/', @path), id FROM media 
        WHERE TRIM('/' FROM file_path) = @path AND category='folder'  LIMIT 1 
        INTO _file_path, _id;
    END IF;
  END IF;
  SELECT _file_path AS file_path, _id AS id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `notification_entity` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `notification_entity`(
  _uid VARCHAR(16) CHARACTER SET ascii
)
BEGIN

DECLARE _hub_id VARCHAR(16) CHARACTER SET ascii;
DECLARE _area VARCHAR(500);
DECLARE _db_name VARCHAR(500);
DECLARE _domain_id INT;
DECLARE _is_support INT DEFAULT 0 ;
DECLARE _wicket_db_name VARCHAR(255);
DECLARE _wicket_id VARCHAR(16);

  SELECT db_name FROM yp.entity WHERE id =_uid INTO _db_name;
  SELECT id , area , if (area = 'personal' ,db_name , _db_name) FROM yp.entity 
  WHERE db_name = DATABASE() 
  INTO _hub_id ,_area, _db_name;

  DROP TABLE IF EXISTS _show_node;
  CREATE TEMPORARY TABLE _show_node (
      resource_id  VARCHAR(16) CHARACTER SET ascii,
      entity_id VARCHAR(16) CHARACTER SET ascii,
      hub_id VARCHAR(16) CHARACTER SET ascii,
      ctime  INT(11) ,
      area  VARCHAR(16),
      category VARCHAR(16)
   );

  
    IF _area = 'personal' THEN 
      
      INSERT INTO _show_node
      SELECT 
          ci.id  ,d.id ,_uid , mtime,'personal' ,'contact'
      FROM 
      contact ci 
      INNER JOIN yp.drumate d ON d.id = ci.entity
      WHERE (ci.status="received") OR (ci.status="informed") OR (ci.status="invitation");

      
      INSERT INTO _show_node
      SELECT   
          ch.message_id, ch.author_id , _uid ,ch.ctime , 'personal' , 'chat'   
      FROM    
          channel ch    
      INNER JOIN read_channel rc ON ch.entity_id= rc.entity_id    
      INNER JOIN contact c ON c.uid = ch.entity_id   
      WHERE ch.entity_id = ch.author_id  AND  rc.entity_id <> rc.uid  AND  ch.sys_id > rc.ref_sys_id;

     
      
      SELECT domain_id FROM yp.privilege WHERE uid = _uid INTO _domain_id;
      SELECT 1  FROM yp.sys_conf WHERE  conf_key = 'support_domain' 
      AND conf_value =_domain_id INTO _is_support;

      IF _is_support <> 1 THEN 

            SELECT h.id FROM 
            yp.hub h INNER JOIN yp.entity e on e.id=h.id
            WHERE h.owner_id=_uid AND `serial`=0
            INTO _wicket_id;

            SELECT db_name FROM yp.entity WHERE id=_wicket_id INTO _wicket_db_name;

            SET @s = CONCAT("
                    INSERT INTO _show_node
                    SELECT 
                    t.ticket_id  , t.ticket_id , 'Support Ticket' , c.ctime ,'personal','ticket'
                    FROM 
                    yp.ticket t  
                    INNER JOIN ", _wicket_db_name ,". map_ticket mt  ON  mt.ticket_id = t.ticket_id 
                    INNER JOIN ", _wicket_db_name ,".channel c ON mt.message_id = c.message_id
                    LEFT JOIN yp.read_ticket_channel rtc on rtc.ticket_id = mt.ticket_id AND rtc.uid =?
                    WHERE t.uid =? AND c.sys_id > IFNULL(rtc.ref_sys_id,0)"

            );
            PREPARE stmt FROM @s;
            EXECUTE stmt USING _uid,_uid;
            DEALLOCATE PREPARE stmt;

        ELSE 
            INSERT INTO _show_node
            SELECT
                t.ticket_id, t.ticket_id , 'Support Ticket' , rtc.ctime ,'personal','ticket'
            FROM 
                yp.ticket t 
            LEFT JOIN yp.read_ticket_channel rtc on rtc.ticket_id = t.ticket_id AND rtc.uid = _uid
            WHERE 
                t.last_sys_id > IFNULL(rtc.ref_sys_id,0) 
                AND CASE WHEN _is_support = 1 THEN t.uid ELSE _uid END = t.uid;
        END IF;

    END IF;

    IF _area = 'private' THEN 
      INSERT INTO _show_node
      SELECT
          c.message_id,_hub_id ,_hub_id ,c.ctime,_area, 'teamchat'  
      FROM channel c 
      WHERE c.sys_id > (SELECT  ref_sys_id FROM read_channel WHERE uid = _uid );
    END IF;

    IF _area <> 'personal' THEN 
      INSERT INTO _show_node
      SELECT id, _hub_id, _hub_id ,  m.upload_time, _area ,'media' 
      FROM media m 
      WHERE file_path NOT REGEXP '^/__(chat|trash)__'  AND 
      IFNULL((is_new(metadata, owner_id, _uid)), 0) =1;
    END IF; 
   
   
   
   

   
   
   
   
   
   
   
   
   

    INSERT INTO _show_node 
    SELECT NULL , _hub_id,  IF (_area = 'personal', _uid ,_hub_id), 0,_area , 'empty' 
    WHERE NOT EXISTS (SELECT resource_id FROM  _show_node LIMIT 1);


    SET @s = CONCAT("
        SELECT  
            c.id contact_id,
            d.id drumate_id,
            dmu.id guest_id,
            coalesce(c.id,  d.id,dmu.id, CASE WHEN hub_id = 'Support Ticket' THEN entity_id ELSE hub_id END) key_id,
            coalesce(c.firstname, d.lastname, dmu.email) firstname,  
            coalesce(c.lastname, d.lastname, dmu.email) lastname,
            IF ( hub_id <>'Support Ticket' , (coalesce( IFNULL(c.surname,IF(coalesce(c.firstname, c.lastname) IS NULL,coalesce(ce.email,d.email,dmu.email),
            CONCAT( IFNULL(c.firstname, '') ,' ',  IFNULL(c.lastname, '')))) ,  h.name )), entity_id )surname,
            coalesce(ce.email,d.email,dmu.email) email,
            c.status status,
            b.hub_id hub_id,
            -- m.user_filename,
            b.ctime,
            b.category,
            b.cnt,
            b.area
        FROM 
        (SELECT 
            count(resource_id) cnt ,entity_id,hub_id,category,max(ctime) ctime ,area  
        FROM  _show_node 
        GROUP BY entity_id,hub_id,category,area ) b 
        LEFT JOIN yp.hub h ON h.id = b.hub_id   
        LEFT JOIN yp.dmz_user dmu ON b.entity_id = dmu.id
        LEFT JOIN yp.drumate d ON b.entity_id = d.id 
        LEFT JOIN ",_db_name,".contact c ON  b.entity_id = c.uid  OR  b.entity_id = c.entity
        LEFT JOIN ",_db_name,".contact_email ce ON ce.contact_id = c.id   AND ce.is_default = 1
        ORDER BY b.ctime DESC"
          );
    PREPARE stmt FROM @s;
    EXECUTE stmt ;
    DEALLOCATE PREPARE stmt;


END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `notification_entity_next` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `notification_entity_next`(
  _uid VARCHAR(16) CHARACTER SET ascii
)
BEGIN

DECLARE _hub_id VARCHAR(16) CHARACTER SET ascii;
DECLARE _area VARCHAR(500);
DECLARE _db_name VARCHAR(500);
DECLARE _domain_id INT;
DECLARE _is_support INT DEFAULT 0 ;
DECLARE _wicket_db_name VARCHAR(255);
DECLARE _wicket_id VARCHAR(16);

  SELECT db_name FROM yp.entity WHERE id =_uid INTO _db_name;
  SELECT id , area , if (area = 'personal' ,db_name , _db_name) FROM yp.entity 
  WHERE db_name = DATABASE() 
  INTO _hub_id ,_area, _db_name;

  DROP TABLE IF EXISTS _show_node;
  CREATE TEMPORARY TABLE _show_node (
      resource_id  VARCHAR(16) CHARACTER SET ascii,
      entity_id VARCHAR(16) CHARACTER SET ascii,
      hub_id VARCHAR(16) CHARACTER SET ascii,
      ctime  INT(11) ,
      area  VARCHAR(16),
      category VARCHAR(16)
   );

  
    IF _area = 'personal' THEN 
      
      INSERT INTO _show_node
      SELECT 
          ci.id  ,d.id ,_uid , mtime,'personal' ,'contact'
      FROM 
      contact ci 
      INNER JOIN yp.drumate d ON d.id = ci.entity
      WHERE (ci.status="received") OR (ci.status="informed") OR (ci.status="invitation");

      
      INSERT INTO _show_node
      SELECT   
          ch.message_id, ch.author_id , _uid ,ch.ctime , 'personal' , 'chat'   
      FROM    
          channel ch    
      INNER JOIN read_channel rc ON ch.entity_id= rc.entity_id    
      INNER JOIN contact c ON c.uid = ch.entity_id   
      WHERE ch.entity_id = ch.author_id  AND  rc.entity_id <> rc.uid  AND  ch.sys_id > rc.ref_sys_id;

     
      
      SELECT domain_id FROM yp.privilege WHERE uid = _uid INTO _domain_id;
      SELECT 1  FROM yp.sys_conf WHERE  conf_key = 'support_domain' 
      AND conf_value =_domain_id INTO _is_support;

      IF _is_support <> 1 THEN 

            SELECT h.id FROM 
            yp.hub h INNER JOIN yp.entity e on e.id=h.id
            WHERE h.owner_id=_uid AND `serial`=0
            INTO _wicket_id;

            SELECT db_name FROM yp.entity WHERE id=_wicket_id INTO _wicket_db_name;

            SET @s = CONCAT("
                    INSERT INTO _show_node
                    SELECT 
                    t.ticket_id  , t.ticket_id , 'Support Ticket' , c.ctime ,'personal','ticket'
                    FROM 
                    yp.ticket t  
                    INNER JOIN ", _wicket_db_name ,". map_ticket mt  ON  mt.ticket_id = t.ticket_id 
                    INNER JOIN ", _wicket_db_name ,".channel c ON mt.message_id = c.message_id
                    LEFT JOIN yp.read_ticket_channel rtc on rtc.ticket_id = mt.ticket_id AND rtc.uid =?
                    WHERE t.uid =? AND c.sys_id > IFNULL(rtc.ref_sys_id,0)"

            );
            PREPARE stmt FROM @s;
            EXECUTE stmt USING _uid,_uid;
            DEALLOCATE PREPARE stmt;

        ELSE 
            INSERT INTO _show_node
            SELECT
                t.ticket_id, t.ticket_id , 'Support Ticket' , rtc.ctime ,'personal','ticket'
            FROM 
                yp.ticket t 
            LEFT JOIN yp.read_ticket_channel rtc on rtc.ticket_id = t.ticket_id AND rtc.uid = _uid
            WHERE 
                t.last_sys_id > IFNULL(rtc.ref_sys_id,0) 
                AND CASE WHEN _is_support = 1 THEN t.uid ELSE _uid END = t.uid;
        END IF;

    END IF;

    IF _area = 'private' THEN 
      INSERT INTO _show_node
      SELECT
          c.message_id,_hub_id ,_hub_id ,c.ctime,_area, 'teamchat'  
      FROM channel c 
      WHERE c.sys_id > (SELECT  ref_sys_id FROM read_channel WHERE uid = _uid );
    END IF;

    IF _area <> 'personal' THEN 
      INSERT INTO _show_node
      SELECT id, _hub_id, _hub_id ,  m.upload_time, _area ,'media' 
      FROM media m 
      WHERE file_path NOT REGEXP '^/__(chat|trash)__'  AND 
      IFNULL((is_new(metadata, owner_id, _uid)), 0) =1;
    END IF; 
   
   
   
   

   
   
   
   
   
   
   
   
   

    INSERT INTO _show_node 
    SELECT NULL , _hub_id,  IF (_area = 'personal', _uid ,_hub_id), 0,_area , 'empty' 
    WHERE NOT EXISTS (SELECT resource_id FROM  _show_node LIMIT 1);


    SET @s = CONCAT("
        SELECT  
            c.id contact_id,
            d.id drumate_id,
            dmu.id guest_id,
            coalesce(c.id,  d.id,dmu.id, CASE WHEN hub_id = 'Support Ticket' THEN entity_id ELSE hub_id END) key_id,
            coalesce(c.firstname, d.lastname, dmu.email) firstname,  
            coalesce(c.lastname, d.lastname, dmu.email) lastname,
            IF ( hub_id <>'Support Ticket' , (coalesce( IFNULL(c.surname,IF(coalesce(c.firstname, c.lastname) IS NULL,coalesce(ce.email,d.email,dmu.email),
            CONCAT( IFNULL(c.firstname, '') ,' ',  IFNULL(c.lastname, '')))) ,  h.name )), entity_id )surname,
            coalesce(ce.email,d.email,dmu.email) email,
            c.status status,
            b.hub_id hub_id,
            -- m.user_filename,
            b.ctime,
            b.category,
            b.cnt,
            b.area,
            (SELECT GROUP_CONCAT(t.tag_id) FROM 
            ",_db_name,".tag t INNER JOIN ",_db_name,".map_tag mt ON t.tag_id = mt.tag_id 
            WHERE mt.id = coalesce(c.id,  d.id,dmu.id,  CASE WHEN hub_id = 'Support Ticket' THEN entity_id ELSE hub_id END  )) as tag_id
        FROM 
        (SELECT 
            count(resource_id) cnt ,entity_id,hub_id,category,max(ctime) ctime ,area  
        FROM  _show_node 
        GROUP BY entity_id,hub_id,category,area ) b 
        LEFT JOIN yp.hub h ON h.id = b.hub_id   
        LEFT JOIN yp.dmz_user dmu ON b.entity_id = dmu.id
        LEFT JOIN yp.drumate d ON b.entity_id = d.id 
        LEFT JOIN ",_db_name,".contact c ON  b.entity_id = c.uid  OR  b.entity_id = c.entity
        LEFT JOIN ",_db_name,".contact_email ce ON ce.contact_id = c.id   AND ce.is_default = 1
        ORDER BY b.ctime DESC"
          );
    PREPARE stmt FROM @s;
    EXECUTE stmt ;
    DEALLOCATE PREPARE stmt;


END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `pages_to_read` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `pages_to_read`(
   IN  _uid VARCHAR(16)
)
BEGIN
  DECLARE _page int(11);
  DECLARE _ref_sys_id int(11) unsigned default 0 ;
  DECLARE _pos_cnt int(11) unsigned default 0 ;
  DECLARE _all_cnt int(11) unsigned default 0 ;

  DECLARE _range bigint;
  DECLARE _offset bigint;

  CALL pageToLimits(_page, _offset, _range);  
  
  SELECT ref_sys_id FROM read_channel WHERE  uid = _uid INTO _ref_sys_id;
  SELECT COUNT(sys_id) FROM channel WHERE  sys_id <=_ref_sys_id  INTO _pos_cnt ;
  SELECT COUNT(sys_id) FROM channel  INTO  _all_cnt ;


  SELECT  FLOOR( (IFNULL(_all_cnt,0)  - IFNULL(_pos_cnt,0))  /_range)+1  page;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `pageToLimits` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `pageToLimits`(
  IN _page VARCHAR(32),
  OUT _offset BIGINT,
  OUT _range BIGINT
)
BEGIN
  SELECT (_page - 1)*45, 45 INTO _offset,_range;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `page_add_history` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `page_add_history`(
   IN _id        VARCHAR(512),
   IN _hashtag   VARCHAR(512),
   IN _device    VARCHAR(16),
   IN _lang      VARCHAR(20),
   IN _status    VARCHAR(20),
   IN _isonline  INT(4),
   IN _author_id VARBINARY(16)
)
BEGIN
    DECLARE _ts   INT(11) DEFAULT 0;
    SELECT UNIX_TIMESTAMP() INTO _ts;
    INSERT INTO page_history (`author_id`, `master_id`, `lang`, `device`, `meta`, `status`, `isonline`, `ctime`)
      VALUES(_author_id, _id, _lang, _device, _hashtag, _status, _isonline, _ts);
    SELECT LAST_INSERT_ID() as history_id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `page_copy` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `page_copy`(
   IN _key    VARCHAR(16),
   IN _author  VARCHAR(160)
)
BEGIN
   DECLARE _id VARBINARY(16) DEFAULT '';
   DECLARE _hashtag VARCHAR(512);
   DECLARE _version TINYINT(4);
   DECLARE _tag VARCHAR(512);
   DECLARE _ident VARCHAR(512);

   SELECT id, hashtag FROM page WHERE (id=_key OR hashtag=_key) INTO _id, _hashtag;
   SELECT COUNT(*) FROM page WHERE hashtag LIKE concat(_hashtag, '-v%') INTO _version;
   SET _hashtag = CONCAT(_hashtag, '-v', _version);
   SELECT COUNT(*) FROM page WHERE hashtag = _hashtag INTO _version;
   WHILE _version > 0 DO
      SET _version = _version + 1;
      SET _hashtag = CONCAT(_hashtag, '-v', _version);
      SELECT COUNT(*) FROM page WHERE hashtag = _hashtag INTO _version;
   END WHILE;
   INSERT INTO page
      SELECT null, uniqueId(), serial, active, _author, _hashtag, `type`, editor, status, ctime, mtime, version
      FROM page WHERE id=_id;
   SELECT *, @vhost AS vhost, _id as src_id FROM page WHERE hashtag=_hashtag;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `page_copy_new` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `page_copy_new`(
   IN _history_id     VARCHAR(16),
   IN _author         VARCHAR(160),
   IN _to_lang        VARCHAR(20),
   IN _hashtag        VARCHAR(512),
   IN _new_page       VARCHAR(10)
)
BEGIN
   DECLARE _id VARBINARY(16) DEFAULT '';
   DECLARE _new_id VARBINARY(16) DEFAULT '';
   DECLARE _version TINYINT(4);
   DECLARE _tag VARCHAR(512);
   DECLARE _ident VARCHAR(512);
   DECLARE _lang varchar(10);
   DECLARE _device varchar(100);
   DECLARE _ts INT(11) DEFAULT 0;
   DECLARE _last INT(11) DEFAULT 0;
   DECLARE _page_exist INT(4) DEFAULT 0;

   SELECT UNIX_TIMESTAMP() INTO _ts;

   START TRANSACTION;
   SELECT master_id, lang, device FROM page_history WHERE serial = _history_id INTO _id, _lang, _device;
   
   SELECT EXISTS (SELECT serial FROM page_history WHERE master_id = _id AND lang = _to_lang AND device = _device) INTO _page_exist;
   IF _lang <> _to_lang AND _page_exist = 1 AND _new_page = "0" THEN
      SELECT 1 AS confirm_copy;
   ELSE
      IF _lang = _to_lang OR (_page_exist = 1 AND _lang <> _to_lang AND _new_page = "1") THEN
        SELECT UNIQUEID() INTO _new_id;
        IF IFNULL(_hashtag, '') = "" THEN
          SELECT hashtag FROM page WHERE id = _id INTO _hashtag;
          
          
          
          
          
          
          
          
          SELECT IFNULL(MAX(SUBSTRING_INDEX(hashtag, '-v', -1)),-1) as d FROM page
            WHERE hashtag REGEXP CONCAT(_hashtag, '-v[0-9]*$') INTO _version;
          SET _hashtag = CONCAT(_hashtag, '-v', _version + 1);

        END IF;
      ELSE
          SELECT _id INTO _new_id;
      END IF;

      UPDATE page_history SET status = 'history' WHERE master_id = _new_id AND lang = _to_lang AND device = _device;
      INSERT INTO page_history (`author_id`, `master_id`, `lang`, `device`, `status`, `isonline`, `meta`, `ctime`)
          VALUES(_author, _new_id, _to_lang, _device, 'draft', 0, _hashtag, _ts);
      SELECT LAST_INSERT_ID() INTO _last;

      IF _lang = _to_lang OR (_page_exist = 1 AND _lang <> _to_lang AND _new_page = "1") THEN
          INSERT INTO page (sys_id, id, serial, active, author_id, hashtag, `type`, editor, status, ctime, mtime, version)
              SELECT null, _new_id, _last, _last, _author, _hashtag, `type`, editor, status, _ts, _ts, version
              FROM page WHERE id=_id;
      END IF;
      COMMIT;
      SELECT *, _hashtag AS hashtag, @vhost AS vhost, _id as src_id, 0 AS confirm_copy FROM page_history WHERE serial=_last;
   END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `page_delete_by_id_lang` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `page_delete_by_id_lang`(
   IN _id           VARCHAR(512),
   IN _locale       VARCHAR(100),
   IN _device       VARCHAR(16)
)
BEGIN
  
  DECLARE _eid VARCHAR (16);

  DELETE FROM page_history WHERE master_id = _id AND lang = _locale AND device = _device;
  DELETE page FROM page WHERE id = _id AND id NOT IN (SELECT master_id
    FROM page_history WHERE master_id = _id);
  
  SELECT id FROM yp.entity WHERE db_name = DATABASE() INTO _eid;
  CALL yp.set_homepage(_eid);


END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `page_delete_by_lang` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `page_delete_by_lang`(
   IN _locale       VARCHAR(100)
)
BEGIN
  DELETE FROM page_history WHERE lang=_locale;
  DELETE page FROM page WHERE id NOT IN (SELECT master_id FROM page_history);
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `page_exists` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `page_exists`(
  IN _hashtag        VARCHAR(512)
)
BEGIN
  SELECT id FROM page WHERE hashtag = _hashtag;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `page_get` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `page_get`(
   IN _tag VARCHAR(512),
   IN _device  VARCHAR(16),
   IN _lang  VARCHAR(16)
)
BEGIN
   DECLARE _existence INT(4);
   SELECT EXISTS (
    SELECT master_id FROM page LEFT JOIN page_history 
      ON master_id = page.id 
      WHERE page.id=_tag OR hashtag=_tag
      AND lang = _lang AND device = _device
   ) INTO _existence;
          
  IF _existence THEN
   SELECT 
    page.id, 
    active, 
    hashtag, 
    `type`, 
    editor, 
    page.status, 
    firstname, 
    lastname,
    ctime, 
    mtime, 
    version
      FROM page LEFT JOIN yp.drumate ON page.author_id=drumate.id
      WHERE (page.id=_tag OR hashtag=_tag);
      
      
      
      
  ELSE
    SELECT id, status FROM page WHERE id=_tag OR hashtag=_tag;
  END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `page_get_base_by_lang` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `page_get_base_by_lang`(
   IN _base_lang       VARCHAR(100)
)
BEGIN
  SELECT serial AS history_id, master_id AS page_id, lang, device, status, isonline, meta
    FROM page_history WHERE (lang = _base_lang AND isonline=1)
    OR (lang = _base_lang AND status='draft' AND isonline=0);
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `page_get_by_id` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `page_get_by_id`(
   IN _key VARCHAR(512)
)
BEGIN
  SELECT page.id, active, hashtag, `type`, editor, status, firstname, lastname ctime, mtime, version
    FROM page LEFT JOIN yp.drumate ON author_id=drumate.id WHERE page.id = _key OR hashtag= _key;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `page_get_by_type` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `page_get_by_type`(
   IN _tag VARCHAR(512),
   IN _device  VARCHAR(16),
   IN _lang  VARCHAR(16),
   IN _type  VARCHAR(16)

)
BEGIN
   SELECT page.id, active, hashtag, `type`, editor, status, firstname, lastname ctime, mtime, version
         FROM page LEFT JOIN yp.drumate ON author_id=drumate.id WHERE `type`=_type;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `page_get_draft_publish` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `page_get_draft_publish`(
   IN _locale       VARCHAR(100),
   IN _published    INT(4),
   IN _hashtag      VARCHAR(500),
   IN _sort_by      VARCHAR(100),
   IN _sort         VARCHAR(100),
   IN _page         INT(11)
)
BEGIN
  DECLARE _range int(6);
  DECLARE _offset int(6);
  CALL pageToLimits(_page, _offset, _range);
  SELECT bh.serial AS history_id, id AS page_id, lang, device, bh.status,
    isonline, hashtag  FROM page b INNER JOIN page_history bh ON b.id = bh.master_id
    WHERE lang = _locale AND hashtag LIKE CONCAT('%', TRIM(IFNULL(_hashtag,'')), '%')
    AND CASE WHEN _published = 1 OR _published = 2 THEN 
      CASE WHEN _published = 2 THEN (bh.status = 'draft' OR isonline=1)
      ELSE isonline = 1 END
    ELSE bh.status = 'draft' END
    ORDER BY
    CASE WHEN LCASE(_sort_by) = 'date' and LCASE(_sort) = 'asc' THEN b.mtime END ASC,
    CASE WHEN LCASE(_sort_by) = 'date' and LCASE(_sort) = 'desc' THEN b.mtime END DESC,
    CASE WHEN LCASE(_sort) = 'desc' THEN hashtag END DESC,
    CASE WHEN LCASE(_sort) <> 'desc' THEN hashtag END ASC
    LIMIT _offset, _range;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `page_get_thread` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `page_get_thread`(
  IN _key VARCHAR(500),
  IN _criteria VARCHAR(16),
  IN _page TINYINT(4)
)
BEGIN
  DECLARE _range int(6);
  DECLARE _offset int(6);
  DECLARE _head int(6);
  DECLARE _hashtag VARCHAR(500);
  DECLARE _id VARBINARY(16);
  DECLARE _status VARCHAR(16);

  CALL pageToLimits(_page, _offset, _range);

  SELECT id, status, active, hashtag FROM page WHERE id=_key OR hashtag=_key
     INTO _id, _status, _head, _hashtag;

  IF _criteria LIKE "D%" THEN
    SELECT serial, author_id, master_id, lang, device, _hashtag as hashtag,
          master_id as id, firstname, lastname, ctime, _head as head
    FROM page_history LEFT JOIN yp.drumate on author_id=drumate.id
      WHERE master_id=_id ORDER BY ctime DESC LIMIT _offset, _range;
  ELSE
    SELECT serial, author_id, master_id, lang, device, _hashtag as hashtag,
          master_id as id, firstname, lastname, ctime, _head as head
    FROM page_history LEFT JOIN yp.drumate on author_id=drumate.id
      WHERE master_id=_id ORDER BY ctime ASC LIMIT _offset, _range;
  END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `page_get_used_languages` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `page_get_used_languages`(
  IN _hashtag  varchar(256)
)
BEGIN
  SELECT lang FROM page LEFT JOIN page_history ON page.id=master_id 
  WHERE hashtag=_hashtag or master_id=_hashtag GROUP BY lang;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `page_history_check_published` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `page_history_check_published`(
   IN _id           VARCHAR(512),
   IN _locale       VARCHAR(100),
   IN _device       VARCHAR(16)
)
BEGIN
  SELECT EXISTS (SELECT serial FROM page_history WHERE master_id = _id AND isonline = 1
    AND lang = _locale AND device = _device) AS IS_PUBLISHED;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `page_history_log` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `page_history_log`(
  IN _tag VARCHAR(400),
  IN _device VARCHAR(16),
  IN _lang VARCHAR(16),
  IN _page TINYINT(4),
  IN _month INT(4),
  IN _year INT(4),
  IN _criteria VARCHAR(16)
)
BEGIN
  DECLARE _range int(6);
  DECLARE _offset int(6);
  DECLARE _active int(8);
  DECLARE _id   VARBINARY(16) DEFAULT '';
  DECLARE _hashtag   varchar(400);

  SELECT id, hashtag, active FROM page WHERE id=_tag OR hashtag=_tag INTO _id, _hashtag, _active;
  CALL pageToLimits(_page, _offset, _range);

  IF _criteria LIKE "D%" THEN
    SELECT _hashtag AS hashtag, author_id, _id AS id,
       serial, ctime, firstname, lastname,lang, device, IF(serial=_active, 1, 0) AS active,
       FROM_UNIXTIME(ctime) AS created_date, status, isonline
       FROM page_history LEFT JOIN (yp.drumate)
       ON author_id=drumate.id
       WHERE master_id=_id AND lang=_lang AND device=_device
       AND CASE WHEN IFNULL(_month,0) <> 0 AND IFNULL(_year,0) <> 0 THEN
       MONTH(FROM_UNIXTIME(ctime)) = _month ELSE true END
       AND CASE WHEN IFNULL(_year,0) <> 0 THEN
       YEAR(FROM_UNIXTIME(ctime)) = _year ELSE true END
       ORDER BY ctime DESC LIMIT _offset, _range;
  ELSE
    SELECT _hashtag AS hashtag, author_id, _id AS id,
       serial, ctime, firstname, lastname,lang, device, IF(serial=_active, 1, 0) AS active,
       FROM_UNIXTIME(ctime) AS created_date, status, isonline
       FROM page_history LEFT JOIN (yp.drumate)
       ON author_id=drumate.id
       WHERE master_id=_id AND lang=_lang AND device=_device
       AND CASE WHEN IFNULL(_month,0) <> 0 AND IFNULL(_year,0) <> 0 THEN
       MONTH(FROM_UNIXTIME(ctime)) = _month ELSE true END
       AND CASE WHEN IFNULL(_year,0) <> 0 THEN
       YEAR(FROM_UNIXTIME(ctime)) = _year ELSE true END
       ORDER BY ctime ASC LIMIT _offset, _range;
  END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `page_home` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `page_home`(
)
BEGIN
  DECLARE _languages VARCHAR(512);
  SELECT
    area, concat(TRIM(TRAILING '/' FROM home_dir), '/page/'), id from yp.entity where db_name=database()
  INTO @area, @root, @entity_id;
  SELECT GROUP_CONCAT(DISTINCT `base` SEPARATOR ':' ) FROM `language` WHERE `state`='active'
    INTO _languages;

  SELECT 
    @area as area, 
    @entity_id as eid, 
    @root AS page_root,
   _languages AS languages;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `page_id_get_by_lang` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `page_id_get_by_lang`(
   IN _locale       VARCHAR(100)
)
BEGIN
  SELECT master_id as page_id FROM page_history WHERE lang=_locale GROUP BY master_id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `page_index` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `page_index`(
   IN _hashtag  varchar(256),
   IN _lang  VARCHAR(6),
   IN _content  MEDIUMTEXT
)
BEGIN
   DECLARE _key  VARCHAR(25);
   SELECT CONCAT(id, '-', _lang) FROM page WHERE hashtag=_hashtag INTO _key;
   REPLACE INTO seo
     (`key`, `hashtag`, `lang`, `content`)
     VALUES(_key, _hashtag, _lang, _content);
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `page_list` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `page_list`(
  IN _page TINYINT(4),
  IN _editor VARCHAR(10),
  IN _criteria VARCHAR(16)
)
BEGIN
  DECLARE _range int(6);
  DECLARE _offset int(6);
  CALL pageToLimits(_page, _offset, _range);

  IF _criteria LIKE "D%" THEN
    SELECT
      page.id, serial, active, hashtag, `type`, `status`, `ctime`, `mtime`, `version`,
      remit, firstname, lastname
    FROM page LEFT JOIN yp.drumate on author_id=drumate.id
      WHERE editor=_editor AND (`type`='page' OR `type`= 'page')
      ORDER BY mtime DESC LIMIT _offset, _range;
  ELSE
    SELECT
      page.id, serial, active, hashtag, `type`, `status`, `ctime`, `mtime`, `version`,
      remit, firstname, lastname
    FROM page LEFT JOIN yp.drumate on author_id=drumate.id
      WHERE editor=_editor AND (`type`='page' OR `type`= 'page')
      ORDER BY mtime ASC LIMIT _offset, _range;
  END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `page_purge` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `page_purge`(
   IN _tag      varchar(400)
)
BEGIN
   DECLARE _id   VARBINARY(16) DEFAULT '';
   DECLARE _hashtag   varchar(400);

   SELECT id, hashtag FROM page WHERE id=_tag OR hashtag=_tag INTO _id, _hashtag;

   DELETE FROM page_history WHERE master_id=_id;
   DELETE FROM page WHERE id=_id;
   SELECT _id as id, _hashtag as hashtag;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `page_remove_item` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `page_remove_item`(
   IN _id      VARBINARY(16)
)
BEGIN
   DELETE FROM page WHERE id=_id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `page_remove_thread` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `page_remove_thread`(
   IN _id      VARBINARY(16)
)
BEGIN
   DELETE FROM page WHERE id=_id;
   DELETE FROM thread WHERE mester_id=_id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `page_rename` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `page_rename`(
   IN _key     VARCHAR(512),
   IN _hashtag VARCHAR(512)
)
BEGIN

   UPDATE page SET hashtag=_hashtag WHERE (id=_key OR hashtag=_key);
   SELECT
     *,
     @vhost AS vhost
   FROM page WHERE hashtag=_hashtag;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `page_rename_new` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `page_rename_new`(
   IN _id             VARCHAR(16),
   IN _hashtag        VARCHAR(512)
)
BEGIN
   DECLARE _hash_exist INT(4) DEFAULT 0;
   DECLARE _eid VARCHAR (16);

   SELECT EXISTS (SELECT id FROM page WHERE id <> _id AND hashtag = _hashtag) INTO _hash_exist;

   IF _hash_exist = 0 THEN
    UPDATE page SET hashtag=_hashtag WHERE id=_id;
    UPDATE page_history SET meta=_hashtag WHERE master_id=_id;
   END IF;
  
  SELECT id FROM yp.entity WHERE db_name = DATABASE() INTO _eid;
  CALL yp.set_homepage(_eid);   


   SELECT
      *,
      @vhost AS vhost, _hash_exist AS hash_exist
   FROM page WHERE id=_id;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `page_save` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `page_save`(
   IN _inId      VARCHAR(16),
   IN _hashtag   VARCHAR(512),
   IN _editor    VARCHAR(16),
   IN _type      VARCHAR(20),
   IN _device    VARCHAR(16),
   IN _lang      VARCHAR(20),
   IN _author_id VARBINARY(16),
   IN _vesrion   VARCHAR(16)
)
BEGIN
   DECLARE _id   VARBINARY(16) DEFAULT '';
   DECLARE _ts   INT(11) DEFAULT 0;
   DECLARE _last INT(11) DEFAULT 0;

   SELECT UNIX_TIMESTAMP() INTO _ts;

   IF CAST(_inId as CHAR(16))='0' OR _inId='0' THEN
     SELECT yp.uniqueId() INTO _id;
   ELSE
     SELECT _inId INTO _id;
   END IF;

   START TRANSACTION;

   INSERT INTO page_history (`author_id`, `master_id`, `lang`, `device`, `meta`, `ctime`)
         VALUES(_author_id, _id, _lang, _device, _hashtag, _ts);
   SELECT LAST_INSERT_ID() INTO _last;

   INSERT INTO page
     (`id`, `hashtag`, `author_id`, `editor`, `type`, `serial`, `active`, `status`, `ctime`, `mtime`, `version`)
     VALUES(_id, _hashtag, _author_id, _editor, _type, _last, _last, 'offline', _ts, _ts, _vesrion)
     ON DUPLICATE KEY UPDATE serial=_last, active=_last, mtime=_ts;

   COMMIT;

   SELECT _id as id, _last as active, _hashtag as hashtag;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `page_save_int` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `page_save_int`(
   IN _inId      VARCHAR(16),
   IN _hashtag   VARCHAR(512),
   IN _editor    VARCHAR(16),
   IN _type      VARCHAR(20),
   IN _device    VARCHAR(16),
   IN _lang      VARCHAR(20),
   IN _isonline  INT(4),
   IN _author_id VARBINARY(16),
   IN _vesrion   VARCHAR(16)
)
BEGIN
   DECLARE _id   VARBINARY(16) DEFAULT '';
   DECLARE _ts   INT(11) DEFAULT 0;
   DECLARE _last INT(11) DEFAULT 0;
   DECLARE _hash_exist INT(4) DEFAULT 0;
   DECLARE _eid VARCHAR (16);

   SELECT UNIX_TIMESTAMP() INTO _ts;

   IF CAST(_inId as CHAR(16))='0' OR _inId='0' THEN
     SELECT yp.uniqueId() INTO _id;
   ELSE
     SELECT _inId INTO _id;
   END IF;

   SELECT EXISTS (SELECT id FROM page WHERE id <> _id AND hashtag = _hashtag) INTO _hash_exist;
   IF _hash_exist = 0 THEN
    START TRANSACTION;

    INSERT INTO page_history (`author_id`, `master_id`, `lang`, `device`, `meta`, `ctime`)
        VALUES(_author_id, _id, _lang, _device, _hashtag, _ts);
    

    SELECT LAST_INSERT_ID() INTO _last;
    UPDATE page_history SET status = 'history' WHERE master_id=_id AND lang = _lang;
    UPDATE page_history SET status = 'draft' WHERE master_id=_id AND lang = _lang AND serial=_last;

    IF _isonline = 1 THEN
        UPDATE page_history SET isonline = 0 WHERE master_id=_id AND lang = _lang;
        UPDATE page_history SET isonline = 1 WHERE master_id=_id AND lang = _lang AND serial=_last;
    END IF;
    INSERT INTO page
      (`id`, `hashtag`, `author_id`, `editor`, `type`, `serial`, `active`, `status`, `ctime`, `mtime`, `version`)
      VALUES(_id, _hashtag, _author_id, _editor, _type, _last, _last, 'offline', _ts, _ts, _vesrion)
      ON DUPLICATE KEY UPDATE serial=_last, active=_last, mtime=_ts;
    
    SELECT id FROM yp.entity WHERE db_name = DATABASE() INTO _eid;
    CALL yp.set_homepage(_eid);
   
    
    COMMIT;

    SELECT _id as id, _last as active, _hashtag as hashtag, _hash_exist AS hash_exist;
   ELSE
    SELECT _id as id, _hashtag as hashtag, _hash_exist AS hash_exist;
   END IF;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `page_save_int_default_page` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `page_save_int_default_page`(
   IN _inId      VARCHAR(16),
   IN _hashtag   VARCHAR(512),
   IN _editor    VARCHAR(16),
   IN _type      VARCHAR(20),
   IN _device    VARCHAR(16),
   IN _lang      VARCHAR(20),
   IN _isonline  INT(4),
   IN _author_id VARBINARY(16),
   IN _vesrion   VARCHAR(16)
)
BEGIN
  DECLARE _id   VARCHAR(16) DEFAULT '';
  DECLARE _ts   INT(11) DEFAULT 0;
  DECLARE _last INT(11) DEFAULT 0;
  DECLARE _hash_exist INT(4) DEFAULT 0;
  DECLARE _src_path VARCHAR(512);

  SELECT UNIX_TIMESTAMP() INTO _ts;

  CALL yp.default_page(_hashtag, _lang, _src_path);

  IF CAST(_inId as CHAR(16))='0' OR _inId='0' THEN
    SELECT yp.uniqueId() INTO _id;
  ELSE
    SELECT _inId INTO _id;
  END IF;

  
  
  
  

  SELECT active FROM `page` LEFT JOIN page_history ON page_history.`serial` = `page`.`serial`  
  WHERE `hashtag` = _hashtag AND page_history.lang = _lang INTO _last;


  
  IF _last IS NULL THEN
    START TRANSACTION;

    INSERT INTO page_history (`author_id`, `master_id`, `lang`, `device`, `meta`, `ctime`)
        VALUES(_author_id, _id, _lang, _device, _hashtag, _ts);
    

    
    SELECT MAX(`serial`)+1 FROM page_history INTO _last;
    UPDATE page_history SET status = 'history' WHERE master_id=_id AND lang = _lang;
    UPDATE page_history SET status = 'draft' 
      WHERE master_id=_id AND lang = _lang AND serial=_last;

    IF _isonline = 1 THEN
      UPDATE page_history SET isonline = 0 WHERE master_id=_id AND lang = _lang;
      UPDATE page_history SET isonline = 1 WHERE master_id=_id AND lang = _lang AND serial=_last;
    END IF;
    
    
    
    

    REPLACE INTO page
      (`id`, `hashtag`, `author_id`, `editor`, `type`, `serial`, 
      `active`, `status`, `ctime`, `mtime`, `version`)
      VALUES(_id, _hashtag, _author_id, _editor, _type, _last, 
      _last, 'offline', _ts, _ts, _vesrion);

    COMMIT;

    SELECT _id as id, _lang AS lang, _last as active, 
      _hashtag as hashtag, _hash_exist AS hash_exist, _src_path AS src_path;
  ELSE
    SELECT _id as id, _lang AS lang, _hashtag as hashtag, _last AS active,
      _hash_exist AS hash_exist, _src_path AS src_path;
  END IF;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `page_save_menu` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `page_save_menu`(
   IN _device  VARCHAR(16),
   IN _lang  VARCHAR(16)
)
BEGIN
   SELECT page.id, active, hashtag, `type`, editor, status, firstname, lastname ctime, mtime, version
         FROM page LEFT JOIN yp.drumate ON author_id=drumate.id WHERE `type`=_type;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `page_search` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `page_search`(
  IN _pattern VARCHAR(84),
  IN _page TINYINT(4)
)
BEGIN

  DECLARE _range int(6);
  DECLARE _offset int(6);
  CALL pageToLimits(_page, _offset, _range);

  SELECT
    content as text,
    @vhost AS vhost,
    SUBSTRING(`key`, 1, 16) as id,
    hashtag,
    hashtag as `name`,
    MATCH(content) against(_pattern IN NATURAL LANGUAGE MODE WITH QUERY EXPANSION) as s1,
    MATCH(hashtag) against(concat('*', _pattern, '*') IN BOOLEAN MODE) as s2
  FROM seo HAVING s1 > 0 or s2 > 0 ORDER BY s2 DESC, s1 DESC LIMIT _offset, _range;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `page_status` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `page_status`(
   IN _id      VARBINARY(16),
   IN _status  VARCHAR(16)
)
BEGIN
   UPDATE page SET status=_status WHERE id=_id;
   SELECT *, tag as hashtag FROM page WHERE id=_id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `page_store` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `page_store`(
   IN _inId      VARCHAR(16),
   IN _hashtag   VARCHAR(512),
   IN _editor    VARCHAR(16),
   IN _type      VARCHAR(20),
   IN _device    VARCHAR(16),
   IN _lang      VARCHAR(20),
   IN _author_id VARBINARY(16),
   IN _vesrion   VARCHAR(16)
)
BEGIN
   DECLARE _id   VARBINARY(16) DEFAULT '';
   DECLARE _ts   INT(11) DEFAULT 0;
   DECLARE _last INT(11) DEFAULT 0;

   SELECT UNIX_TIMESTAMP() INTO _ts;

   IF CAST(_inId as CHAR(16))='0' OR _inId='0' OR _inId='' THEN
     SELECT yp.uniqueId() INTO _id;
   ELSE
     SELECT _inId INTO _id;
   END IF;

   START TRANSACTION;

   INSERT INTO page_history (`author_id`, `master_id`, `lang`, `device`, `meta`, `ctime`)
         VALUES(_author_id, _id, _lang, _device, _hashtag, _ts);
   SELECT LAST_INSERT_ID() INTO _last;

   REPLACE INTO page
     (`id`, `hashtag`, `author_id`, `editor`, `type`, `serial`, `active`, `status`, `ctime`, `mtime`, `version`)
     VALUES(_id, _hashtag, _author_id, _editor, _type, _last, _last, 'offline', _ts, _ts, _vesrion);
     

   COMMIT;

   SELECT _id as id, _last as active, _hashtag as hashtag;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `page_unpublish` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `page_unpublish`(
   IN _id           VARCHAR(512),
   IN _locale       VARCHAR(100),
   IN _device       VARCHAR(16)
)
BEGIN
   DECLARE _history_id   INT(11) DEFAULT 0;
   DECLARE _ts INT(11) DEFAULT 0;
   SELECT serial INTO _history_id FROM page_history WHERE master_id = _id AND isonline = 1 AND lang = _locale AND device = _device;
   SELECT UNIX_TIMESTAMP() INTO _ts;
   UPDATE page_history SET status = 'history', isonline = 0 WHERE master_id=_id AND lang = _locale AND device = _device;
   UPDATE page_history SET status = 'draft' WHERE serial=_history_id;
   UPDATE page SET serial=_history_id, active=_history_id,mtime=_ts WHERE id=_id;
   SELECT id, active, hashtag, _history_id AS history_id FROM page WHERE id=_id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `page_update` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `page_update`(
   IN _id      VARCHAR(16),
   IN _tag     VARCHAR(512),
   IN _author  VARCHAR(160),
   IN _lang    VARCHAR(20),
   IN _device  VARCHAR(20),
   IN _comment TEXT
)
BEGIN
   DECLARE _mtime INT(11) DEFAULT 0;
   DECLARE _url_key   VARCHAR(1000) DEFAULT '';
   SELECT UNIX_TIMESTAMP() INTO _mtime;
   UPDATE page SET hash=page_ident(_tag, _lang, _device),  tag=_tag,
     author=_author, comment=_comment, mtime=_mtime WHERE id=_id;
   SELECT
     *,
     @vhost AS vhost,
     tag as hashtag
   FROM page WHERE id=_id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `page_update_new` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `page_update_new`(
   IN _id           VARCHAR(512),
   IN _history_id   INT(11),
   IN _lang         VARCHAR(20),
   IN _isonline     INT(4)
)
BEGIN
   DECLARE _ts INT(11) DEFAULT 0;
   SELECT UNIX_TIMESTAMP() INTO _ts;
   UPDATE page_history SET status = 'history' WHERE master_id=_id AND lang = _lang;
   UPDATE page_history SET status = 'draft' WHERE master_id=_id AND lang = _lang AND serial=_history_id;

   IF _isonline = 1 THEN
      UPDATE page_history SET isonline = 0 WHERE master_id=_id AND lang = _lang;
      UPDATE page_history SET isonline = 1 WHERE master_id=_id AND lang = _lang AND serial=_history_id;
   END IF;
   
   UPDATE page SET serial=_history_id, active=_history_id,mtime=_ts WHERE id=_id;
   SELECT id, active, hashtag FROM page WHERE id=_id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `permission_grant` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `permission_grant`(
  IN _rid VARCHAR(16),
  IN _uid VARCHAR(16),
  IN _expiry_time INT(11),
  IN _permission TINYINT(4),
  IN _assign_via VARCHAR(50),
  IN _msg mediumtext
)
BEGIN

  DECLARE _ts INT(11) DEFAULT 0;
  DECLARE _tx INT(11) DEFAULT 0;
  DECLARE _owner_count TINYINT(4) DEFAULT 0;

  SELECT UNIX_TIMESTAMP() INTO _ts;
  SELECT cast(_permission as unsigned) INTO @perm;

  SELECT IF(IFNULL(_expiry_time, 0) = 0, 0,
    UNIX_TIMESTAMP(TIMESTAMPADD(HOUR,_expiry_time, FROM_UNIXTIME(_ts)))) INTO _tx;
  START TRANSACTION;
    REPLACE INTO permission
      VALUES(null, _rid, _uid, _msg, _tx, _ts, _ts, @perm,_assign_via );
      
      

  SELECT count(*) FROM permission WHERE permission=63 AND resource_id='*' INTO _owner_count;
  IF _owner_count < 1 THEN 
    ROLLBACK;
    SELECT 1 failed, "New granting would create orphaned hub" reason;
  ELSE 
    COMMIT;
    SELECT 0 failed, @perm AS permission, sys_id AS id FROM permission 
      WHERE resource_id=_rid AND entity_id=_uid;
  END IF; 
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `permission_make_owner` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `permission_make_owner`(
  IN _key VARCHAR(80)
)
BEGIN
  DECLARE _uid VARCHAR(16) DEFAULT NULL;

  SELECT id FROM yp.entity WHERE id=_key OR ident=_key INTO _uid;
  IF _uid IS NOT NULL THEN
    DELETE FROM permission WHERE permission=63 AND resource_id='*';
    CALL permission_grant('*', _uid, 0, 63, 'system', 'permission_make_owner');
  ELSE 
    SELECT 1 failed, CONCAT("Invalid user id : ",  _uid, " from key ", _key) reason;
  END IF;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `permission_revoke` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `permission_revoke`(
  IN _rid VARCHAR(16),
  IN _eid VARCHAR(16)
)
BEGIN
  DECLARE _filetype VARCHAR(160) DEFAULT NULL;
  IF _eid != '' THEN
    DELETE FROM permission WHERE resource_id=_rid AND entity_id=_eid;
    IF _eid = 'nobody' or _eid ='*' THEN
      DELETE FROM permission WHERE resource_id=_rid and assign_via= 'link';
    END IF;
    SELECT category FROM media WHERE id=_rid INTO _filetype;
    IF _filetype='schedule' THEN 
      DELETE FROM permission WHERE resource_id=_rid;
      DELETE FROM media WHERE id=_rid;
    END IF;
  ELSE
    DELETE FROM permission WHERE resource_id=_rid;
  END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `permission_set` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `permission_set`(
  IN _uid VARCHAR(16),
  IN _privilege INT(4)
)
BEGIN
  DECLARE _db_name VARCHAR(30);
  DECLARE _hub_id VARCHAR(16);

  UPDATE permission SET permission=_privilege, utime = UNIX_TIMESTAMP()
    WHERE entity_id=_uid AND resource_id='*';
  SELECT db_name FROM yp.entity WHERE id=_uid INTO _db_name;
  SELECT id FROM yp.entity WHERE db_name=DATABASE() INTO _hub_id;
  SET @s = CONCAT(
    "UPDATE `" ,_db_name,"`.permission SET permission=",_privilege, 
    ", utime = UNIX_TIMESTAMP() WHERE resource_id=", QUOTE(_hub_id));
  PREPARE stmt FROM @s;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;
 
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `poll_create` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `poll_create`(
  IN _ident VARCHAR(80),
  IN _name VARCHAR(80),
  IN _referer VARCHAR(500),
  IN _ip VARCHAR(40)
)
BEGIN

  DECLARE _now INT(11) DEFAULT 0;
  DECLARE _id VARCHAR(16);

  SELECT uniqueId(), UNIX_TIMESTAMP() into _id, _now;

  INSERT INTO
    poll VALUES(_id, _ident, _name, _now, _referer, _ip);
  SELECT * FROM poll WHERE id = _id;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `poll_get` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `poll_get`(
  IN _key VARCHAR(80)
)
BEGIN

  SELECT
    poll.id as id,
    author_id,
    ident,
    `name`,
    ctime,
    referer,
    ip,
    concat(firstname, ' ', lastname) as author
  FROM poll left join yp.drumate ON drumate.id=author_id WHERE id = _key OR ident = _key;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `poll_init` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `poll_init`(
  IN _auth_id VARCHAR(16),
  IN _ident VARCHAR(80),
  IN _name VARCHAR(80),
  IN _referer VARCHAR(500),
  IN _ip VARCHAR(40)
)
BEGIN

  DECLARE _now INT(11) DEFAULT 0;
  DECLARE _id VARCHAR(16);

  SELECT uniqueId(), UNIX_TIMESTAMP() into _id, _now;

  INSERT INTO
    poll VALUES(_id, _auth_id, _ident, _name, _now, _referer, _ip);
  SELECT
    poll.id as id,
    author_id,
    ident,
    `name`,
    ctime,
    referer,
    ip,
    concat(firstname, ' ', lastname) as author
  FROM poll left join yp.drumate ON drumate.id=author_id WHERE id = _id;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `post_forward_message_get` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `post_forward_message_get`(IN _in JSON,OUT _out JSON)
BEGIN
  DECLARE _message_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _message JSON;
  DECLARE _attachment  JSON;
 
    SELECT JSON_UNQUOTE(JSON_EXTRACT(_in, "$.message_id")) INTO _message_id;

    SELECT  attachment FROM channel WHERE message_id = _message_id  AND  attachment  <> '[]' AND  attachment IS NOT NULL INTO  _attachment ;

    SELECT  message FROM channel WHERE message_id = _message_id  AND message IS NOT NULL INTO _message  ;

    SELECT  JSON_OBJECT('forward_message_id', message_id) FROM channel WHERE message_id = _message_id  INTO  _out;

    SELECT JSON_MERGE ( _out, JSON_OBJECT( 'message', _message )) INTO _out WHERE _message IS NOT NULL;
    SELECT JSON_MERGE ( _out, JSON_OBJECT( 'attachment', _attachment )) INTO _out WHERE  _attachment IS NOT NULL;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `remove_all_members` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `remove_all_members`(
  IN _keep_id  VARCHAR(16)
)
BEGIN
  DECLARE _done INT DEFAULT 0;
  DECLARE _hub_id VARCHAR(16);
  DECLARE _drumate_db VARCHAR(40);
  DECLARE _uid VARCHAR(16);
  DECLARE _perm TINYINT(2);
  DECLARE _members CURSOR FOR SELECT entity_id, permission FROM permission WHERE entity_id != '*';
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET _done = 1; 

  SELECT id  FROM yp.entity WHERE db_name = database() INTO _hub_id;

  OPEN _members;

  WHILE NOT _done DO
    FETCH _members INTO _uid, _perm;
    IF _uid != _keep_id THEN
      

      SELECT db_name  FROM yp.entity WHERE id=_uid INTO  _drumate_db;

     IF (_drumate_db IS NOT NULL) THEN 
        SET @s = CONCAT(
          "DELETE FROM `", _drumate_db, "`.permission WHERE resource_id = ", quote(_hub_id), ";"
        );
        PREPARE stmt FROM @s;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
        SET @s = CONCAT(
          "DELETE FROM `", _drumate_db, "`.media WHERE id = ", quote(_hub_id), ";"
        );
        PREPARE stmt FROM @s;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
      END IF;

      SELECT NULL INTO _drumate_db; 
    END IF;
  END WHILE;
  CLOSE _members;
  DELETE FROM permission WHERE entity_id != _keep_id AND entity_id != '*' ;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `remove_huber` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `remove_huber`(
  IN _key  VARCHAR(80)
)
BEGIN
  DECLARE _db VARCHAR(30);
  DECLARE _hid VARBINARY(16);
  DECLARE _uid VARBINARY(16);
  SELECT id FROM yp.entity WHERE db_name=database() INTO _hid;
  SELECT db_name, id FROM yp.entity WHERE id=_key INTO _db, _uid;
  IF IFNULL(_uid, '') <> '' THEN
    SET @s = CONCAT("CALL `", _db, "`.remove_from_my_hub(", quote(_hid), ");");
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    DELETE FROM huber WHERE id = _uid;
  END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `remove_member` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `remove_member`(
  IN _key  VARCHAR(80)
)
BEGIN
  DECLARE _uid VARCHAR(16);
  DECLARE _hub_id VARCHAR(16);
  DECLARE _drumate_db VARCHAR(80);
  SELECT id  FROM yp.entity WHERE db_name = database() INTO _hub_id;
  SELECT id, db_name  FROM yp.entity WHERE id=_key INTO _uid, _drumate_db;
  
  DELETE FROM permission WHERE entity_id = _uid;
  SET @s1 = CONCAT("DELETE FROM `", _drumate_db, "`.permission ",
    " WHERE resource_id = ", quote(_hub_id), ";");
  SET @s2 = CONCAT("DELETE FROM `", _drumate_db, "`.media ",
    " WHERE id = ", quote(_hub_id), ";");
  PREPARE stmt FROM @s1;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;
  PREPARE stmt FROM @s2;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;
  SELECT _uid AS id, 0 AS permission;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `rename_trash` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `rename_trash`(
  IN _src_id VARCHAR(16),
  IN _src_entity_id VARCHAR(16),
  IN _dest_pid VARCHAR(16),
  IN _des_entity_id VARCHAR(16)
  )
BEGIN
  DECLARE _category VARCHAR(40);
  DECLARE _src_db   VARCHAR(255);
  DECLARE _des_db   VARCHAR(255);
 
  
  SELECT db_name from yp.entity WHERE id=_src_entity_id INTO _src_db;
  SELECT db_name from yp.entity WHERE id=_des_entity_id INTO _des_db;
  SELECT NULL,NULL,NULL,NULL INTO @user_filename, @nid, @parent_id,@newfilename;
    
	
    SET @sql = CONCAT(
    " SELECT  destination.user_filename ,destination.id ,destination.parent_id
          
        FROM ",_src_db,".media source
            INNER JOIN ",_des_db,".media destination ON destination.user_filename= source.user_filename
            AND source.category = destination.category AND destination.status  = 'deleted'
        WHERE 
          source.id =",QUOTE(_src_id)," AND
          destination.parent_id=",QUOTE(_dest_pid), " INTO @user_filename, @nid, @parent_id "  );
          
    PREPARE stmt FROM @sql ;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    

   IF @user_filename IS NOT NULL THEN
  
	   SET @sql = CONCAT("SELECT ", _des_db , ".unique_filename( @parent_id,  @user_filename) into @newfilename") ;  
	   PREPARE stmt FROM @sql ;
	   EXECUTE stmt;
	   DEALLOCATE PREPARE stmt;
	   SELECT @user_filename, @nid, @parent_id ,@newfilename ;
	   
	   SET @sql = CONCAT("call ",_des_db ,".mfs_rename(@nid ,@newfilename )" );
	   PREPARE stmt FROM @sql ;
	   EXECUTE stmt;
	   DEALLOCATE PREPARE stmt;
	   SELECT NULL,NULL,NULL,NULL INTO @user_filename, @nid, @parent_id,@newfilename;
   END IF ;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `rmdir` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `rmdir`(
  IN mid VARBINARY(16)
)
BEGIN
  DECLARE dirname VARCHAR(255);
  SELECT file_path FROM media  WHERE id=mid INTO dirname;
  DELETE FROM media WHERE file_path LIKE CONCAT(dirname, '/%');
  DELETE FROM media WHERE id=mid;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `rmfile` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `rmfile`(
  IN mid VARBINARY(16)
)
BEGIN
  DELETE FROM media WHERE id=mid;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `room_access_next` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `room_access_next`(
  IN _socket_id VARCHAR(64),
  IN _user_id VARCHAR(16),
  IN _room_id VARCHAR(16)
)
BEGIN
  DECLARE _privilege TINYINT(2) DEFAULT 0;
  DECLARE _avatar_id VARCHAR(16) DEFAULT NULL;
  DECLARE _screen_id VARCHAR(16) DEFAULT NULL;
  DECLARE _hub_id VARCHAR(16) DEFAULT NULL;
  DECLARE _drumate_db VARCHAR(32) DEFAULT NULL;
  DECLARE _guest_name VARCHAR(128);
  DECLARE _start_time INT(11) UNSIGNED DEFAULT 0;

  SELECT COALESCE(dr.firstname, guest_name, u.name), c.uid
    FROM yp.cookie c 
    INNER JOIN yp.socket s ON s.cookie=c.id 
    LEFT JOIN yp.drumate dr ON (dr.id=c.uid)
    LEFT JOIN yp.dmz_user u ON u.id=c.uid
    WHERE s.id = _socket_id AND c.uid!='ffffffffffffffff'
    ORDER BY LENGTH(c.id) DESC LIMIT 1  
    INTO _guest_name, _avatar_id;


  SELECT IFNULL(db_name, 'B_nobody') FROM yp.entity WHERE id=_user_id INTO _drumate_db;
  SELECT id FROM yp.entity WHERE db_name = DATABASE() INTO _hub_id;
  SELECT id FROM yp.room WHERE 
    hub_id=_hub_id AND `type`='screen' LIMIT 1 INTO _screen_id;

  SELECT DISTINCT
    r.id,
    r.id AS room_id,
    a.id AS user_id, 
    a.socket_id, 
    r.presenter_id, 
    r.ctime, 
    r.hub_id,
    _avatar_id AS avatar_id,
    _guest_name AS guest_name,
    database() AS hub_db,
    _drumate_db AS db_name,
    a.role,
    _screen_id AS screen_id,
    a.privilege AS permission,
    COALESCE(dr.email, u.email) email, 
    COALESCE(dr.firstname, _guest_name, u.name) firstname, 
    COALESCE(dr.lastname, _guest_name, u.name) lastname, 
    COALESCE(dr.fullname, _guest_name, u.name) fullname,
    r.type,
    e.server AS use_node,
    e.location AS use_location,
    e.server AS pushNode,
    e.location AS pushLocation,
    e.server AS endpointAddress,
    e.location AS endpointRoute,
    r.status
  FROM yp.room r  
    INNER JOIN room_attendee a ON a.type = r.type
    INNER JOIN yp.room_endpoint e ON e.room_id = r.id
    LEFT JOIN yp.drumate dr ON (dr.id=_user_id)
    LEFT JOIN yp.dmz_user u ON u.id=_user_id
    WHERE r.id = _room_id AND a.socket_id=_socket_id;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `room_check_next` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `room_check_next`(
  IN _socket_id VARCHAR(64),
  IN _room_id VARCHAR(16)
)
BEGIN
  DECLARE _privilege TINYINT(2) DEFAULT 0;
  DECLARE _user_id VARCHAR(16) DEFAULT NULL;
  DECLARE _avatar_id VARCHAR(16) DEFAULT NULL;
  DECLARE _screen_id VARCHAR(16) DEFAULT NULL;
  DECLARE _drumate_db VARCHAR(32) DEFAULT NULL;
  DECLARE _guest_name VARCHAR(128);
  
  SELECT permission, s.uid FROM permission p LEFT JOIN yp.socket s 
    ON s.uid=p.entity_id 
    WHERE (p.resource_id='*' OR p.resource_id=_room_id) AND s.id=_socket_id
    ORDER BY permission DESC LIMIT 1
    INTO _privilege, _user_id;

  
  
  
    
  SELECT COALESCE(dr.firstname, guest_name, u.name), c.uid
    FROM yp.cookie c 
    INNER JOIN yp.socket s ON s.cookie=c.id 
    LEFT JOIN yp.drumate dr ON (dr.id=c.uid)
    LEFT JOIN yp.dmz_user u ON u.id=c.uid
    WHERE s.id = _socket_id
    ORDER BY LENGTH(c.id) DESC LIMIT 1  
    INTO _guest_name, _avatar_id;


  SELECT IFNULL(db_name, 'B_nobody') FROM yp.entity WHERE id=_user_id INTO _drumate_db;
  SELECT DISTINCT id FROM room WHERE `type`='screen' LIMIT 1 INTO _screen_id;
  SELECT DISTINCT
    r.id,
    r.id AS room_id,
    r.user_id, 
    r.socket_id, 
    r.ctime, 
    e.id AS hub_id,
    _avatar_id AS avatar_id,
    database() AS hub_db,
    _screen_id AS screen_id,
    _drumate_db AS db_name,
    r.role,
    IF(socket_id=_socket_id, 1, 0) rank,
    _privilege AS permission,
    COALESCE(dr.email, u.email) email, 
    COALESCE(dr.firstname, _guest_name, u.name) firstname, 
    COALESCE(dr.lastname, _guest_name, u.name) lastname, 
    COALESCE(dr.fullname, _guest_name, u.name) fullname,
    r.type,
    r.status
  FROM room r  
    INNER JOIN yp.entity e ON e.db_name=database()
    LEFT JOIN yp.drumate dr ON (dr.id=_user_id)
    LEFT JOIN yp.dmz_user u ON u.id=_user_id
    WHERE r.socket_id=_socket_id AND r.id=_room_id;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `room_detail` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `room_detail`(
  IN _in JSON,
  OUT _out JSON
)
BEGIN
DECLARE _read_cnt INT ;
DECLARE _uid VARCHAR(16);
DECLARE _ref_sys_id BIGINT;
DECLARE _read_sys_id BIGINT default 0;  
DECLARE _message mediumtext;
DECLARE _metadata JSON;
DECLARE _attachment mediumtext;
DECLARE _ctime INT(11) unsigned;
 
 
  SELECT JSON_UNQUOTE(JSON_EXTRACT(_in, "$.uid")) INTO _uid;

  SELECT  ref_sys_id FROM read_channel WHERE uid = _uid INTO _read_sys_id; 

	SELECT 
	  COUNT(sys_id)
	FROM 
    channel c  WHERE  c.sys_id > _read_sys_id INTO _read_cnt ;

  

  SELECT max(sys_id) 
  FROM  channel c 
  LEFT JOIN delete_channel dc  
      ON dc.ref_sys_id = sys_id AND uid = _uid
  WHERE  ref_sys_id IS NULL INTO _ref_sys_id;

  SELECT message, attachment, ctime, metadata FROM 
    channel  WHERE sys_id = _ref_sys_id 
    INTO _message, _attachment, _ctime, _metadata;

  SELECT JSON_MERGE(IFNULL(_out,'{}'), JSON_OBJECT('read_cnt',_read_cnt )) INTO  _out;
  SELECT JSON_MERGE(IFNULL(_out,'{}'), JSON_OBJECT('message',_message ))  WHERE _message IS NOT NULL INTO  _out;
  SELECT JSON_MERGE(IFNULL(_out,'{}'), JSON_OBJECT('ctime',_ctime )) WHERE _ctime IS NOT NULL INTO  _out;
  SELECT JSON_MERGE(IFNULL(_out,'{}'), JSON_OBJECT('attachment',_attachment )) WHERE _attachment IS NOT NULL INTO  _out;
  SELECT JSON_MERGE(IFNULL(_out,'{}'), _metadata) WHERE _metadata IS NOT NULL INTO _out;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `room_get_all_peers` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `room_get_all_peers`(
    IN _socket_id VARCHAR(64)
)
BEGIN
  DECLARE _count INTEGER DEFAULT 0;
  SELECT * from room WHERE status='started' AND socket_id!=_socket_id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `room_get_next` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `room_get_next`(
  IN _device_id VARCHAR(64),
  IN _socket_id VARCHAR(64),
  IN _user_id VARCHAR(64),
  IN _room_id VARCHAR(16),
  IN _type VARCHAR(32)
)
BEGIN
  DECLARE _privilege TINYINT(2) DEFAULT 0;
  DECLARE _presenter TINYINT(4) DEFAULT 0;
  DECLARE _orphaned TINYINT(4) DEFAULT 0;
  DECLARE _hub_id VARCHAR(16) DEFAULT NULL;
  DECLARE _avatar_id VARCHAR(16) DEFAULT NULL;
  DECLARE _drumate_db VARCHAR(32) DEFAULT NULL;
  DECLARE _location VARCHAR(128) DEFAULT NULL;
  DECLARE _server VARCHAR(128) DEFAULT NULL;
  DECLARE _guest_name VARCHAR(128);
  DECLARE _email VARCHAR(128);
  DECLARE _redirect BOOLEAN;
  DECLARE _count INTEGER DEFAULT 0;
  DECLARE _org_perm TINYINT(4) DEFAULT 0b0100000;
  DECLARE _status VARCHAR(128) DEFAULT 'waiting';  
  DECLARE _role VARCHAR(128) DEFAULT 'listener';  
  DECLARE _area VARCHAR(128) DEFAULT NULL;  

  SELECT area, id FROM yp.entity WHERE db_name = DATABASE() INTO _area, _hub_id;

  IF _type = 'screen' OR _area = 'private' THEN 
    SET _org_perm = 0b0000010;
  END IF; 


  
  DELETE FROM room_attendee 
    WHERE socket_id NOT IN (SELECT id FROM yp.socket);

  DELETE FROM yp.room WHERE hub_id=_hub_id AND 
    (presenter_id NOT IN (SELECT id FROM yp.socket) OR presenter_id IS NULL);

  DELETE FROM yp.room_endpoint WHERE room_id NOT IN (SELECT id FROM yp.room);


  IF (_room_id IN('', '0')) THEN 
    SELECT NULL INTO _room_id;
  END IF;
  
  SELECT id, `status` FROM yp.room WHERE `type`=_type AND hub_id=_hub_id 
    INTO _room_id, _status;

  IF (_room_id IS NULL) THEN 
    SELECT room_id FROM room_attendee 
      WHERE `type`=_type
      LIMIT 1 INTO _room_id;
    SELECT IFNULL(_room_id, uniqueId()) INTO _room_id;
  END IF;

  SELECT user_permission(_user_id, _room_id) INTO _privilege; 

  SELECT `server`, `location` FROM yp.room_endpoint WHERE room_id=_room_id
    INTO _server, _location;

  
  
  IF(_privilege&0b0000010) THEN 
    SELECT count(*) FROM yp.room WHERE id = _room_id INTO _count;

    
    IF(_count = 0) THEN 
      IF _server IS NULL OR _location IS NULL THEN 
        SELECT s.server, s.location FROM yp.socket s WHERE s.id=_socket_id AND s.uid=_user_id
          INTO _server, _location; 
        REPLACE INTO yp.room_endpoint (`room_id`, `ctime`, `server`, `location`)
          VALUES(_room_id, UNIX_TIMESTAMP(), _server, _location);
      END IF; 
      REPLACE INTO yp.room (`hub_id`, `id`, `ctime`, `type`, `status`)
      VALUES(_hub_id, _room_id, UNIX_TIMESTAMP(), _type, 'waiting');
    END IF;
    IF(_privilege&_org_perm) THEN 
      
      SELECT count(*) FROM yp.room r 
        INNER JOIN yp.socket s ON r.presenter_id=s.id 
        INNER JOIN yp.drumate d ON s.uid=d.id 
        WHERE r.type = _type AND hub_id=_hub_id AND JSON_VALUE(`profile`, "$.connected") > 1 
        INTO _count; 
      
      
      IF(_count = 0) THEN 
        
        DELETE FROM yp.room WHERE ctime < UNIX_TIMESTAMP() 
          AND `type` = 'screen' AND hub_id =  _hub_id;
        UPDATE yp.room SET `status`='started', presenter_id=_socket_id WHERE id = _room_id;
        UPDATE yp.drumate SET `profile`=JSON_SET(`profile`, "$.connected", 2) WHERE id=_user_id;
        
        IF _type = 'screen' THEN 
          SELECT e.server, e.location FROM yp.room_endpoint e 
            INNER JOIN yp.room r ON e.room_id = r.id 
            WHERE hub_id = _hub_id AND `type` != 'screen' ORDER BY e.ctime ASC LIMIT 1
            INTO _server, _location;
          REPLACE INTO yp.room_endpoint (`room_id`, `ctime`, `server`, `location`)
            VALUES(_room_id, UNIX_TIMESTAMP(), _server, _location);
        END IF;
      END IF;

    END IF;

    SET @_role = 'listener';
    SELECT IF(presenter_id = _socket_id, 'presenter', 'listener') 
      FROM yp.room WHERE hub_id =  _hub_id AND `type` = _type
      INTO @_role;
    
    REPLACE INTO room_attendee (
      id, 
      privilege,
      device_id, 
      socket_id, 
      room_id, 
      `type`,
      ctime, 
      `role`
    )
    VALUES(
      _user_id, 
      _privilege,
      _device_id, 
      _socket_id, 
      _room_id,
      _type,
      UNIX_TIMESTAMP(), 
      @_role
    );
  END IF;
  CALL room_access_next(_socket_id, _user_id, _room_id);
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `room_invite` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `room_invite`(
  IN _id VARCHAR(16), 
  IN _user_id VARCHAR(16), 
  IN _socket_id VARCHAR(32),
  IN _type VARCHAR(32)
)
BEGIN
  INSERT INTO room (
      id, 
      user_id, 
      socket_id, 
      ctime, 
      `type`,
      `role`
    )
    VALUES(
      _id, 
      _user_id, 
      _socket_id, 
      UNIX_TIMESTAMP(), 
      _type, 
      'attendee'
    )ON DUPLICATE KEY UPDATE socket_id=_socket_id, `type`=_type;

  CALL permission_grant(_id, _user_id, 24, 3, 'no_traversal', _socket_id);
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `room_leave` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `room_leave`(
    IN _id VARCHAR(64),
    IN _socket_id VARCHAR(64)
)
BEGIN
  DELETE FROM room WHERE id=_id AND socket_id=_socket_id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `room_users` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `room_users`(
  IN _id VARCHAR(16)
)
BEGIN
  DECLARE _perm TINYINT(2);
  DECLARE _id VARCHAR(16);
  SELECT user_id AS `uid`, `role`, `type`, socket_id, email, firstname, lastname, fullname 
    FROM room r LEFT JOIN yp.drumate d ON 
    r.user_id=d.id WHERE id=_id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `seo_get` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `seo_get`(
  IN _hashtag VARCHAR(128),
  IN _lang VARCHAR(128)
)
BEGIN
  DECLARE h VARCHAR(128);
  IF _hashtag is NULL OR _hashtag='' THEN
    SELECT home_layout FROM yp.entity WHERE db_name=database() INTO h;
  ELSE
    SELECT _hashtag INTO h;
  END IF;

  SELECT * FROM `seo` WHERE lang=_lang and hashtag=h;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `seo_index` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `seo_index`(
	IN _data  JSON
)
BEGIN
  DECLARE _i INTEGER DEFAULT 0;
  WHILE _i < JSON_LENGTH(_data) DO 
    SELECT read_json_array(_data, _i) INTO @_item;
      
    INSERT INTO seo SELECT 
      null,
      UNIX_TIMESTAMP(),
      1,
      JSON_VALUE(@_item, "$.word"), 
      JSON_VALUE(@_item, "$.hub_id"), 
      JSON_VALUE(@_item, "$.nid")
      ON DUPLICATE KEY UPDATE 
        occurrence = occurrence + 1, ctime=UNIX_TIMESTAMP();
    SELECT _i + 1 INTO _i;
  END WHILE;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `seo_index_bulk` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `seo_index_bulk`(
	IN _data  mediumtext
)
BEGIN
      SET @st = _data;
      PREPARE stmt2 FROM @st;
      EXECUTE stmt2 ;           
      DEALLOCATE PREPARE stmt2;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `seo_media_check` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `seo_media_check`()
BEGIN
  DECLARE _hub_id VARCHAR(16) CHARACTER SET ascii ;
  DECLARE _home_dir VARCHAR(512);

  SELECT id ,home_dir INTO _hub_id,_home_dir from yp.entity  WHERE db_name = DATABASE();



  INSERT INTO yp.seo_factory_check (hub_id,nid,mfs_root,db_name,file_path,extension,mimetype,category)
  SELECT _hub_id, m.id,concat(_home_dir, "/__storage__/") , DATABASE(),m.file_path ,m.extension,m.mimetype,m.category 
  FROM media m
  LEFT JOIN  seo_object so on so.nid= m.id
  LEFT JOIN  yp.seo_factory_check f ON f.hub_id =_hub_id AND m.id = f.nid
  WHERE m.category NOT IN ('hub','folder','root')
  AND so.nid IS NULL AND f.nid IS NULL;
  
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `seo_register` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `seo_register`(
	IN _hub_id VARCHAR(16),
	IN _nid VARCHAR(16),
	IN _node JSON
)
BEGIN
  REPLACE INTO seo_object SELECT 
    null,
    _hub_id, 
    _nid,
    _node;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `set_member_pemission` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `set_member_pemission`(
  IN _key  VARCHAR(80),
  IN _perm  TINYINT(2)
)
BEGIN
  DECLARE _uid VARCHAR(16);
  DECLARE _hub_id VARCHAR(16);
  DECLARE _drumate_db VARCHAR(80);
  SELECT id  FROM yp.entity WHERE db_name = database() INTO _hub_id;
  SELECT id, db_name  FROM yp.entity WHERE id=_key INTO _uid, _drumate_db;
  UPDATE permission SET permission=_perm, utime=UNIX_TIMESTAMP() WHERE entity_id = _uid;
  SET @s = CONCAT("UPDATE `", _drumate_db, "`.permission SET permission=", _perm, 
    " WHERE resource_id = ", quote(_hub_id), ";");
  PREPARE stmt FROM @s;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;
  SELECT @s;
  SELECT * FROM permission WHERE entity_id = _uid;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `set_page_length` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `set_page_length`(
  IN _start int,
  IN _end int
)
BEGIN
  DECLARE _length INT DEFAULT 20;
  DECLARE _perpage INT DEFAULT 20;

  IF @rows_per_page IS NULL THEN
    SET @rows_per_page=15;
  END IF;

  SELECT (_end - _start)*@rows_per_page INTO _length;
  SET @rows_per_page=_length;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `show_all_members` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `show_all_members`(
)
BEGIN
  DECLARE _hub_id VARCHAR(16);
  SELECT id FROM yp.entity WHERE db_name=DATABASE() INTO _hub_id;

  SELECT   
    d.id,
    e.db_name AS db_name,
    _hub_id AS nid,
    permission AS privilege,
    read_json_object(d.profile, 'firstname') AS firstname,
    read_json_object(d.profile, 'lastname') AS lastname
    
  FROM permission p 
  INNER JOIN yp.drumate d ON p.entity_id=d.id 
  INNER JOIN yp.entity e ON e.id=d.id
  WHERE resource_id='*' ;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `show_contributors` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `show_contributors`(
  IN _page         INT(4)
)
BEGIN
  DECLARE _range int(6);
  DECLARE _offset int(6);
  DECLARE _count int(6);
  DECLARE _hub_id VARCHAR(16);
  DECLARE _p int(4);

  CALL pageToLimits(_page, _offset, _range);
  SELECT COUNT(*) FROM member INTO _count;
  SELECT id FROM yp.entity WHERE db_name = database() INTO _hub_id;

  SELECT 
    _page as `page`,
    drumate.id, 
    permission AS privilege,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.firstname')), ''))AS firstname,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.lastname')), '')) AS lastname,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.email')), '')) AS email,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.mobile')), '')) AS mobile,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.address')), '')) AS address,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.city.content')), IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.city')), ''))) AS city,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.country.content')), IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.country')), ''))) AS country,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.country.value')), IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.country')), ''))) AS country_code,
    expiry_time AS expiry,
    permission.ctime, 
    permission.utime, 
    _count as total
    FROM permission LEFT JOIN yp.drumate ON entity_id=drumate.id 
    WHERE entity_id != _hub_id ORDER BY permission DESC LIMIT _offset, _range;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `show_hubers` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `show_hubers`(
  IN _page TINYINT(4)
)
BEGIN

  DECLARE _hid VARBINARY(16);
  DECLARE _range bigint;
  DECLARE _offset bigint;

  SELECT id FROM yp.entity WHERE db_name=database() INTO _hid;

  CALL pageToLimits(_page, _offset, _range);
  SELECT
    _page as `page`,
    _hid as hub_id,
    entity.id,
    entity.ident,
    entity.area,
    entity.vhost,
    drumate.dmail,
    drumate.email,
    drumate.firstname,
    drumate.lastname,
    drumate.remit,
    CONCAT(firstname, ' ', lastname) as `fullname`,
    privilege
  FROM yp.entity INNER JOIN (yp.drumate, huber) ON drumate.id=entity.id AND huber.id=entity.id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `statistics_add` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `statistics_add`(
  IN _disk_usage    INT(20)
)
BEGIN
    DECLARE _last INT(11) DEFAULT 0;
    DECLARE _page_count INT(11) DEFAULT 0;
    SELECT COUNT(serial) FROM block_history WHERE status = 'draft' OR isonline = 1 INTO _page_count;
    INSERT INTO statistics VALUES (NULL, _disk_usage, _page_count, 0, UNIX_TIMESTAMP());
    SELECT LAST_INSERT_ID() INTO _last;
    SELECT * FROM statistics WHERE sys_id = _last;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `style_add` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `style_add`(
  IN _selector VARCHAR(255),
  IN _style VARCHAR(12000),
  IN _comment VARCHAR(255)
)
BEGIN
  insert into style(`selector`, `declaration`, `comment`) values(_selector, _style, _comment)
  ON DUPLICATE KEY UPDATE `selector`=_selector, `declaration`=_style, `comment`=_comment;
  SELECT * FROM style WHERE id=LAST_INSERT_ID();
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `style_create` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `style_create`(
  IN _name VARCHAR(255),
  IN _sel VARCHAR(255),
  IN _style VARCHAR(12000),
  IN _comment VARCHAR(255)
)
BEGIN

  DECLARE _className  VARCHAR(100) DEFAULT '';
  DECLARE _selector   VARCHAR(200) DEFAULT '';
  SELECT concat('cc-', yp.uniqueId()) INTO _className;
  SELECT IF(_sel IS NULL OR _sel = '', concat('.', _className), concat('.', _className, ' ', _sel))
    INTO _selector;
  INSERT INTO `style`(`name`, `class_name`, `selector`, `declaration`, `comment`)
               VALUES(_name, _className, _selector, _style, _comment)
  ON DUPLICATE KEY UPDATE `name`=_name, `selector`=_selector, `declaration`=_style, `comment`=_comment;
  SELECT * FROM `style` WHERE id=LAST_INSERT_ID();
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `style_get` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `style_get`(
  IN _id VARCHAR(16)
)
BEGIN
  SELECT * FROM `style` where id=_id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `style_get_classes` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `style_get_classes`(
)
BEGIN
  SELECT * FROM `style`;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `style_get_files` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `style_get_files`(
)
BEGIN
  SELECT id as nid FROM media  WHERE category='stylesheet' AND status='active';
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `style_list` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `style_list`(
  IN _page TINYINT(4)
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  CALL pageToLimits(_page, _offset, _range);

  SELECT * FROM `style` ORDER BY selector ASC LIMIT _offset, _range;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `style_remove` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `style_remove`(
  IN _id VARCHAR(16)
)
BEGIN
  DELETE FROM style WHERE id=_id;
  SELECT _id as id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `style_rename` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `style_rename`(
  IN _id VARCHAR(16),
  IN _name VARCHAR(255)
)
BEGIN
  UPDATE style SET `name`=_name WHERE id=_id;
  SELECT * FROM style WHERE id=_id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `style_save` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `style_save`(
  IN _id VARCHAR(16),
  IN _style VARCHAR(12000)
)
BEGIN
  UPDATE style SET declaration=_style WHERE id=_id;
  SELECT * FROM style WHERE id=_id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `style_search` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `style_search`(
  IN _str VARCHAR(100)
)
BEGIN
  SELECT * FROM `style` where selector like concat("%", _str, "%");
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `style_sheets` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `style_sheets`(
  IN _page TINYINT(4)
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  CALL pageToLimits(_page, _offset, _range);

  SELECT id AS nid, user_filename AS `filename`,  caption, metadata as outerClass
  FROM media  WHERE category='stylesheet' AND status='active' 
  ORDER BY upload_time DESC LIMIT _offset, _range;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `tag_delete` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `tag_delete`(
  IN _sys_id        INT(11) UNSIGNED
)
BEGIN
  DELETE FROM content_tag WHERE sys_id = _sys_id;
  SELECT sys_id AS `serial`, id, `language`, `type`, `status`, `name` 
  FROM content_tag ORDER BY sys_id ASC;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `tag_get_by_name` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `tag_get_by_name`(
  IN _name         VARCHAR(100),
  IN _page         INT(6)
)
BEGIN
  DECLARE _range int(6);
  DECLARE _offset int(6);
  CALL pageToLimits(_page, _offset, _range);
  SELECT 
    `id`,
    `name`, 
    `hashtag`,
    `language`,
    `description` as content,
    _page as `page`
    FROM content_tag c
    INNER JOIN `block` USING(id) 
    WHERE c.`status`='online' AND `name`=_name 
    ORDER BY c.rank ASC LIMIT _offset, _range;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `tag_list` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `tag_list`(
  IN _page         INT(6)
)
BEGIN
  DECLARE _range int(6);
  DECLARE _offset int(6);
  CALL pageToLimits(_page, _offset, _range);
  SELECT 
    `name`, 
    GROUP_CONCAT( `hashtag` SEPARATOR ' ' ) as ids,
    `description` as content,
    _page as `page`
    FROM content_tag
    INNER JOIN `block` USING(id) 
    WHERE content_tag.`status`='online' 
    GROUP BY `name`,`description` ASC LIMIT _offset, _range;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `tag_list_by_lang` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `tag_list_by_lang`(
  IN _lang         VARCHAR(100),
  IN _page         INT(6)
)
BEGIN
  DECLARE _range int(6);
  DECLARE _offset int(6);
  CALL pageToLimits(_page, _offset, _range);
  SELECT 

    `name`, 

    GROUP_CONCAT( `hashtag` SEPARATOR ' ' ) as ids,
    
    
    (
      SELECT content FROM yp.translate 
      WHERE translate.key_code=`name` AND translate.lang=_lang
    ) as content,
    _page as `page`,
    (
      SELECT group_rank FROM content_tag c1
      WHERE c1.name=c2.name limit 1
    ) AS `rank`
    FROM content_tag c2
    INNER JOIN `block` USING(id) 
    WHERE c2.`status`='online' 
    GROUP BY `name`,`description` ASC ORDER by `rank` LIMIT _offset, _range;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `tag_save` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `tag_save`(
  IN _sys_id        INT(11) UNSIGNED,
  IN _tag           VARCHAR(500),
  IN _lang          MEDIUMTEXT,
  IN _type          VARCHAR(50),
  IN _name          VARCHAR(500)
)
BEGIN
  DECLARE _row_count INT(11) UNSIGNED;
  DECLARE _id VARBINARY(16);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION, SQLWARNING
  BEGIN
    SELECT "INTERNAL_ERROR" AS error;
  END;
  IF _type = 'block' THEN
    SELECT id FROM block WHERE id=_tag OR hashtag=_tag INTO _id;
  ELSE
    SELECT _tag INTO _id;
  END IF;
  IF IFNULL(_sys_id, 0) = 0 THEN
    SET _sys_id = NULL;
    INSERT INTO content_tag (sys_id, id, `language`, `type`, `status`, `name`, ctime) VALUES
      (_sys_id, _id, _lang, _type, 'online', _name, UNIX_TIMESTAMP())
      ON DUPLICATE KEY UPDATE id = _id, `language`=_lang, `type` = _type, `status` = 'online', `name`=_name;
    SELECT LAST_INSERT_ID() INTO _sys_id;
    SELECT sys_id AS `serial`, id, `language`, `type`, `status`, `name` FROM content_tag WHERE sys_id = _sys_id;
  ELSE
    SELECT COUNT(sys_id) FROM content_tag WHERE sys_id = _sys_id AND id = _id INTO _row_count;
    IF IFNULL(_row_count, 0) = 0 THEN
      SELECT "ID_NOT_FOUND" AS error;
    ELSE
      UPDATE content_tag SET id = _id, `language`=_lang, `type` = _type,
        `status` = 'online', `name`=_name WHERE sys_id = _sys_id;
      SELECT sys_id AS `serial`, id, `language`, `type`, `status`, `name`
        FROM content_tag WHERE sys_id = _sys_id;
    END IF;
  END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `test_limit` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `test_limit`(
  IN _page int
)
BEGIN
  DECLARE total bigint;
  DECLARE _offset bigint;
  DECLARE perpage INT DEFAULT 20;
  SELECT count(*) FROM media into total;

  SELECT FLOOR(total/perpage)*_page INTO _offset;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `ticket_list` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `ticket_list`(
  IN _uid VARCHAR(16),
  IN _data JSON,
  IN _page INT(6) 
  )
BEGIN
  DECLARE _domain_id INT;
  DECLARE _is_support INT DEFAULT 0 ;
  DECLARE _length INTEGER DEFAULT 0;
  DECLARE _idx INTEGER DEFAULT 0;
  DECLARE _list JSON; 
  DECLARE _range bigint;
  DECLARE _offset bigint;
  DECLARE _read_cnt INT ;

  DECLARE _ticket_id INT;
  DECLARE _db_name VARCHAR(500);

  DECLARE _search_ticket_id INT;
  
    CALL pageToLimits(_page, _offset, _range);

    SELECT JSON_QUERY(_data, "$.status") INTO _list;
    SELECT JSON_VALUE(_data, "$.search_ticket_id") INTO _search_ticket_id;


    DROP TABLE IF EXISTS __tmp_status;
    CREATE TEMPORARY TABLE __tmp_status(
      `status` varchar(50)    
    ); 

    SELECT  JSON_LENGTH(_list)  INTO _length;

 
    WHILE _idx < _length  DO 
      INSERT INTO __tmp_status SELECT JSON_UNQUOTE(JSON_EXTRACT(_list, CONCAT("$[", _idx, "]")));
      SELECT _idx + 1 INTO _idx;
    END WHILE;


    SELECT domain_id FROM yp.privilege WHERE uid = _uid INTO _domain_id;
    SELECT 1  FROM yp.sys_conf WHERE  conf_key = 'support_domain' AND conf_value =_domain_id INTO _is_support;

    DROP TABLE IF EXISTS _show_node;
    CREATE TEMPORARY TABLE _show_node AS 
    SELECT 
      _page page,
      t.ticket_id,
      sb.db_name db_name,  
      t.ticket_id `message`,  
      t.uid,
      t.metadata,
      t.status,
      (SELECT IF(COUNT(*), 1, 0) FROM yp.socket soc WHERE soc.uid=t.uid ) is_online,
      (SELECT 
          COUNT(1)
        FROM 
          map_ticket mt 
          INNER JOIN channel c ON mt.message_id = c.message_id
          LEFT JOIN yp.read_ticket_channel rtc on rtc.ticket_id = mt.ticket_id AND rtc.uid = _uid
          WHERE mt.ticket_id = t.ticket_id  AND c.sys_id > IFNULL(rtc.ref_sys_id,0) ) room_count,
      d.firstname, d.lastname, d.fullname , o.name org_name, t.utime
    FROM 
      yp.ticket t
      INNER JOIN yp.hub h ON h.owner_id = t.uid AND `serial`= 0
      INNER JOIN yp.entity sb ON h.id = sb.id 
      INNER JOIN yp.drumate d  ON t.uid =d.id
      INNER JOIN yp.organisation o ON o.domain_id= d.domain_id
    WHERE   
      t.uid = CASE WHEN  _is_support = 1 THEN t.uid ELSE _uid END   AND 
      t.status IN (SELECT status FROM __tmp_status ) AND 
      t.ticket_id = IFNULL(_search_ticket_id,t.ticket_id)

      ORDER BY t.ticket_id DESC 
      LIMIT _offset ,_range;

    ALTER TABLE _show_node ADD `is_checked` boolean default 0 ;
    UPDATE _show_node SET is_checked = 1 WHERE db_name IS NULL;

    IF  _is_support = 1 THEN 
      SELECT ticket_id ,db_name FROM _show_node WHERE is_checked =0  LIMIT 1 INTO _ticket_id, _db_name; 
      WHILE _ticket_id IS NOT NULL DO
        UPDATE _show_node SET is_checked = 1 WHERE ticket_id = _ticket_id ; 
          SET @st = CONCAT('SELECT 
            COUNT(1)
            FROM ', _db_name ,'.map_ticket mt 
            INNER JOIN ', _db_name ,'.channel c ON mt.message_id = c.message_id
            LEFT JOIN yp.read_ticket_channel rtc on rtc.ticket_id = mt.ticket_id AND rtc.uid = ?
            WHERE mt.ticket_id = ? AND c.sys_id > IFNULL(rtc.ref_sys_id,0)
            INTO @read_cnt');
          PREPARE stamt FROM @st;
          EXECUTE stamt USING _uid , _ticket_id;
          DEALLOCATE PREPARE stamt; 

        UPDATE _show_node SET is_checked = 1 ,room_count =  @read_cnt WHERE  ticket_id = _ticket_id ; 
        SELECT NULL , NULL  INTO @read_cnt,_ticket_id;
        SELECT ticket_id ,db_name FROM _show_node WHERE is_checked =0  LIMIT 1 INTO _ticket_id, _db_name; 
      END WHILE;
    END IF;

    SELECT * FROM _show_node  ORDER BY ticket_id DESC ;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `ticket_show` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `ticket_show`(
  IN _ticket_id  int(11),
  IN _uid VARCHAR(16),
  IN _page INT(6)  
  )
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  DECLARE _ref_sys_id int(11) unsigned default 0 ;
  DECLARE _old_ref_sys_id int(11) unsigned default 0 ;
  DECLARE _hub_id VARCHAR(16);  
    CALL pageToLimits(_page, _offset, _range);


      
      
      
      
      
      
      
      
      


    SELECT last_sys_id FROM yp.ticket WHERE ticket_id = _ticket_id  INTO _ref_sys_id;
    SELECT ref_sys_id FROM yp.read_ticket_channel 
    WHERE uid = _uid AND ticket_id = _ticket_id  INTO _old_ref_sys_id;


    IF ( _ref_sys_id > IFNULL(_old_ref_sys_id,0)) THEN  
    
      UPDATE channel c INNER JOIN map_ticket mt ON mt.message_id = c.message_id
      SET  c.metadata = JSON_SET(metadata,CONCAT("$._seen_.", _uid), UNIX_TIMESTAMP())
      WHERE c.sys_id <= _ref_sys_id   AND mt.ticket_id = _ticket_id AND
      JSON_EXISTS(metadata, CONCAT("$._seen_.", _uid))= 0;

      INSERT INTO yp.read_ticket_channel(uid,ticket_id , ref_sys_id,ctime) SELECT _uid,_ticket_id,_ref_sys_id,UNIX_TIMESTAMP() 
      ON DUPLICATE KEY UPDATE ref_sys_id= _ref_sys_id , ctime =UNIX_TIMESTAMP();
    END IF; 


    SELECT id FROM yp.entity WHERE db_name= DATABASE() INTO _hub_id; 


    SELECT 
      _page as `page`,
      c.sys_id,
      t.ticket_id,
      c.author_id, 
      'ticket' message_type,   
      c.message,   
      c.message_id, 
      c.thread_id, 
      c.is_forward, 
      c.attachment, 
      CASE WHEN LTRIM(RTRIM(c.attachment))='' OR  c.attachment IS NULL THEN 0 ELSE 1 END is_attachment, 
      _hub_id hub_id,
      c.status,     
      c.ctime,   
      CASE WHEN  t.message_id = c.message_id THEN 1 ELSE 0 END  is_ticket,  
      CASE WHEN  t.message_id = c.message_id THEN t.metadata ELSE NULL END metadata,
      IFNULL(d.firstname, 'Support') firstname, 
      IFNULL(d.lastname, 'Team') lastname, 
      IFNULL(d.fullname, 'Support Team') fullname,
      CASE WHEN _old_ref_sys_id  <  c.sys_id THEN 1 ELSE 0 END is_notify,  
      CASE WHEN JSON_EXISTS(c.metadata, CONCAT("$._seen_.", _uid))= 1 THEN 1 ELSE 0 END is_readed,
      CASE WHEN JSON_LENGTH(c.metadata , '$._seen_')  >=  JSON_LENGTH(c.metadata , '$._delivered_') 
      THEN  1 ELSE 0 END is_seen
    FROM 
      yp.ticket t 
      INNER JOIN map_ticket mt ON t.ticket_id= mt.ticket_id
      INNER JOIN channel c ON mt.message_id = c.message_id
      LEFT JOIN yp.drumate d  ON c.author_id=d.id
      WHERE t.ticket_id = _ticket_id 
      ORDER BY  c.sys_id DESC 
      LIMIT _offset ,_range;


END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `ticket_unreaded` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `ticket_unreaded`(
  IN _uid VARCHAR(16)  CHARACTER SET ascii
)
BEGIN
  DECLARE _type VARCHAR(16);
  DECLARE _sys_id int(11);
  DECLARE _domain_id INT;
  DECLARE _is_support INT DEFAULT 0 ;


  SELECT domain_id FROM yp.privilege WHERE uid = _uid INTO _domain_id;
  SELECT 1  FROM yp.sys_conf WHERE  conf_key = 'support_domain' AND conf_value =_domain_id INTO _is_support;

  SELECT
     c.message_id, t.ticket_id
  FROM 
      yp.ticket t 
  LEFT JOIN yp.read_ticket_channel rtc on rtc.ticket_id = t.ticket_id AND rtc.uid = _uid
  INNER JOIN  channel c  ON t.last_sys_id  = c.sys_id
 WHERE 
      t.last_sys_id > IFNULL(rtc.ref_sys_id,0) 
      AND CASE WHEN _is_support = 1 THEN t.uid ELSE _uid END = t.uid;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `update_membership` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `update_membership`(
   IN _operation VARCHAR(20)
)
BEGIN

  DECLARE _done INT DEFAULT 0;
  DECLARE _id VARBINARY(16);
  DECLARE _hid VARBINARY(16);
  DECLARE _db_name VARCHAR(20);
  DECLARE _hubers CURSOR FOR SELECT id FROM huber;
  DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET _done = 1;


  SELECT id FROM yp.entity WHERE db_name=database() INTO _hid;

  OPEN _hubers;

  REPEAT
    FETCH _hubers INTO _id;
    SELECT db_name FROM yp.entity WHERE id=_id INTO _db_name;

    IF _operation = 'add' THEN
      
      SET @s = CONCAT("INSERT IGNORE INTO `",_db_name,"`.media (id, origin_id, file_path, user_filename, parent_id, parent_path,
        extension, mimetype, category, filesize, `geometry`, upload_time, publish_time,
        metadata, caption, `status`, approval) SELECT hub.id, owner_id, vhost, hub.name,
        (SELECT id FROM media WHERE parent_id='0' LIMIT 1), '', entity.area,
        'text/plain', 'hub', entity.space, '', UNIX_TIMESTAMP(), UNIX_TIMESTAMP(),
        '', '', 'active', 'submitted' FROM yp.hub JOIN(yp.entity) ON hub.id=entity.id
        WHERE hub.id=", quote(_hid));
    ELSEIF _operation = 'remove' THEN
      
      SET @s = CONCAT("DELETE FROM `",_db_name,"`.media WHERE id=", quote(_hid) );
    ELSE
      SET @s = "SELECT NULL";
    END IF;

    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

  UNTIL _done END REPEAT;

  CLOSE _hubers;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `update_transfer_session` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `update_transfer_session`(
  IN _nid  varchar(16),
  IN _session  varchar(64)  
)
BEGIN
 UPDATE media SET metadata=JSON_MERGE(
      IFNULL(metadata, '{}'), 
      JSON_OBJECT('session', JSON_OBJECT(_session, UNIX_TIMESTAMP()))
    )
    WHERE id=_nid;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `__dmz_test` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `__dmz_test`(
  IN _share_id VARCHAR(50),
  IN _recipient_id varchar(64) 
)
BEGIN

SET @_rid = 'aa7d749baa7d74b6';
SET @_rep = '4d8d6a2c4d8d6a3b';
SELECT * FROM permission  WHERE resource_id=_share_id;
SELECT DISTINCT  g.email, 
    s.hub_id,     
    h.name,      
    d.fullname,      
    p.permission privilege     
    FROM media m       

      INNER JOIN permission p ON m.id = p.resource_id
      INNER JOIN yp.share s ON s.permission_id=p.sys_id
      INNER JOIN yp.map_share ms ON ms.hub_id = s.hub_id
      INNER JOIN yp.member_share g on g.id =ms.recipient_id
      INNER JOIN yp.drumate d ON  s.uid=d.id 
      INNER JOIN yp.hub h ON h.id=s.hub_id

WHERE (m.id = _share_id )         
AND  ms.recipient_id = _recipient_id
AND m.status = 'active';      

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

