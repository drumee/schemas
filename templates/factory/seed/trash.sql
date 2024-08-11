
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
DROP TABLE IF EXISTS `domain`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `domain` (
  `id` int(11) NOT NULL,
  `name` varchar(1000) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `drumate`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `drumate` (
  `sys_id` int(11) NOT NULL,
  `id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `username` varchar(80) DEFAULT NULL,
  `domain_id` int(11) unsigned DEFAULT NULL,
  `remit` tinyint(4) NOT NULL DEFAULT 0,
  `fingerprint` varchar(128) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '',
  `profile` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`profile`)),
  `firstname` varchar(128) GENERATED ALWAYS AS (json_value(`profile`,'$.firstname')) VIRTUAL,
  `lastname` varchar(128) GENERATED ALWAYS AS (json_value(`profile`,'$.lastname')) VIRTUAL,
  `fullname` varchar(128) GENERATED ALWAYS AS (if(concat(ifnull(`firstname`,''),' ',ifnull(`lastname`,'')) = ' ',json_value(`profile`,'$.email'),concat(ifnull(`firstname`,''),' ',ifnull(`lastname`,'')))) VIRTUAL,
  `avatar` varchar(512) GENERATED ALWAYS AS (json_value(`profile`,'$.avatar')) VIRTUAL,
  `lang` varchar(10) GENERATED ALWAYS AS (json_value(`profile`,'$.lang')) VIRTUAL,
  `allow_search` tinyint(4) GENERATED ALWAYS AS (json_value(json_value(`profile`,'$.privacy'),'$.visibility')) VIRTUAL,
  `quota` varchar(500) GENERATED ALWAYS AS (json_value(`profile`,'$.quota')) VIRTUAL,
  `email` varchar(128) CHARACTER SET ascii COLLATE ascii_general_ci GENERATED ALWAYS AS (json_value(`profile`,'$.email')) VIRTUAL,
  `dmail` varchar(128) GENERATED ALWAYS AS (json_value(`profile`,'$.dmail')) VIRTUAL,
  `otp` varchar(50) GENERATED ALWAYS AS (ifnull(convert(json_unquote(json_extract(`profile`,'$.otp')) using utf8mb4),'0')) VIRTUAL,
  `connected` varchar(50) GENERATED ALWAYS AS (ifnull(convert(json_unquote(json_extract(`profile`,'$.connected')) using utf8mb4),'0')) VIRTUAL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `entity`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `entity` (
  `id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `ident` varchar(80) DEFAULT NULL,
  `vhost` varchar(512) DEFAULT NULL,
  `db_name` varchar(255) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `db_host` varchar(255) NOT NULL DEFAULT '',
  `fs_host` varchar(255) NOT NULL DEFAULT '',
  `home_dir` varchar(512) NOT NULL DEFAULT '',
  `home_id` varchar(16) DEFAULT NULL,
  `default_lang` varchar(12) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT 'fr',
  `home_layout` varchar(128) NOT NULL DEFAULT '',
  `homepage` varchar(1600) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '{}' COMMENT 'TO BE REMOVED',
  `overview` mediumtext DEFAULT NULL,
  `layout` mediumtext DEFAULT NULL COMMENT 'TO BE REMOVED',
  `type` enum('organization','hub','drumate','shop','blog','forum','guest','dummy') DEFAULT NULL,
  `area` enum('public','share','limited','restricted','private','personal','system','dummy','dmz-public','dmz-private','dmz','pool','pool/dmz','template') DEFAULT NULL,
  `domain` varchar(255) DEFAULT NULL,
  `area_id` varbinary(16) DEFAULT NULL,
  `dom_id` int(11) unsigned DEFAULT NULL,
  `headline` varchar(255) DEFAULT NULL,
  `status` enum('active','frozen','deleted','archived','system','locked','online','offline','hidden') DEFAULT NULL,
  `accessibility` enum('open','membership','personal') DEFAULT 'open',
  `ctime` int(11) unsigned NOT NULL,
  `mtime` int(11) unsigned NOT NULL,
  `space` float NOT NULL DEFAULT 0,
  `menu` varchar(255) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL COMMENT 'Pointer to the default menu',
  `settings` mediumtext NOT NULL,
  `icon` varchar(500) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT 'https://fonts.drumee.name/static/images/drumee/logo.png',
  `frozen_time` int(11) unsigned DEFAULT NULL,
  KEY `category` (`type`),
  KEY `ctime` (`ctime`,`mtime`),
  KEY `home_layout` (`home_layout`),
  KEY `status` (`status`),
  KEY `area_id` (`area_id`),
  KEY `default_lang` (`default_lang`),
  KEY `icon` (`icon`),
  FULLTEXT KEY `settings` (`settings`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `hub`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `hub` (
  `sys_id` int(11) NOT NULL,
  `id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `hubname` varchar(80) DEFAULT NULL,
  `domain_id` int(10) unsigned DEFAULT NULL,
  `owner_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `origin_id` varchar(16) DEFAULT NULL,
  `dmail` varchar(255) NOT NULL DEFAULT '',
  `name` varchar(80) NOT NULL,
  `serial` int(11) unsigned NOT NULL DEFAULT 0,
  `description` varchar(2000) DEFAULT NULL,
  `keywords` varchar(2000) DEFAULT NULL,
  `permission` tinyint(4) unsigned NOT NULL DEFAULT 0,
  `profile` mediumtext DEFAULT NULL,
  KEY `dmail` (`dmail`),
  KEY `default_perm` (`permission`),
  KEY `owner_id` (`owner_id`),
  KEY `origin_id` (`origin_id`),
  FULLTEXT KEY `keywords` (`name`,`keywords`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `organization`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `organization` (
  `sys_id` int(11) NOT NULL,
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
  `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`metadata`))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `privilege`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `privilege` (
  `sys_id` int(11) NOT NULL,
  `uid` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `domain_id` int(11) unsigned NOT NULL,
  `privilege` int(4) unsigned DEFAULT 0,
  `is_authoritative` tinyint(4) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `vhost`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `vhost` (
  `sys_id` int(11) NOT NULL,
  `fqdn` varchar(256) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `dom_id` int(11) unsigned DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

