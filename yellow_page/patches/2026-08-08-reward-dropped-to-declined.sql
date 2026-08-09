-- =========================================================
-- reward_claim.status — migrate the OLD 'dropped' to 'declined'
--
-- 'dropped' is changing meaning. It used to be the terminal
-- record of a DELIBERATE abandon: the user clicked "Drop
-- anyway" on the flow's own guard and said, out loud, that they
-- were leaving. From the exit-guard change onwards it means the
-- opposite kind of exit — the user closed the tab or refreshed
-- and never told us anything, which is why the new 'dropped' is
-- RECOVERABLE and re-opens the flow (see reward_claim_track's
-- re-ranked ladder, and reward.get_state's OPEN set).
--
-- The deliberate case keeps a terminal status of its own,
-- 'declined'.
--
-- WHY THIS PATCH EXISTS
--
-- Every row already sitting at 'dropped' was written under the
-- OLD meaning. Left alone, the proc change would silently
-- convert each of those explicit refusals into "we lost them,
-- offer it again": they would re-enter the OPEN set and be
-- walked back into a flow they had already declined, and any
-- who finished would consume one of the campaign's limited
-- slots on the strength of a "no".
--
-- So the rows are moved to the status that still means what
-- they meant when they were written. Intent is preserved
-- exactly; nothing is re-offered that was not re-offerable
-- before.
--
-- ORDER MATTERS. This runs BEFORE reward_claim_track and
-- reward_claim_emailed are patched. In the other order there is
-- a window in which a genuine, newly-accidental 'dropped' row
-- could be written by the new proc and then converted to
-- 'declined' by this patch — turning "they wandered off" into
-- "they refused", which is the one outcome this file exists to
-- prevent.
--
-- NOT RE-RUNNABLE, and deliberately not written to be. Past the
-- deploy, a 'dropped' row means an accidental exit and
-- converting it would be exactly wrong. The date in the
-- filename is the guard: this belongs to one deploy and must
-- not be replayed into a later manifest.
--
-- SCOPE, measured rather than assumed: 1 row on stage
-- (2026-08-08, out of 173 — emailed 150, failed 17, done 4,
-- dropped 1, started 1) and 0 rows on a fresh local install.
-- Small, but the whole point is that the one row belongs to a
-- real person who said no.
--
-- mtime moves because the row genuinely changed. ctime,
-- completed_count and completed_at are untouched: this is a
-- renaming of what the row already recorded, not a new event,
-- and completed_count in particular is what holds a slot.
-- =========================================================
UPDATE `reward_claim`
   SET `status` = 'declined',
       `mtime`  = UNIX_TIMESTAMP()
 WHERE `status` = 'dropped';

-- The column comment, restated for the new vocabulary. Comment-only and
-- idempotent — the type and default are unchanged, so re-running rewrites the
-- same text. Kept in the same file as the UPDATE so the two can never be
-- applied out of step with each other.
ALTER TABLE `reward_claim`
  MODIFY COLUMN `status` varchar(16) NOT NULL DEFAULT 'emailed'
  COMMENT 'emailed | failed | clicked | started | dropped | declined | missed | done';
