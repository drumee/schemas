-- =========================================================
-- reward_claim.status — swap 'declined'/'dropped' to
-- 'dropped'/'left'
--
-- A RENAMING, not a change of behaviour. Every rank, every
-- transition and every gate decision stays exactly as it was;
-- only the words move.
--
-- WHY
--
-- The vocabulary was inverted against the only word anyone
-- outside the schema shares: the button. It says "Drop anyway",
-- so pressing it is what a user, an admin, or anyone reading the
-- funnel calls a DROP. Recording that as 'declined' — and
-- giving the name 'dropped' to the silent refresh/tab-close exit
-- instead — meant the dashboard answered the question "why is
-- this person dropped at step 2?" with "declined", about the one
-- gesture that IS dropping.
--
--   declined -> dropped   the user pressed "Drop anyway".
--                         Terminal, as before.
--   dropped  -> left      the user went away without saying
--                         anything. Recoverable, as before.
--
-- ONE STATEMENT, AND IT HAS TO BE.
--
-- The two names SWAP, and one of the two possible orders is
-- destructive. Running 'declined' -> 'dropped' FIRST merges the
-- old 'dropped' rows into that same name, and the following
-- 'dropped' -> 'left' then carries BOTH populations to 'left' --
-- verified on a scratch DB, where it collapsed two rows that
-- meant opposite things into one status. Nothing can undo it
-- afterwards: the rows no longer differ in any column.
--
-- The other order ('dropped' -> 'left' first) does happen to
-- work. It is still not what this file does, because its
-- correctness rests entirely on two statements staying in the
-- right order forever -- through edits, merges, and anyone who
-- reasonably assumes two UPDATEs in one patch commute.
--
-- A single UPDATE with CASE removes the question: every row is
-- evaluated against the value it held when the statement began,
-- so the swap is simultaneous and no order exists to get wrong.
--
-- NOT RE-RUNNABLE. Running it twice sends 'dropped' back to
-- 'left' and 'left' on to nothing, which is the collapse above
-- with extra steps. The date in the filename is the guard: this
-- belongs to one deploy.
--
-- ORDER: apply BEFORE reward_claim_track and
-- reward_claim_emailed. Between this patch and those, the procs
-- still rank the OLD names, so a post lands with rank 0 and
-- loses every comparison -- the row simply does not move, which
-- is the safe way to be caught mid-deploy.
--
-- SCOPE, measured on stage 2026-08-08: 1 'declined' row and 1
-- 'dropped' row, out of 174. Small, but both belong to real
-- people and they mean opposite things.
-- =========================================================
UPDATE `reward_claim`
   SET `status` = CASE `status`
                    WHEN 'declined' THEN 'dropped'
                    WHEN 'dropped'  THEN 'left'
                  END,
       `mtime`  = UNIX_TIMESTAMP()
 WHERE `status` IN ('declined', 'dropped');

-- The column comment, restated for the new vocabulary. Comment-only and
-- idempotent — the type and default are unchanged.
ALTER TABLE `reward_claim`
  MODIFY COLUMN `status` varchar(16) NOT NULL DEFAULT 'emailed'
  COMMENT 'emailed | failed | clicked | started | left | dropped | missed | done';
