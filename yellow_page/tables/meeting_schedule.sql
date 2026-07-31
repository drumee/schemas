-- Global index of scheduled meetings, maintained write-through by the room
-- service (book/update/remove) so a single background worker can poll for
-- meetings whose start time has arrived WITHOUT fanning out a JSON scan across
-- every per-hub `media` table. One row per meeting node; `attendees` holds the
-- uid list to notify. `fired` guards against re-notifying the same occurrence;
-- for recurring meetings the worker advances stime/etime and resets `fired`.
-- `early_fired` is the same guard for the heads-up push sent a fixed lead time
-- before the start — tracked separately so it can't suppress the real one.
CREATE TABLE IF NOT EXISTS `meeting_schedule` (
  `id` varchar(16) NOT NULL,
  `hub_id` varchar(16) NOT NULL,
  `nid` varchar(16) NOT NULL,
  `stime` int(11) unsigned NOT NULL DEFAULT 0,
  `etime` int(11) unsigned NOT NULL DEFAULT 0,
  `created_by` varchar(16) DEFAULT NULL,
  `title` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `message` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `attendees` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT '[]' CHECK (json_valid(`attendees`)),
  `recur` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `fired` tinyint(1) NOT NULL DEFAULT 0,
  `early_fired` tinyint(1) NOT NULL DEFAULT 0,
  `ctime` int(11) unsigned DEFAULT NULL,
  `mtime` int(11) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `hub_nid` (`hub_id`,`nid`),
  KEY `due` (`fired`,`stime`),
  KEY `upcoming` (`early_fired`,`stime`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
