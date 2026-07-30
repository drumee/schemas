# Reward campaign — grant 5 years of unlimited storage

Date: 2026-07-29
Status: approved

## Problem

The claim-reward campaign awards a *slot* but never the *prize*.

`reward_claim_track` bumps `reward_claim.completed_count` under `GET_LOCK('reward_slot')`,
`reward.track` answers `granted: 1`, and the widget shows a congratulations screen reading
**"5 years of unlimited storage!"** (ui-team `builtins/widget/reward-flow/skeleton/modal.js`).

Nothing anywhere writes to `yp.quota`. A user who completes the flow consumes one of the
campaign's 100 slots and receives a 5 GB free allowance, exactly as before.

This work closes the gap between what the campaign promises and what it delivers.

## Decisions

| # | Decision | Chosen |
|---|----------|--------|
| 1 | How "unlimited" is encoded | Explicit `$.unlimited` flag in the quota JSON |
| 2 | Interaction with org entitlements | Personal-only; org-covered users gated out before Step 1 |
| 3 | How the 5-year term ends | Read-time check, scoped to `source = 'reward'` |
| 4 | Users who already completed | Backfilled, dated from their own completion |
| 5 | Where the grant executes | New proc `reward_grant_storage`, CALLed inside `reward_claim_track` |

## Changed during implementation

Three things the design did not anticipate, all found by the scratch-DB run.

**`reward_claim.completed_at` is a new column.** The term has to start at the
completion, and `mtime` cannot carry that: it moves on every track post and
`reward_claim_emailed` bumps it again on a re-arm, so a user mailed a second wave
would have their five years silently restarted from the date of the mail. Added by
`2026-07-29-reward-claim-completed-at.sql`, written once and never moved.

**Eligibility became one function, `reward_personal_eligible`.** The design put the
org check in the gate and again in the grant. Those are two copies of one rule and they
immediately disagreed: the grant refused an org member while `reward_claim_track`
awarded the slot anyway, so an ineligible user burned one of the campaign's 100 places
and got nothing — permanently, since `reward_slots_used` counts `completed_count`. The
function is now the single source for all three callers, and the award refuses too.

**`reward_grant_storage` requires `completed_count > 0`.** The design had it check only
org-coverage and existing rows. But `payment_clear_entitlement` calls it for every
cancelling individual, so as written, **cancelling a subscription granted 5 years of
unlimited storage to users who had never seen the campaign.** Caught by test T9, which
handed the prize to a user whose only contact with the flow was being turned away by the
slot cap.

## Deployed schema, not the repo's

`yellow_page/tables/quota.sql` is stale. It declares `PRIMARY KEY (domain_id)` and
`UNIQUE (payer_id)`, with no `id`, `ctime`, `mtime`, `source` or `period_end` — which would
make it impossible for two users to hold rows in domain 1, and would break
`payment_apply_entitlement`, which already inserts `ctime`/`mtime`.

The factory seed captured from a real installation
(`templates/factory/seed/yp.sql:25113`) shows what is actually deployed:

```sql
CREATE TABLE `quota` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `domain_id` int(11) unsigned NOT NULL,
  `payer_id` varchar(16) ...,
  `plan` varchar(80) ...,
  `seat`, `history_length`, `disk`, `organization`,   -- VIRTUAL, over the JSON
  `quota` longtext CHECK (json_valid(`quota`)),
  `ctime` bigint(20) unsigned, `mtime` bigint(20) unsigned,
  `source` varchar(16) DEFAULT 'free',
  `period_end` int(11) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `domain_id` (`domain_id`,`payer_id`)
)
```

Everything below targets that shape. `UNIQUE(domain_id, payer_id)` is what makes many
personal rows in domain 1 legal, and it is the key every upsert here collides on.
`quota.sql` is reconciled with it as part of this work.

## Data model

One `yp.quota` row per rewarded user. No schema change.

