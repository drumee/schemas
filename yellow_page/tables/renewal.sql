CREATE TABLE `renewal` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `subscription_id` varchar(30) DEFAULT NULL,
  `payment_intent_id` varchar(30) DEFAULT NULL,
  `product` varchar(30) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT 'pro',
  `plan` varchar(30) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT 'advanced',
  `period` enum('free','month','year') DEFAULT 'free',
  `recurring` int(11) DEFAULT 0,
  `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`metadata`)),
  `stime` int(11) unsigned NOT NULL,
  `next_renewal_time` int(11) unsigned NOT NULL,
  `cancel_time` int(11) unsigned DEFAULT NULL,
  `ctime` int(11) unsigned NOT NULL,
  `next_action` varchar(10) GENERATED ALWAYS AS (case when json_value(`metadata`,'$.1.on') = 1 then '1' else case when json_value(`metadata`,'$.5.on') = 1 then '5' else case when json_value(`metadata`,'$.6.on') = 1 then '6' else case when json_value(`metadata`,'$.7.on') = 1 then '7' else case when json_value(`metadata`,'$.8.on') = 1 then '8' else case when json_value(`metadata`,'$.9.on') = 1 then '9' else case when json_value(`metadata`,'$.10.on') = 1 then '10' else case when json_value(`metadata`,'$.11.on') = 1 then '11' else case when json_value(`metadata`,'$.12.on') = 1 then '12' else case when json_value(`metadata`,'$.13.on') = 1 then '13' else case when json_value(`metadata`,'$.14.on') = 1 then '14' else case when json_value(`metadata`,'$.15.on') = 1 then '15' else case when json_value(`metadata`,'$.16.on') = 1 then '16' else case when json_value(`metadata`,'$.17.on') = 1 then '17' else case when json_value(`metadata`,'$.18.on') = 1 then '18' else case when json_value(`metadata`,'$.19.on') = 1 then '19' end end end end end end end end end end end end end end end end) VIRTUAL,
  `next_action_time` varchar(10) GENERATED ALWAYS AS (case when json_value(`metadata`,'$.1.on') = 1 then json_value(`metadata`,'$.1.date') else case when json_value(`metadata`,'$.5.on') = 1 then json_value(`metadata`,'$.5.date') else case when json_value(`metadata`,'$.6.on') = 1 then json_value(`metadata`,'$.6.date') else case when json_value(`metadata`,'$.7.on') = 1 then json_value(`metadata`,'$.7.date') else case when json_value(`metadata`,'$.8.on') = 1 then json_value(`metadata`,'$.8.date') else case when json_value(`metadata`,'$.9.on') = 1 then json_value(`metadata`,'$.9.date') else case when json_value(`metadata`,'$.10.on') = 1 then json_value(`metadata`,'$.10.date') else case when json_value(`metadata`,'$.11.on') = 1 then json_value(`metadata`,'$.11.date') else case when json_value(`metadata`,'$.12.on') = 1 then json_value(`metadata`,'$.12.date') else case when json_value(`metadata`,'$.13.on') = 1 then json_value(`metadata`,'$.13.date') else case when json_value(`metadata`,'$.14.on') = 1 then json_value(`metadata`,'$.14.date') else case when json_value(`metadata`,'$.15.on') = 1 then json_value(`metadata`,'$.15.date') else case when json_value(`metadata`,'$.16.on') = 1 then json_value(`metadata`,'$.16.date') else case when json_value(`metadata`,'$.17.on') = 1 then json_value(`metadata`,'$.17.date') else case when json_value(`metadata`,'$.18.on') = 1 then json_value(`metadata`,'$.18.date') else case when json_value(`metadata`,'$.19.on') = 1 then json_value(`metadata`,'$.19.date') end end end end end end end end end end end end end end end end) VIRTUAL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `entity_id` (`entity_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
