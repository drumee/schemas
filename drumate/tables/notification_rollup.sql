-- File: schemas/drumate/tables/notification_rollup.sql
-- Per-user store holding the last known state of each notification rollup,
-- so a rollup can still be rendered after it has been read.
--
-- WHY THIS TABLE EXISTS. The chat / teamchat / media / ticket rows in the
-- notification panel are not stored events. notification_center_next
-- recomputes them on every call, and every one of its branches is an UNREAD
-- predicate -- p2p_time.ref_ctime > p2p_read.ref_ctime for chat,
-- JSON_EXISTS(metadata,'$._seen_.<uid>') = 0 for teamchat, is_new(...) = 1 for
-- media, channel.sys_id > read_ticket_channel.ref_sys_id for ticket. A rollup
-- is therefore a live count of what is unread, and once it is read the count
-- is zero and the proc emits nothing at all. There is no "read rollup" to
-- render: the concept is empty, not merely unstored.
--
-- Lexis (2026-08-28) requires those rows to stay in the panel after reading,
-- like every other notification. The only way to render something that no
-- longer exists is to have captured it WHILE it still did, which is what this
-- table is for: every time the server computes the live rollups (for the bell
-- badge, which happens on desk load, on visibility change, on reconnect and on
-- chat/mention websocket pushes -- not merely while the panel is open) it
-- upserts each one here. Reading then makes the live rollup disappear while
-- the stored copy remains, and the feed renders the stored copy as read.
--
-- Capturing at GENERATION time rather than at click time is deliberate: a user
-- who reads a conversation by opening the chat window directly, never touching
-- the panel, must still keep the row. Capturing on click would cover only the
-- panel and would make rows persist or vanish depending on HOW they were read.
--
-- BOUNDED BY CONSTRUCTION, so no retention policy is needed. The primary key
-- is one row per (user, category, key) -- per peer, per folder, per ticket --
-- and writes are upserts, so the table does not grow with message volume. A
-- user with fifty contacts and a hundred folders tops out around a hundred and
-- fifty rows for the lifetime of the account. This also matches how the panel
-- already groups: one row per peer, updated in place, never a second row.
--
-- No backfill is possible or needed: rollups that were already read before
-- this shipped were never recorded anywhere and are gone. They are equally
-- gone today, so nothing regresses -- the store simply starts filling from the
-- first badge refresh after deployment.

CREATE TABLE IF NOT EXISTS `notification_rollup` (
  `user_id` VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `category` VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL COMMENT 'chat | teamchat | media | ticket',
  `key_id` VARCHAR(255) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL COMMENT 'peer_id for chat, folder nid for teamchat, hub_id for media, ticket_id for ticket',
  `hub_id` VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `payload` JSON NOT NULL COMMENT 'the rollup row as the client received it, stored verbatim so rendering needs no second source',
  `last_id` BIGINT DEFAULT NULL,
  `ctime` INT(11) UNSIGNED NOT NULL COMMENT 'event time of the newest item in the rollup; drives feed ordering',
  `mtime` INT(11) UNSIGNED NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  `deleted` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '1 = removed by the trash button, never shown again',
  PRIMARY KEY (`user_id`, `category`, `key_id`),
  INDEX `idx_ctime` (`ctime`),
  INDEX `idx_deleted` (`deleted`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