| Column | Value |
|---|---|
| `domain_id` | the user's `drumate.domain_id` (the gate guarantees `1`) |
| `payer_id` | `uid` |
| `plan` | `reward-5y` |
| `source` | `reward` — the discriminator every new check keys on |
| `period_end` | `UNIX_TIMESTAMP(NOW() + INTERVAL 5 YEAR)` |
| `quota` | the free plan's JSON with the storage keys lifted |

```json
{ "plan": "reward-5y", "unlimited": true,
  "disk": 9223372036854775807,
  "desk_disk": 9223372036854775807,
  "hub_disk": 9223372036854775807,
  "seat": 0, "organization": 0, "history_length": 0,
  "private_hub": 1, "share_hub": 0, "public_hub": 0 }
```

**The prize is storage, not a plan upgrade.** Workspace counts, seats and version history
stay at the free plan's values, and are copied from the live `yp.plan` row rather than
hardcoded, so they track future free-plan changes.

**`$.disk` still carries a huge number even though `$.unlimited` is the real signal.**
`disk` is a generated column over `json_value(quota,'$.disk')`, and every resolver computes
`_q_disk - used`. If only the flag were set and one reader were missed, `$.disk` would be
NULL, then 0, then negative free space — locking the user out of their own account. The
number is the failure-safe floor; the flag is what enforcement and the UI read.

`period_end` is `DEFAULT NULL` in the deployed schema, so NULL counts as "no expiry"
alongside 0 in every guard. Without that, every Stripe and free row would read as expired.

## Grant path

New file `yellow_page/procedures/reward/reward_grant_storage.sql` — one routine,
**emitting no result set**: `reward_claim_track` already ends in a trailing `SELECT` and the
mariadb wrapper drops extra result chunks.

Called from `reward_claim_track`, when `_eff = 'done'`, inside the existing
`GET_LOCK('reward_slot')` section, so slot and prize move together:

```sql
IF _eff = 'done' THEN
  CALL reward_grant_storage(_uid);
END IF;
```

`reward_claim_track`'s signature is unchanged — `(uid, campaign, status, step)` — so this
ships as a schema patch with no server deploy. That is the property that proc's own comments
were written to protect: making the limit a parameter once coupled it to a server deploy and
broke every runtime still on the previous build.

`reward_grant_storage` is `INSERT ... ON DUPLICATE KEY UPDATE` on `(domain_id, payer_id)`,
guarded to **only ever create a row or update one whose `source = 'reward'`**. A user who has
since bought a plan carries `source = 'stripe'`; a re-armed completion must not clobber it.

It re-checks the org-eligibility rule itself and writes nothing if it fails, so a stale open
browser cannot slip past the gate.

### Interaction with Stripe

If a rewarded user later subscribes, `payment_apply_entitlement` overwrites the row — correct,
paid outranks a reward. But `payment_clear_entitlement` *deletes* on cancel, which would drop
them to 5 GB rather than back to their reward.

`reward_claim.completed_count` and `mtime` are the durable record, so the grant is
re-materialisable. `payment_clear_entitlement` gains a single `CALL reward_grant_storage` at
the end, re-granting the remainder of the original term (`period_end` is recomputed from the
completion date, not from the cancel date, so cancelling does not extend the prize).

## Eligibility gate

Every resolver is **tenant-first**: when `domain_id > 1` the organisation's row wins and a
personal `payer_id = uid` row is never read. A reward written for an org member would be
silently inert.

`reward.get_state` therefore gains one condition:

```js
eligible = OPEN.has(row.status) && !(await this._underOrgEntitlement())
```

resolved in SQL as *"`drumate.domain_id > 1` and a `yp.quota` row exists for that domain keyed
by the organisation"* — the same `INNER JOIN yp.organisation` test `disk_limit` already uses,
so the gate and the resolver agree by construction rather than by two teams remembering the
same rule.

Checked at the **gate**, before Step 1, following the precedent set by `capped`: the flow
refuses to walk someone through three steps to hand them nothing.

## Read paths

All four SQL resolvers get the same guard on their personal-row tier:

