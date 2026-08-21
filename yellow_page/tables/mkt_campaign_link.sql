-- File: schemas/yellow_page/tables/mkt_campaign_link.sql
-- Purpose: Campaign link registry — the only sanctioned way to author a Drumee
--          campaign URL. Enforces the taxonomy at authoring time so the
--          Distribution page does not have to clean it up at query time.
--
-- WHY utm_term AND utm_content ARE NOT NULL DEFAULT '': a UNIQUE index treats
-- every NULL as distinct, so nullable columns in uni_tuple would let the same
-- link be saved unlimited times as long as content was left blank — which is
-- the commonest case and exactly the duplicate this table exists to prevent.
-- The empty string is a value; NULL is not.
--
-- ascii_general_ci on the five utm columns and on `ref`: these are compared
-- against JSON_VALUE(drumate.profile, '$.utm.*') in the Distribution procs, and
-- a collation mismatch on a cross-schema join throws ERROR 1267 — that has
-- already happened once between the reward tables and yp.
CREATE TABLE IF NOT EXISTS `mkt_campaign_link` (
  `id`            int(11) unsigned NOT NULL AUTO_INCREMENT,
  `name`          varchar(160) NOT NULL COMMENT 'human label for the registry; NOT part of the URL',
  `destination`   varchar(512) NOT NULL DEFAULT 'https://drumee.com/',
  `utm_source`    varchar(64) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `utm_medium`    varchar(64) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `utm_campaign`  varchar(64) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `utm_term`      varchar(64) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '',
  `utm_content`   varchar(64) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '',
  `ref`           varchar(64) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT ''
                  COMMENT 'partner/user referral code — a Drumee param, not a UTM',
  `owner`         varchar(64) NOT NULL DEFAULT '' COMMENT 'person accountable for the campaign',
  `created_by`    varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `archived`      tinyint(1) NOT NULL DEFAULT 0
                  COMMENT 'hidden from the default view; NEVER deleted — an archived link is still live in the wild and must keep resolving',
  `ctime`         int(11) unsigned NOT NULL,
  `mtime`         int(11) unsigned NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uni_tuple` (`utm_source`,`utm_medium`,`utm_campaign`,`utm_term`,`utm_content`),
  KEY `idx_campaign` (`utm_campaign`),
  KEY `idx_archived` (`archived`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
COMMENT='Campaign link registry — one row per authored campaign URL';
