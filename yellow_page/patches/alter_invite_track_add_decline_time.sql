-- =========================================================
-- Add invite_track.decline_time -- the outcome the table could
-- not record, because until now there was no way to refuse.
--
-- A workspace invitation used to have exactly two shapes. An
-- address with no account got a token and a pending_invitation
-- row and became a member by signing up; an address that
-- already had an account was granted membership on the spot by
-- hub.invite, with nothing to accept. Neither could be turned
-- down, so `accept_time IS NULL` meant "not yet" and nothing
-- else, and one nullable column carried the whole outcome.
--
-- Both branches now mint an invitation the recipient answers,
-- from the email or from the notification row, so an
-- invitation has THREE outcomes and a second column is needed
-- to tell the last two apart:
--
--   accept_time NULL, decline_time NULL   still pending
--   accept_time set                       joined
--   decline_time set                      refused
--
-- WITHOUT THIS COLUMN a refusal is indistinguishable from
-- silence, and `invites_sent - invites_accepted` -- which
-- viral_loop reports as the pending figure -- would count every
-- refusal as an invitation still waiting for an answer,
-- forever.
--
-- FIRST REFUSAL WINS, mirroring the first-acceptance-wins rule
-- in invite_track_accept: invite_track_decline only writes when
-- the column is NULL. A person invited again after refusing,
-- who refuses again, keeps the moment they first said no.
--
-- BOTH COLUMNS CAN BE SET AT ONCE, and that is not a
-- contradiction: refused in March, invited again in June,
-- joined. The row then says both things happened, which is
-- what happened. Readers that want "did they end up in" ask
-- accept_time; readers that want "was this ever refused" ask
-- decline_time. Nothing clears either one -- invite_track_mark_v2
-- keeps the table's existing gain-information-only rule.
--
-- NOT BACKFILLED. No refusal has ever been recordable, so
-- every existing row is genuinely NULL here; there is no
-- earlier signal to reconstruct one from. Unlike the
-- contact_activity.deleted_at patch there is not even a
-- tempting wrong source to guard against.
--
-- NULLABLE WITH NO DEFAULT, matching accept_time exactly, so
-- the two read the same way and neither needs a sentinel.
-- Indexed for the same reason accept_time is: viral_loop_window
-- counts rows by this column over a date window.
--
-- This table lives in yp and is shared by every user, so the
-- ALTER is a single statement against one table.
-- =========================================================

ALTER TABLE `invite_track`
  ADD COLUMN IF NOT EXISTS `decline_time` INT(11) UNSIGNED DEFAULT NULL
    COMMENT 'When the invitation was refused. NULL = never refused. First refusal wins.'
    AFTER `accept_time`,
  ADD INDEX IF NOT EXISTS `idx_decline_time` (`decline_time`);
