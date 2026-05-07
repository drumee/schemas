
DROP TABLE IF EXISTS quota;
CREATE TABLE `quota` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `domain_id` int(11) unsigned NOT NULL,
  `payer_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `plan` varchar(80) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT 'free',
  `seat` int(10) unsigned GENERATED ALWAYS AS (json_value(`quota`,'$.seat')) VIRTUAL,
  `history_length` int(10) unsigned GENERATED ALWAYS AS (json_value(`quota`,'$.history_length')) VIRTUAL,
  `disk` bigint(20) unsigned GENERATED ALWAYS AS (json_value(`quota`,'$.disk')) VIRTUAL,
  `organization` int(10) unsigned GENERATED ALWAYS AS (json_value(`quota`,'$.organization')) VIRTUAL,
  `quota` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`quota`)),
  `ctime` bigint(20) unsigned DEFAULT NULL,
  `mtime` bigint(20) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY (`domain_id`,`payer_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

INSERT INTO quota (
    domain_id,
    payer_id,
    plan,
    quota,
    ctime,
    mtime
  ) VALUES(
    1, 'ffffffffffffffff', 'free', 
    '{"plan": "free", "seat": 0, "disk": 20000000000, "organization": 0, "history_length": 0}',
    UNIX_TIMESTAMP(),
    UNIX_TIMESTAMP()
  );