```sql
WHERE payer_id = _uid
  AND (source <> 'reward' OR period_end IS NULL
       OR period_end = 0 OR period_end > UNIX_TIMESTAMP())
```

| File | Change |
|---|---|
| `directory/get_quota.sql` | guard in both routines; the PROCEDURE selects named columns so it must also emit `unlimited` (the FUNCTION returns whole JSON and carries it already) |
| `utils/disk_limit.sql` | guard; emit `unlimited`; return a large positive `available_disk` rather than `BIGINT_MAX - used` |
| `utils/disk_free.sql` | guard; return a large positive when unlimited |
| `directory/my_disk_limit.sql` | guard; emit `unlimited` |

`disk_free` needs care: it is **personal-first** while the other three are tenant-first. With
personal-only rewards that ordering does not bite, but without the guard an *expired* reward
row would still outrank the domain row.

JS enforcement, `server-team/service/media.js` `chekcDiskLimit()`. The current unlimited test
is `storage === '9223372036854775807'` — a strict string compare that silently misses if the
driver hands back a Number. An explicit check goes ahead of it:

```js
if (quotaInfo && (quotaInfo.unlimited === true || quotaInfo.unlimited === 1)) return true;
```

`chekcDiskLimit` reads the *procedure* form of `get_quota`, which is why that one must emit
the column. `desk.js check_quota` uses the function form for hub counts and is unaffected —
the reward deliberately leaves `private_hub`/`share_hub` at free-plan values.

## Display

`Visitor.quota()` is fed from `desk.get_env` → the `get_quota` FUNCTION, so `unlimited`
reaches the client without a transport change. The account screen renders **"Unlimited"** with
no usage bar instead of a 9.2 EB total sitting at 0%.

The admin Storage Console is domain-scoped and rewards live in domain 1, so it is unaffected.
But `adminpannel/get_org_quota.sql` has a fallback that does `SUM(disk)` across a domain, and
a BIGINT-max row inside that sum would wreck the header. It cannot fire today; `AND source <>
'reward'` is added anyway rather than trusting the gate to hold for five years. That file is
mirrored in `admin-dash-server/schemas/`, so both copies change.

## Backfill

`yellow_page/patches/2026-07-29-reward-backfill-grant.sql`, following the house style of
`2026-07-24-migrate-free-to-new-allowance.sql`: grant to every `reward_claim` row with
`completed_count > 0` where `drumate.domain_id = 1` and no quota row exists, with `period_end`
five years from **that user's own** `rc.mtime` — they were promised the term at their
completion, not at deploy time.

A trailing `SELECT` lists the residue — org-domain holders and users already on Stripe — for a
human decision rather than a silent skip. Idempotent via `NOT EXISTS` plus an
`ON DUPLICATE KEY UPDATE` restricted to `source = 'reward'`.

## Testing

This box cannot runtime-test any of it: there is no reward data here, and the local
`yp.quota` is an ancient two-column table (`id`, `size`) — the schema itself is wrong.

Verification ran in a scratch DB built from the factory seed's quota shape plus `plan`,
`reward_claim`, `drumate`, `organisation` and `sys_conf`, with `yp.` rewritten to the
scratch schema. All eleven routines load clean. Results:

| Case | Result |
|---|---|
| Fresh grant writes the row, `unlimited=1`, 1826 days | pass |
| Second completion: no second row, term unmoved | pass |
| Org member: no slot consumed, no row | pass *(failed first — see above)* |
| Solo user with a Stripe row: not clobbered | pass |
| Slot cap: last place awarded, next user `missed` and ungranted | pass |
| Lapsed reward falls back to free 5 GB (`disk_free` → 5000000000) | pass |
| `get_quota` PROCEDURE emits the `unlimited` column | pass |
| `my_disk_limit` emits it; `disk_free` stays positive | pass |
| Cancel re-grants a genuine winner with the original term | pass |
| Cancel grants nothing to a non-participant or a `missed` user | pass *(failed first — see above)* |
| `get_org_quota` unaffected | pass |
| Backfill: correct per-user terms, residue reported, idempotent over two runs | pass |

