-- =========================================================
-- Tier gates: task-tracker views + group-meeting duration
--
-- WHY: two features ship gated by plan for the first time.
--
--   task_views       which task-tracker views a plan may open.
--                    Comma-separated whitelist, or '*' for all.
--                    Free -> 'board,list'; every PAID tier (pro and every
--                    org tier) -> '*'.
--
--   meeting_minutes  hard cap on a GROUP meeting (yp.room.type='meeting'),
--                    in minutes. 0 means no cap.
--                    Free -> 45; every PAID tier -> 0.
--                    1:1 calls (type='connect') are NOT capped and this key
--                    says nothing about them — the server scopes the deadline
--                    to meeting rooms.
--
-- WHERE THESE LIVE: yp.plan.QUOTA, not yp.plan.FEATURES. Only `quota` is
-- copied into a live entitlement (payment_apply_entitlement) and only `quota`
-- is returned by the get_quota FUNCTION that feeds desk.get_env and hence
-- Visitor.quota() in the clients. `features` is read by payment_get_catalog
-- alone, for the pricing page, and never reaches a client — putting an
-- entitlement there would read as undefined everywhere it matters.
--
-- THE CLIENT FAILS OPEN ON A MISSING KEY, deliberately: libs/billing's
-- taskViewsAllowed() treats an absent `task_views` as "no restriction", so the
-- UI change is inert until this patch runs. That is the intended rollout order
-- — ship the client, observe no change, then turn the gate on from here. The
-- corollary is that this patch is what ACTIVATES the feature, so it must reach
-- every row that can answer for a user, not just the catalog.
--
-- FOUR PLACES HAVE TO AGREE, and missing any one of them leaves a population
-- ungated:
--
--   1. plan          the catalog. Fresh databases and future subscriptions.
--   2. quota (paid)  live entitlements are a SNAPSHOT of plan.quota taken when
--                    the plan was applied, so an existing subscriber keeps the
--                    old JSON until their next subscription event.
--   3. quota (free)  the same, for rows that say free/pro.
--   4. the FREE SENTINEL row (payer_id='ffffffffffffffff', domain_id=1) —
--                    get_quota CASE 3 falls back to it for every user with no
--                    quota row of their own, which is MOST free accounts. Skip
--                    this one and the gate simply does not exist for them.
--
-- FREE IS THE ONLY GATED TIER. Pro is a PAID plan and is deliberately NOT
-- gated: paying anything at all buys every task view and uncapped meetings.
-- (An earlier draft of this patch gated free+pro together, on the reasoning
-- that both are personal `entity_type='user'` tiers and these are
-- collaboration features. That grouped a paying customer with a free one and
-- was never the intent -- corrected here.)
--
-- DEFAULT IS PERMISSIVE for anything not named here: an unrecognised or legacy
-- plan must never be gated by accident. The 2026-07-24 rebuild rewrote
-- 'Pro'/'Drumee Plus'/'advanced' onto team, but production has drifted from
-- this repo's seed before (see the 2026-08-14 patch, which measured it), so
-- this does not assume that worked.
--
-- RE-RUNNABLE: sets absolute values, never increments.
-- =========================================================

-- ── 1. Catalog ───────────────────────────────────────────────────────────
--
-- BOTH statements are scoped to entity_type IN ('user','org') -- i.e. to real
-- PLANS. yp.plan also holds `addon` SKUs (pro_seat, team_seat, storage_100 /
-- _500 / _1000), and an addon is not a plan: it has no task views and no
-- meeting length of its own, it only contributes seat and disk quantity to
-- whichever plan it is attached to (payment_apply_entitlement reads
-- entity_type 'org' or 'user' for the entitlement JSON and never reads an
-- addon row for it). Writing these keys onto an addon would be inert but
-- misleading -- a row that looks entitled to something it can never grant.
--
-- Together the two statements cover every plan row exactly once.

-- Free: the only restricted tier.
UPDATE `plan`
   SET `quota` = JSON_SET(`quota`, '$.task_views', 'board,list',
                                   '$.meeting_minutes', 45)
 WHERE `plan_code` = 'free'
   AND `entity_type` IN ('user', 'org');

-- Every paid tier -- pro (personal) and every org tier. Named explicitly
-- rather than left absent so that a future change to the client's default
-- cannot silently gate them.
UPDATE `plan`
   SET `quota` = JSON_SET(`quota`, '$.task_views', '*',
                                   '$.meeting_minutes', 0)
 WHERE `plan_code` <> 'free'
   AND `entity_type` IN ('user', 'org');

-- ── 2. Live entitlements ─────────────────────────────────────────────────
-- Free, INCLUDING the free sentinel row: that row's $.plan is 'free', so it is
-- matched here and needs no separate statement — but it is the row most free
-- accounts actually read, so it is called out to make sure this predicate is
-- never narrowed in a way that drops it.
--
-- IFNULL(..., 'free') matters: a row with no $.plan at all is a free account,
-- and must be gated like one.
UPDATE `quota`
   SET `quota` = JSON_SET(`quota`, '$.task_views', 'board,list',
                                   '$.meeting_minutes', 45)
 WHERE LOWER(IFNULL(JSON_VALUE(`quota`, '$.plan'), 'free')) = 'free';

-- Everything else that already carries an entitlement — pro, team, business,
-- and any legacy or hand-granted name still in the wild. Permissive by
-- default: an unrecognised plan is not a reason to take features away.
UPDATE `quota`
   SET `quota` = JSON_SET(`quota`, '$.task_views', '*',
                                   '$.meeting_minutes', 0)
 WHERE LOWER(IFNULL(JSON_VALUE(`quota`, '$.plan'), 'free')) <> 'free';

-- ── 3. Belt and braces on the sentinel ───────────────────────────────────
-- If the sentinel row's $.plan is ever anything other than 'free', the second
-- statement above would have handed every quota-less account the unrestricted
-- values. Pin it by KEY, not by plan name.
UPDATE `quota`
   SET `quota` = JSON_SET(`quota`, '$.task_views', 'board,list',
                                   '$.meeting_minutes', 45)
 WHERE `payer_id` = 'ffffffffffffffff'
   AND `domain_id` = 1;
