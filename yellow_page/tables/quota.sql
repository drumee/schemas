-- File: schemas/yellow_page/tables/quota.sql
-- Purpose: Create quota table to handle users' quota depending on their plan
--          The default values are provided by the table group_quota
DROP TABLE IF EXISTS `quota`;
CREATE TABLE IF NOT EXISTS `quota` (
  `domain_id` int(11) unsigned DEFAULT NULL,
  `payer_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `plan` varchar(80) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT 'free',
  `seat` integer unsigned GENERATED ALWAYS AS (json_value(`quota`,'$.seat')) VIRTUAL,
  `history_length` integer unsigned GENERATED ALWAYS AS (json_value(`quota`,'$.history_length')) VIRTUAL,
  `disk` bigint unsigned GENERATED ALWAYS AS (json_value(`quota`,'$.disk')) VIRTUAL,
  `organization` integer unsigned GENERATED ALWAYS AS (json_value(`quota`,'$.organization')) VIRTUAL,
  `quota` JSON,
  PRIMARY KEY (`domain_id`),
  UNIQUE KEY `payer_id` (`payer_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

insert into quota (domain_id, payer_id, quota) select 1, 'ffffffffffffffff', JSON_OBJECT('plan','free', 'seat', 0, 'disk', 20000000000, 'organization', 0);