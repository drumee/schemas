CREATE TABLE `conference` (
  `room_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `socket_id` varchar(30) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `hub_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `privilege` tinyint(2) DEFAULT 0,
  `participant_id` varchar(64) GENERATED ALWAYS AS (json_value(`metadata`,'$.participant_id')) VIRTUAL,
  `type` varchar(64) GENERATED ALWAYS AS (ifnull(json_value(`metadata`,'$.type'),'meeting')) VIRTUAL,
  `area` varchar(64) GENERATED ALWAYS AS (ifnull(json_value(`metadata`,'$.area'),'dmz')) VIRTUAL,
  `firstname` varchar(164) GENERATED ALWAYS AS (json_value(`metadata`,'$.firstname')) VIRTUAL,
  `lastname` varchar(164) GENERATED ALWAYS AS (json_value(`metadata`,'$.lastname')) VIRTUAL,
  `uid` varchar(164) GENERATED ALWAYS AS (json_value(`metadata`,'$.uid')) VIRTUAL,
  `permission` tinyint(4) GENERATED ALWAYS AS (ifnull(json_value(`metadata`,'$.permission'),0)) VIRTUAL,
  `role` varchar(64) GENERATED ALWAYS AS (ifnull(json_value(`metadata`,'$.role'),'attendee')) VIRTUAL,
  `audio` tinyint(4) GENERATED ALWAYS AS (ifnull(json_value(`metadata`,'$.audio'),1)) VIRTUAL,
  `video` tinyint(4) GENERATED ALWAYS AS (ifnull(json_value(`metadata`,'$.video'),0)) VIRTUAL,
  `screen` tinyint(4) GENERATED ALWAYS AS (ifnull(json_value(`metadata`,'$.share'),0)) VIRTUAL,
  `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL DEFAULT '{}' CHECK (json_valid(`metadata`)),
  UNIQUE KEY `socket_id` (`room_id`,`socket_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
