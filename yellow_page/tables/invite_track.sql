-- File: schemas/yellow_page/tables/invite_track.sql
-- Purpose: one row per (workspace, invited email), stamped when the invitation
--          was SENT and again when it was ACCEPTED. Feeds the analytics
--          dashboard's Engagement > Viral loop page.
--
-- WHY A TABLE AND NOT A DERIVED QUERY. Of the four figures the page reports,
-- exactly one is recoverable from data already on disk, and the interesting
-- three are not:
--
--   sent, invitee with NO account   yp.token, method 'hub_invite:<hub>'. Carries
--                                   inviter_id and ctime, so this branch alone
--                                   is derivable.
--   sent, invitee WITH an account   NOT derivable, and this is the common case
--                                   inside an organisation. hub.invite grants
--                                   membership on the spot (service/private/
--                                   hub.js, the `isDrumate` branch) and writes
--                                   nothing at all -- no token, no pending row,
--                                   not even the writeAudit its sibling branch
--                                   writes. The invitation leaves no trace.
--   accepted                        NOT derivable. yp.pending_invitation is
--                                   DELETED on acceptance, so a redeemed
--                                   invitation and one that never existed are
--                                   the same absence of a row.
--   who invited                     NOT derivable for the account branch, per
--                                   the above.
--
-- One unrecorded branch is enough to make "invite rate" unanswerable, which is
-- why this exists rather than a view over yp.token.
--
-- UNIQUE (hub_id, invitee_email) IS THE "FIRST INVITE WINS" RULE, following
-- funnel_milestone and feature_usage. Re-inviting the same address to the same
-- workspace must not inflate `invites_sent` -- otherwise the accept rate falls
-- every time somebody re-sends, which is the opposite of what a re-send means.
-- invite_track_mark is INSERT ... ON DUPLICATE KEY UPDATE and never overwrites
-- sent_time or inviter_id, so no caller can get the semantics wrong by
-- forgetting a guard, and the backfill is re-runnable. It matches the same key
-- yp.pending_invitation already uses, deliberately: two tables keyed the same
-- way cannot disagree about what "the same invitation" means.
--
-- had_account SEPARATES TWO THINGS THE PAGE MUST NOT CONFLATE. An invitation to
-- someone who already has an account is granted immediately, so its accept_time
-- equals its sent_time and it is accepted by construction. Counting those in
-- one blended accept rate reports a number close to 100% that says nothing
-- about whether invitations persuade anyone. The column lets viral_loop report
-- the blended rate AND the newcomer-only rate, and lets the page show both
-- rather than one flattering figure.
--
-- accept_time NULL MEANS STILL PENDING, not unknown. Every writer sets it
-- explicitly: the instant-grant branch stamps it equal to sent_time at INSERT,
-- and invite_track_accept stamps it at redemption. A NULL therefore always
-- means "sent, not yet redeemed" and is what `invites_sent - invites_accepted`
-- counts.
--
-- approx MARKS A BACKFILLED STAND-IN, exactly as in funnel_milestone. It is set
-- on rows recovered from yp.pending_invitation (whose created_at predates any
-- inviter attribution) and on rows inferred from a hub's own permission table
-- (which records a grant, not an invitation, and knows no inviter at all).
-- viral_loop excludes approx rows from `inviters` for that reason -- an inviter
-- that was never recorded must not be counted as one.
--
-- NO FOREIGN KEY, deliberately, following funnel_milestone, feature_usage and
-- signup_track: the row outlives the account. Deleting a user must not
-- retroactively shrink last quarter's invite rate.
--
-- COLLATIONS ARE utf8mb4_general_ci BECAUSE yp.drumate.id AND yp.hub.id BOTH
-- ARE -- verified live on 2026-08-26 against information_schema, not assumed.
-- Note that yp.membership declares the same ids varbinary(16); that table is
-- dead (zero rows on every install checked) and is NOT what this joins to.
-- Every read of this table joins drumate and entity; a collation that merely
-- coerces still costs a per-row conversion and cannot seek the index.

CREATE TABLE IF NOT EXISTS `invite_track` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `inviter_id` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL
    COMMENT 'Reference to yp.drumate.id -- who sent it. NULL only on backfilled rows whose inviter was never recorded.',
  `hub_id` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL
    COMMENT 'Reference to yp.hub.id -- the workspace invited into',
  `invitee_email` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL
    COMMENT 'Address the invitation was sent to, lowercased by the writer',
  `invitee_uid` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL
    COMMENT 'Reference to yp.drumate.id -- filled when the invitation is accepted',
  `sent_time` int(11) unsigned NOT NULL
    COMMENT 'When the invitation was FIRST sent. Never updated.',
  `accept_time` int(11) unsigned DEFAULT NULL
    COMMENT 'When it was accepted. NULL = still pending. Equals sent_time for instant grants.',
  `had_account` tinyint(1) unsigned NOT NULL DEFAULT 0
    COMMENT '1 = invitee already had an account and was granted membership on the spot',
  `source` enum('hub_invite','invite_with_roles','secure_share','backfill') NOT NULL DEFAULT 'hub_invite'
    COMMENT 'Which call site wrote the row',
  `approx` tinyint(1) unsigned NOT NULL DEFAULT 0
    COMMENT '1 = recovered by backfill, not a measured moment. Excluded from inviter counts.',
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `invitation` (`hub_id`,`invitee_email`),
  KEY `idx_inviter` (`inviter_id`),
  KEY `idx_sent_time` (`sent_time`),
  KEY `idx_accept_time` (`accept_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
COMMENT='Viral loop -- one row per workspace invitation, first send + acceptance'
