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
-- had_account SEPARATES TWO THINGS THE PAGE MUST NOT CONFLATE: whether an
-- invitation had to persuade somebody to open an account, or merely to say yes.
-- The column lets viral_loop report the blended rate AND the newcomer-only
-- rate, and lets the page show both rather than one figure.
--
-- 🚨 ITS MEANING CHANGED, AND ROWS ON EITHER SIDE OF THAT CHANGE READ
-- DIFFERENTLY. It used to also mean "accepted by construction": hub.invite
-- granted membership on the spot to an address that already had an account, so
-- invite_track_mark stamps accept_time = sent_time whenever had_account = 1.
-- Since workspace invitations became something the recipient answers -- accept
-- or decline, from the email or the notification row -- that is no longer true,
-- and invite_track_mark_v2 leaves accept_time NULL for those rows until they
-- are really accepted.
--
-- Both procedures still exist and both are correct FOR THEIR CALLER. A server
-- that still grants on the spot calls invite_track_mark; a server that sends a
-- real invitation calls invite_track_mark_v2. So a blended accept rate spanning
-- the deploy is comparing two different questions, and rows with
-- had_account = 1 AND accept_time = sent_time are the older kind.
--
-- accept_time NULL NO LONGER MEANS PENDING ON ITS OWN -- see decline_time.
-- Pending is accept_time IS NULL AND decline_time IS NULL. Every writer sets
-- these explicitly: invite_track_accept stamps acceptance at redemption,
-- invite_track_decline stamps refusal, and neither ever clears the other.
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
    COMMENT 'When it was accepted. NULL = never accepted. Equals sent_time on rows written by invite_track_mark with had_account=1, i.e. before invitations could be refused.',
  `decline_time` int(11) unsigned DEFAULT NULL
    COMMENT 'When the invitation was refused. NULL = never refused. First refusal wins.',
  `had_account` tinyint(1) unsigned NOT NULL DEFAULT 0
    COMMENT '1 = invitee already had an account when the invitation was sent',
  `source` enum('hub_invite','invite_with_roles','secure_share','backfill','audit_invite_sent','audit_member_added') NOT NULL DEFAULT 'hub_invite'
    COMMENT 'Which call site wrote the row. The audit_* values are backfill-only and name WHICH audit action a recovered row came from: audit_invite_sent is a literal invitation, audit_member_added is a grant through _grantMembership (hub.invite existing-account branch OR add_contributors). They are kept apart so the looser of the two can be excluded later without re-running anything.',
  `approx` tinyint(1) unsigned NOT NULL DEFAULT 0
    COMMENT '1 = recovered by backfill, not a measured moment. Excluded from inviter counts.',
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `invitation` (`hub_id`,`invitee_email`),
  KEY `idx_inviter` (`inviter_id`),
  KEY `idx_sent_time` (`sent_time`),
  KEY `idx_accept_time` (`accept_time`),
  KEY `idx_decline_time` (`decline_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
COMMENT='Viral loop -- one row per workspace invitation: first send, plus its outcome'