The backfill's residue report initially aborted with `ERROR 1271 Illegal mix of
collations` — `quota.source` is `ascii_general_ci` against `utf8mb4` literals in a CASE.
Since that report is the only thing telling an operator who was *not* granted, it was the
one statement in the patch that must not fail; `source` is now converted explicitly.

## Rollout

Order is **schema → server-team → ui-team**, and it is safe rather than lucky: after the
schema patch alone, a rewarded user's row carries `$.disk` at BIGINT max, which `media.js`
already honours through its existing sentinel. There is no window where the grant is written
but not enforced — which is why that floor is in the row.

Patching means every instance plus a sweep for stragglers; a merge is not a deploy.

Rollback is `DELETE FROM yp.quota WHERE source = 'reward'`, exact by construction, because
nothing here ever mutates a row it did not create.

## Out of scope

- No `reward-5y` row in the `yp.plan` catalog — it would surface in the pricing UI.
- No change to the tenant-first cascade.
- `disk_free`'s personal-first ordering, and its nondeterministic
  `WHERE domain_id = _domain_id LIMIT 1` (several rows per domain are now legal), are
  pre-existing bugs. Flagged, not fixed here.

---

# Addendum: expiry-day behaviour (2026-07-29)

The grant shipped with read-time expiry and nothing else — no warning, no
explanation, and a UI that actively hid the resulting state. This addendum covers
what happens as the term ends.

## Decisions

| # | Decision | Chosen |
|---|----------|--------|
| 1 | What an expired reward is | A gift that ends: data kept, uploads pause, nothing ever deleted |
| 2 | What the warning asks | Free up space; Team mentioned second (no individual paid plan exists) |
| 3 | Who is warned, when | Only users over the free allowance; 30 days, 7 days, day of |
| 4 | Over-quota visibility | Stop clamping; name the state on the storage screen |

Explicitly rejected: reusing `renewal_expiry`'s ladder, which after ~181 days
calls `clean()` and deletes every hub. An unpaid invoice and an expired present
are not the same thing.

## Components

| Where | What |
|---|---|
| `yellow_page/procedures/reward/reward_expiry_due.sql` | query-only: who, at which stage |
| `yellow_page/procedures/contact/contact_reward_expiry_unread.sql` | surfaces the notice in the activity panel |
| `server-team/offline/workers/rewardExpiryWorker.js` | daily cron, delivery only |
| `server-team/service/private/templates/butler/reward-expiry-warning.html` | the mail |
| `server-team/service/private/activity.js` | one line: register the unread proc |
| `ui-team` account/storage screens + 6 locale files | honest over-quota state |

**Nothing here is load-bearing.** The term ends inside the read-time guards. If
the worker is never installed, the allowance still drops on the right day and
enforcement still holds — users are simply not warned.

## The ledger

`contact_activity` rows, `event='reward_expiry_warning'`, `data.stage ∈ {30,7,0}`.
One write serves as both the in-app notification and the sent-ledger.

The guard is *"no row at this stage yet"*, never *"today is day 30"* — the latter
is true for 24 hours and never returns, so a single missed cron night would skip
that warning forever. `stage` is the most urgent threshold **reached**, so a
catch-up run sends the 7-day notice rather than a "30 days remaining" mail that
is already false; skipped stages are recorded as superseded, with `dismissed_at`
set at insert so the feed's ordinary `dismissed_at IS NULL` filter hides them.

## Known gaps, deliberately unaddressed

- **No individual paid plan.** A solo user over 5 GB can only free space or form
  an organisation. That is a product decision, not something this work can fix.
- **Expired reward rows are never deleted** from `yp.quota`. Harmless — every
  reader now carries the guard — but every future reader inherits the obligation.
- **`disk_free` is personal-first** while the other resolvers are tenant-first,
  and its domain fallback still uses a nondeterministic `LIMIT 1`. Pre-existing.
