CREATE TABLE `reminder` (
  `id` varchar(16) NOT NULL,
  `uid` varchar(16) NOT NULL,
  `task` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT '{}' CHECK (json_valid(`task`)),
  `ctime` int(11) unsigned GENERATED ALWAYS AS (json_value(`task`,'$.ctime')) VIRTUAL,
  `mtime` int(11) unsigned GENERATED ALWAYS AS (json_value(`task`,'$.mtime')) VIRTUAL,
  `stime` int(11) unsigned GENERATED ALWAYS AS (json_value(`task`,'$.stime')) VIRTUAL,
  `etime` int(11) unsigned GENERATED ALWAYS AS (json_value(`task`,'$.etime')) VIRTUAL,
  `nid` varchar(16) GENERATED ALWAYS AS (json_value(`task`,'$.nid')) VIRTUAL,
  `hub_id` varchar(16) GENERATED ALWAYS AS (json_value(`task`,'$.hub_id')) VIRTUAL,
  `period` int(11) unsigned GENERATED ALWAYS AS (json_value(`task`,'$.period')) VIRTUAL,
  `duration` int(11) unsigned GENERATED ALWAYS AS (json_value(`task`,'$.duration')) VIRTUAL,
  `repeat` enum('once','hourly','daily','weekly','monthly','yearly','period','onload') GENERATED ALWAYS AS (json_value(`task`,'$.repeat')) VIRTUAL,
  PRIMARY KEY (`id`),
  KEY `uid` (`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
