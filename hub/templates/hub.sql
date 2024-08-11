-- MariaDB dump 10.17  Distrib 10.4.8-MariaDB, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: template_hub
-- ------------------------------------------------------
-- Server version	10.4.8-MariaDB-1:10.4.8+maria~buster-log

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

--
-- Table structure for table `article`
--

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `comment`
--

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `share`
--

DROP TABLE IF EXISTS `share`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `share` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `id` varchar(50) NOT NULL,
  `permission_id` varchar(16) NOT NULL,
  `sender_id` varchar(16) NOT NULL,
  `recipient_id` varchar(16) NOT NULL DEFAULT 'ffffffffffffffff',
  `state` enum('new','changed') DEFAULT 'new',
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `permission_id` (`id`,`permission_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `statistics`
--

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2019-11-05 20:40:27
