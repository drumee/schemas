-- File: schemas/patches/invite_track_backfill.sql
-- Purpose: seed yp.invite_track with the invitation history that IS
--          recoverable, so the Viral loop page does not open reading zero on
--          an install that has been sending invitations for two years.
--
-- RE-RUNNABLE, AND SAFE IN THE MANIFEST. Every statement is INSERT IGNORE
-- against the UNIQUE (hub_id, invitee_email) key, so a second run adds
-- nothing and overwrites nothing. This is the funnel_backfill.sql contract,
-- NOT the feature_usage_backfill.sql one: that file writes absolute counters
-- with ON DUPLICATE KEY UPDATE and would reset live totals if it were ever
-- replayed, which is why it is banned from the manifest. Nothing here carries
-- a counter, so the same treatment is safe and this file IS listed.
--
-- ORDER MATTERS. The three sources are inserted best-attributed first, because
-- INSERT IGNORE means the FIRST row to claim a (hub, email) pair wins:
--
--   1. yp.token          exact. inviter_id and ctime are real, recorded at
--                        send time by _addInviteToken. approx = 0.
--   2. pending_invitation created_at is real but there is no inviter column,
--                        so these are approx = 1 and contribute to `sent`
--                        without contributing to `inviters`.
--   3. hub permission    a grant, not an invitation. No inviter, no send
--                        moment. approx = 1. Handled by the crawl in
--                        workspace_members_backfill.sql, not here -- see below.
--
-- Running them in the other order would let a pending row with no inviter mask
-- a token row that knows exactly who sent it.
--
-- WHAT CANNOT BE RECOVERED, and it is the interesting half. An invitation to
-- somebody who ALREADY HAD AN ACCOUNT left no trace anywhere: hub.invite's
-- isDrumate branch granted membership and wrote no token, no pending row, and
-- no audit entry. Those invitations are not in this backfill and cannot be put
-- there by any query -- a permission row proves the person has access, never
-- that they were invited, by whom, or when. viral_loop reports `approx_rows`
-- and the page says so, the same way Core function said it about chat and
-- task. Do not try to infer them from permission.ctime: that is the grant, and
-- treating grants as invitations would count every workspace's own owner as
-- somebody who accepted an invitation.
--
-- THE HAZARD IS A PRUNED SOURCE, not double-counting. yp.token rows are
-- expired and cleaned; run this as early as practical, before any retention
-- job trims them, or the recoverable history is smaller than it needed to be.
-- =========================================================================

-- ---------------------------------------------------------------
-- 1. Exact rows -- from yp.token, written by hub._addInviteToken.
--
-- method is 'hub_invite:<hub_id>', so the workspace is the part after the
-- colon; metadata.$.hub_id carries the same value and is used as the fallback
-- for any row whose method was truncated.
--
-- accept_time is derived, not stored: the token's own `status` is not reliably
-- flipped on redemption, but a drumate now existing at that address IS the
-- redemption. entity.ctime is when that account was created, which for an
-- invited newcomer is the moment they accepted.
-- ---------------------------------------------------------------
INSERT IGNORE INTO invite_track
  (inviter_id, hub_id, invitee_email, invitee_uid,
   sent_time, accept_time, had_account, source, approx)
SELECT
  t.inviter_id,
  IFNULL(NULLIF(SUBSTRING_INDEX(t.method, ':', -1), ''),
         JSON_VALUE(t.metadata, '$.hub_id'))              AS hub_id,
  LOWER(TRIM(t.email))                                    AS invitee_email,
  d.id                                                    AS invitee_uid,
  t.ctime                                                 AS sent_time,
  -- Accepted only if the account exists AND was created at or after the
  -- invitation. An older account at the same address was never a redemption
  -- of THIS invitation -- it was already there.
  IF(d.id IS NOT NULL AND e.ctime >= t.ctime, e.ctime, NULL) AS accept_time,
  0                                                       AS had_account,
  'backfill'                                              AS source,
  0                                                       AS approx
FROM token t
  LEFT JOIN drumate d ON LOWER(TRIM(d.email)) = LOWER(TRIM(t.email))
  LEFT JOIN entity  e ON e.id = d.id
WHERE t.method LIKE 'hub_invite:%'
  AND t.email IS NOT NULL
  AND TRIM(t.email) <> ''
  AND t.ctime IS NOT NULL;

-- ---------------------------------------------------------------
-- 2. Approximate rows -- from yp.pending_invitation.
--
-- These are invitations still outstanding: the table's rows are DELETED on
-- redemption, so anything left here is by definition unaccepted, and
-- accept_time is NULL rather than derived.
--
-- No inviter column exists, so inviter_id is NULL and approx = 1. viral_loop
-- counts these in `invites_sent` but excludes them from `inviters` -- an
-- inviter that was never recorded must not become a counted one.
--
-- Rows already claimed by step 1 are skipped by INSERT IGNORE, which is the
-- intent: a token row for the same pair knows more than this one does.
-- ---------------------------------------------------------------
INSERT IGNORE INTO invite_track
  (inviter_id, hub_id, invitee_email, invitee_uid,
   sent_time, accept_time, had_account, source, approx)
SELECT
  NULL,
  p.hub_id,
  LOWER(TRIM(p.email)),
  NULL,
  -- created_at defaults to 0 on rows written before the column was added;
  -- fall back to the invitation's own expiry minus the 7-day window
  -- hub.invite uses, which is the only other timestamp the row carries.
  IF(p.created_at > 0, p.created_at, GREATEST(p.expiry_time - (7 * 86400), 0)),
  NULL,
  0,
  'backfill',
  1
FROM pending_invitation p
WHERE p.email IS NOT NULL
  AND TRIM(p.email) <> ''
  AND p.hub_id IS NOT NULL;
