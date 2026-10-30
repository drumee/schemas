-- File: schemas/yellow_page/tables/campaign_attribution.sql
-- Purpose: where a paid-campaign signup came from, kept per account and stamped
--          with the organisation once one exists.
--
-- FIRST TOUCH, NEVER OVERWRITTEN. The writer is INSERT IGNORE against the
-- primary key and nothing updates these columns afterwards, except org_id,
-- which is only ever set while still NULL.
--
-- A SEPARATE ROW, NOT signup_track: click ids are longer than the 64 characters
-- signup_track allows, and truncating one makes it useless.
CREATE TABLE IF NOT EXISTS `campaign_attribution` (
  `uid`          varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `org_id`       varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `offer`        varchar(32) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `utm_source`   varchar(100) DEFAULT NULL,
  `utm_medium`   varchar(100) DEFAULT NULL,
  `utm_campaign` varchar(100) DEFAULT NULL,
  `utm_content`  varchar(100) DEFAULT NULL,
  `utm_term`     varchar(100) DEFAULT NULL,
  `gclid`        varchar(512) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `li_fat_id`    varchar(512) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `fbclid`       varchar(512) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `country`      char(2) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  -- The _ga client id, so server events join the browser's GA4 user.
  `ga_client_id` varchar(64) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `ctime`        int(11) unsigned NOT NULL,
  PRIMARY KEY (`uid`),
  KEY `org_id` (`org_id`),
  KEY `offer` (`offer`, `ctime`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
