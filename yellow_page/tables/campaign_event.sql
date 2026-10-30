-- File: schemas/yellow_page/tables/campaign_event.sql
-- Purpose: outbox of campaign funnel events bound for GA4.
--
-- slot = '' makes an event once-per-account through the unique key. Events that
-- must record every occurrence (card_failed_1usd) pass the Stripe event id.
--
-- An outbox because the payment path must never wait on, or fail with, Google.
-- campaignEventWorker sends rows with sent_time IS NULL and retries them.
CREATE TABLE IF NOT EXISTS `campaign_event` (
  `id`         bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `uid`        varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `event`      varchar(40) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `slot`       varchar(64) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '',
  `plan`       varchar(32) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `ctime`      int(11) unsigned NOT NULL,
  `sent_time`  int(11) unsigned DEFAULT NULL,
  `attempts`   smallint(5) unsigned NOT NULL DEFAULT 0,
  `last_error` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uni_event` (`uid`, `event`, `slot`),
  KEY `pending` (`sent_time`, `attempts`),
  KEY `event_ctime` (`event`, `ctime`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
