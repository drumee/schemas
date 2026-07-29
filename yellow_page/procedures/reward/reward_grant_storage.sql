DELIMITER $

-- =========================================================
-- reward_grant_storage
--
-- Materialise the claim-reward prize: 5 years of unlimited
-- storage, as a personal yp.quota entitlement row.
--
-- Until this existed the campaign awarded a SLOT and nothing
-- else. reward_claim_track bumped completed_count, reward.track
-- answered granted:1, and the widget told the user they had
-- claimed "5 years of unlimited storage" -- while every
-- resolver went on handing them the free 5 GB. This is the
-- write that makes the congratulations screen true.
--
-- Called from reward_claim_track on a GRANTED completion,
-- inside its GET_LOCK('reward_slot') section, so the slot and
-- the prize move together. Also called by
-- payment_clear_entitlement, which DELETEs a cancelled
-- subscriber's row and would otherwise drop a rewarded user to
-- 5 GB instead of back to their reward.
--
-- EMITS NO RESULT SET, deliberately. reward_claim_track ends in
-- a trailing SELECT and the mariadb wrapper drops extra result
-- chunks, so a SELECT here would either vanish or displace the
-- row the caller reads back.
--
-- WHAT "UNLIMITED" IS
--
-- $.unlimited is the real signal, read by media.js
-- chekcDiskLimit and by the resolvers below. $.disk is ALSO set
-- to the BIGINT sentinel, and that is not belt-and-braces for
-- its own sake: `disk` is a generated column over
-- JSON_VALUE(quota,'$.disk') and every resolver computes
-- _q_disk - used. A row carrying the flag but no $.disk would
-- read 0, then negative free space, and lock the user out of
-- their own account. The number is the failure-safe floor; the
-- flag is what anything that understands it reads.
--
-- The prize is STORAGE, not a plan upgrade. Workspace counts,
-- seats and version history stay at the free plan's values, and
-- are copied from the live yp.plan row rather than written out
-- here, so they follow the free plan if it changes.
--
-- PERSONAL ONLY
--
-- Every resolver is tenant-first: when domain_id > 1 the
-- organisation's row wins and a personal payer_id row is never
-- read. Writing one for an org member would be inert, so this
-- refuses instead -- silently, because reward.get_state has
-- already turned those users away at the gate and the only way
-- to arrive here is a stale browser that was open when the
-- user joined an org.
--
-- WHAT IT WILL NOT OVERWRITE
--
-- Only a row that does not exist, or one that is already
-- source='reward'. A user who has since bought a plan carries
-- source='stripe' and a re-armed completion must not clobber
-- paid entitlement with a free one.
--
-- THE TERM STARTS AT THE COMPLETION, NOT AT THIS CALL
--
-- period_end is reward_claim.completed_at + 5 years. Using
-- NOW() would restart the clock every time this runs, which is
-- exactly the case the re-grant path creates: cancelling a
-- subscription would silently buy five fresh years. completed_at
-- is written once and never moved (see the column comment).
--
-- INTERVAL 5 YEAR rather than +157680000 seconds, so leap years
-- are counted rather than rounded away.
-- =========================================================
DROP PROCEDURE IF EXISTS `reward_grant_storage`$
CREATE PROCEDURE `reward_grant_storage`(
  IN _uid VARCHAR(16)
)
BEGIN
  -- 2^63-1. Not a limit anybody reaches; a value the readers that predate
  -- $.unlimited already recognise (media.js:653 compares against this exact
  -- figure), so a half-deployed rollout still enforces "unlimited" correctly.
  DECLARE _unlimited BIGINT UNSIGNED DEFAULT 9223372036854775807;
  DECLARE _domain_id INT(11) UNSIGNED DEFAULT NULL;
  DECLARE _completed_at INT(11) UNSIGNED DEFAULT 0;
  DECLARE _period_end INT(11) UNSIGNED DEFAULT 0;
  DECLARE _base JSON DEFAULT NULL;
  DECLARE _quota JSON DEFAULT NULL;
  DECLARE _blocked INT DEFAULT 0;

  -- Scalar subqueries throughout rather than SELECT ... INTO: a missing row
  -- yields NULL here, where INTO raises NOT FOUND and leaves the variable
  -- silently holding whatever it had before.
  SET _domain_id = (SELECT domain_id FROM yp.drumate WHERE id = _uid LIMIT 1);

  -- No such user. Nothing to grant, and nothing to say about it.
  IF _domain_id IS NULL THEN
    SET _blocked = 1;
  END IF;

  -- DID THEY ACTUALLY WIN ONE?
  --
  -- completed_count > 0 is what "holds one of the campaign's places" means
  -- (reward_slots_used counts exactly this), so it is also what entitles the
  -- user to the prize.
  --
  -- Not a formality. reward_claim_track only calls this on an award, so from
  -- there the check is redundant -- but payment_clear_entitlement calls it for
  -- EVERY cancelling individual, to restore a reward that a subscription had
  -- overwritten. Without this, cancelling a subscription granted 5 years of
  -- unlimited storage to users who had never seen the campaign. Caught in the
  -- scratch-DB run; T9 handed the prize to a user whose only interaction with
  -- the flow was being turned away by the slot cap.
  IF _blocked = 0 AND IFNULL(
       (SELECT completed_count FROM yp.reward_claim WHERE uid = _uid LIMIT 1), 0) = 0 THEN
    SET _blocked = 1;
  END IF;

  -- Covered by an org entitlement -> the personal row would never be read.
  -- Delegated to reward_personal_eligible so this proc, reward_claim_track's
  -- award decision and the server's gate cannot drift apart -- they did once,
  -- and the result was org members burning one of the campaign's limited places
  -- for a prize this proc then refused to write.
  IF _blocked = 0 AND reward_personal_eligible(_uid) = 0 THEN
    SET _blocked = 1;
  END IF;

  -- An existing row that is not ours. Paid entitlement outranks the reward.
  IF _blocked = 0 THEN
    IF (SELECT COUNT(*) FROM yp.quota
         WHERE domain_id = _domain_id AND payer_id = _uid
           AND IFNULL(source, 'free') <> 'reward') > 0 THEN
      SET _blocked = 1;
    END IF;
  END IF;

  IF _blocked = 0 THEN
    -- The term's origin. Falls back to now for a caller that somehow gets here
    -- before completed_at is written, which is better than period_end = 5 years
    -- after the epoch -- an instantly-expired prize.
    SET _completed_at = IFNULL(
      (SELECT NULLIF(completed_at, 0) FROM yp.reward_claim WHERE uid = _uid LIMIT 1),
      UNIX_TIMESTAMP());
    SET _period_end = UNIX_TIMESTAMP(FROM_UNIXTIME(_completed_at) + INTERVAL 5 YEAR);

    -- Start from the live free plan so the non-storage entitlements track it.
    SET _base = (SELECT quota FROM yp.plan
                  WHERE plan_code = 'free' AND entity_type = 'user' AND active = 1
                  LIMIT 1);
    -- Catalog missing or deactivated: the storage keys are all this row really
    -- needs, and refusing the prize over an absent catalog row would be the
    -- wrong way to fail.
    SET _base = IFNULL(_base, JSON_OBJECT('seat', 0, 'organization', 0,
                                          'history_length', 0, 'private_hub', 1));

    SET _quota = JSON_SET(_base,
      '$.plan',      'reward-5y',
      '$.unlimited', TRUE,
      '$.disk',      _unlimited,
      '$.desk_disk', _unlimited,
      '$.hub_disk',  _unlimited);

    INSERT INTO yp.quota
      (domain_id, payer_id, plan, quota, source, period_end, ctime, mtime)
    VALUES
      (_domain_id, _uid, 'reward-5y', _quota, 'reward', _period_end,
       UNIX_TIMESTAMP(), UNIX_TIMESTAMP())
    ON DUPLICATE KEY UPDATE
      -- Reached only when the existing row is already source='reward' (anything
      -- else was refused above), so this is a refresh of our own grant, not a
      -- takeover. period_end recomputes to the same value for the same
      -- completed_at, which is what makes a repeat call a no-op.
      plan       = 'reward-5y',
      quota      = VALUES(quota),
      source     = 'reward',
      period_end = _period_end,
      mtime      = UNIX_TIMESTAMP();
  END IF;
END $

DELIMITER ;
