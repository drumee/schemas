# Activation funnel tracking

**Date:** 2026-08-24
**Status:** implemented, not yet deployed
**Branch:** `feature/funnel-tracking` in `schemas`, `analytics-server`, `analytics-ui`, `server-team`, `loby`

## Problem

The analytics dashboard's **Activation → Funnel** page was a mockup. Of its
five stages exactly one — Signup — carried a real number. The other four were
hardcoded strings (`~2,470 · 70%`) marked with an "ex" chip, and both metric
cards below them were invented. The page's own header said so: *"There is no
activation engine: nothing writes activated_at, and no event says a folder was
created or a file uploaded for a given user."*

This makes that sentence false.

## What each stage means

| Stage | Definition |
|---|---|
| **Signup** | A real account: `yp.entity ⋈ yp.drumate`, test addresses excluded. The denominator. |
| **Onboarded** | Finished the onboarding wizard (`profile.onboarded = 1`). |
| **Create folder** | Created a folder themselves, at least once. |
| **Upload file** | Put a file in their workspace, at least once. |
| **Activated** | Both of the above, in either order. |

The shape is **not a line**. Signup → Onboarded is sequential; folder and
upload are two independent flags that can land in either order, because Drumee
gives every account a workspace at signup and a user can upload before they
ever create a folder. The page draws them side by side joined with `+`.

## Decisions

Four questions were settled before any code:

1. **Store milestones in a new table** rather than deriving them or counting
   `services_log` rows.
2. **Backfill all four stages** from history, rather than starting empty.
3. **All time.** The page ignores the topbar range chip.
4. **Write server-side**, in the media handlers, rather than from the UI
   selectors that were originally named.

Each is justified below where it bites.

### 1. Why a table

Three milestones were derivable and one was not.

`folder` and `upload` are `MIN(timestamp)` over `yp.mfs_changelog` — possible,
but a full scan plus a `JSON_VALUE` per row on every page load, over the
busiest write path in the product.

`onboarded` is **not derivable at all**. `drumate.profile.$.onboarded` is a
boolean. `mark_onboarding_complete` only *validates* the wizard; nothing
anywhere records when it was finished. A funnel with one undated stage cannot
be cohorted or timed — it could report that a user onboarded but never when.
One undated stage is enough to make the page unanswerable.

`yp.funnel_milestone` has `PRIMARY KEY (uid, milestone)`, and every writer is
`INSERT IGNORE`. **That key is the "first time only" rule** — the second folder
a user creates is a no-op in the storage engine, so no caller can get the
semantics wrong by forgetting a guard, and the backfill is re-runnable for
free.

### 2. Why the system folders need no exclusion

The original request asked to exclude the folders every account is born with.
They are excluded already, structurally, and it is worth knowing why before
anyone "fixes" the backfill by adding a filter:

- Photos / Documents / Videos / Musics come from the drumate factory template.
- "Personal Workspace" comes from loby's `make_default_folers`.
- `__chat__` / `__trash__` come from `mfs_home` and `mfs_trash_init`.

**All of them call `mfs_make_dir` procedure-to-procedure.** Only the
`media.make_dir` *service* writes an `mfs_changelog` row. So the seeded folders
were never in the data the funnel reads. Verified on the live box: every
`mimetype='folder'` changelog row belongs to a real site import, none to
account provisioning.

Chat attachments are absent the same way — `changelog_write` returns early for
`/__chat__/` paths — and `media.js` repeats that test before marking, so the
funnel and the changelog count the same population.

### 3. Why server-side and not the named selectors

The request named four UI entry points (`form-folder__main`,
`--add-folder`, two `--from-device`). Writing from the server instead means the
milestone cannot be bypassed and survives UI refactors, and it follows how
uploads are already counted for the Referral board.

The trade accepted: a folder made by drag-drop or context menu, and an upload
from Google Drive migration or paste, also count. Those are genuinely "the user
put something in their workspace", which is what the stage means.

### 4. Why all time, and why the chip is dimmed

A funnel bounded by **event** date is not a funnel: a March signup who
activates in August lands in Activated but not in Signup, so the stages stop
being monotonic and percentages exceed 100. The correct windowed version bounds
the **signup cohort**, which is a different query.

Rather than leave a live chip doing nothing — the exact bug the growth chart
shipped with, documented in `analytics-ui/app/utils.js` — `_paintWindowChips`
greys the range control while Funnel is open (`WINDOWLESS_VIEWS`), and the page
carries a caption saying so. The chips stay *clickable*, because the window is
global state other pages read.

## Architecture

```
                    ┌──────────────────────────────────────┐
  loby              │  onboarding.update_profile           │
  service/          │    drumate_update_profile (onboarded)│
  onboarding.js     │    → funnel_mark(uid,'onboarded')    │
                    └──────────────────────────────────────┘
                    ┌──────────────────────────────────────┐
  server-team       │  media.make_dir  → 'folder'          │
  service/media.js  │  media.upload    → 'upload'          │
  + lib/funnel-     │    (media.new only, /__chat__/ out)  │
    milestone.js    └──────────────────────────────────────┘
                                    │
                                    ▼
                    ┌──────────────────────────────────────┐
  schemas           │  yp.funnel_mark                      │
                    │    INSERT IGNORE the reported leg    │
                    │    both legs present?                │
                    │      → INSERT IGNORE 'activated'     │
                    │        at GREATEST(folder, upload)   │
                    └──────────────────────────────────────┘
                                    │
                                    ▼
                    ┌──────────────────────────────────────┐
                    │  yp.funnel_milestone                 │
                    │    PK (uid, milestone)               │
                    └──────────────────────────────────────┘
                                    │
                                    ▼
                    ┌──────────────────────────────────────┐
  analytics-server  │  yp.funnel_summary()  (all time)     │
                    │  analytics.funnel_summary endpoint   │
                    └──────────────────────────────────────┘
                                    │
                                    ▼
                    ┌──────────────────────────────────────┐
  analytics-ui      │  _refreshFunnel → skeleton/funnel.js │
                    └──────────────────────────────────────┘
```

**`activated` is derived in one place.** It can be completed by either of two
unrelated handlers, so asking each to check the other's milestone would be two
copies of one rule that drift the first time either is edited. The handlers
report the fact they know; `funnel_mark` decides what it adds up to, and
`SIGNAL`s if a caller hands it `activated` directly.

**Onboarded is written after `drumate_update_profile`, not after
`mark_complete`.** `mark_complete` only validates the stored answers — it can
succeed and then be followed by a failed profile write, leaving a user who
never got `onboarded = 1` and meets the wizard again next login. The profile
write is what actually ends onboarding.

Every call site is fire-and-forget with a `.catch()`, following
`pushReferralLive` next door: the folder or the file is already committed, so a
failure here must not surface as a failure of the operation, and an analytics
row must not add latency to an upload.

## Files

| Repo | File | Change |
|---|---|---|
| schemas | `yellow_page/tables/funnel_milestone.sql` | new |
| schemas | `yellow_page/procedures/analytics/funnel_mark.sql` | new |
| schemas | `patches/funnel_backfill.sql` | new |
| schemas | `patches/manifest.txt`, `patches/changelog.txt` | updated |
| analytics-server | `schemas/procedures/yp/funnel_summary.sql` | new |
| analytics-server | `acl/analytics.json` | `funnel_summary` endpoint |
| analytics-server | `service/index.js` | `funnel_summary()` handler |
| server-team | `service/lib/funnel-milestone.js` | new |
| server-team | `service/media.js` | 2 call sites |
| loby | `service/onboarding.js` | 1 call site + `_markFunnelMilestone` |
| analytics-ui | `app/skeleton/funnel.js` | rewritten data-driven |
| analytics-ui | `app/index.js` | `_refreshFunnel`, `WINDOWLESS_VIEWS`, chip dimming |
| analytics-ui | `app/skin/index.scss` | `__approx-tag`, `[data-disabled]` |

## Backfill, and the one estimate on the page

`folder`, `upload` and `activated` are backfilled from real historical
timestamps in `mfs_changelog`.

`onboarded` cannot be. There was no completion time to recover, so
`entity.ctime` stands in and the row is flagged `approx = 1`. The **count is
exact**; only the dates are estimates. The page surfaces this as an `≈` chip on
the Onboarded box with a tooltip, rather than presenting an estimate as a
measurement.

Any future cohort or time-to-onboard work must **exclude** `approx` rows rather
than average them in.

## Verification performed

Against MariaDB 11.8 on the local box, and a purpose-built `scratch_funnel`
database with seeded fixtures:

| Check | Result |
|---|---|
| Same milestone marked twice → one row, first timestamp kept | pass |
| `folder` then `upload` → `activated` at the later timestamp | pass |
| Reverse order → identical result | pass |
| `folder` alone → no `activated` row | pass |
| Empty / NULL uid → silent no-op | pass |
| `funnel_mark(uid,'activated')` → refused (ERROR 1644) | pass |
| Typo'd milestone → refused, nothing written | pass |
| Backfill run twice → byte-identical table (MD5 compared) | pass |
| Fixture of 5 real + 1 test user → `5/4/4/3/3`, approx 1, median 300s | pass |
| Test account with a *complete* funnel → absent from every stage | pass |
| Forced-NULL regexp → 6 users reported, not 0 | pass |
| Zero activated users → median NULL, one row still returned | pass |
| Zero users at all → clean zero row, no error | pass |
| Skeleton render: loaded / loading / empty-install | pass |
| `sass` compile of `skin/index.scss` | pass |

**Not verified here:** the page in a browser, and a real `media.make_dir` /
`media.upload` through the deployed server. This box serves only
`local.drumee`, and the running server code lives in `/srv/drumee/runtime`
rather than the checkout. Both need a stage deploy.

## Rollout order

The table and procedures must land **before** the services that call them.

1. `bin/patch-from-file yellow_page/tables/funnel_milestone.sql yellow_page`
2. `bin/patch-from-file yellow_page/procedures/analytics/funnel_mark.sql yellow_page`
3. Run `patches/funnel_backfill.sql`
4. Apply `analytics-server/schemas/procedures/yp/funnel_summary.sql`
5. Deploy analytics-server (read-only; safe to land early)
6. Deploy server-team and loby (the writers)
7. Deploy analytics-ui

**Before step 1**, two checks that have burned this codebase before:

- Diff the *deployed* `analytics_test_email_regexp` against the repo copy.
  Procedures here are applied by hand and drift; this one was missing entirely
  on the local box.
- Confirm `mfs_changelog.uid`'s actual collation on each target. The repo
  declares `utf8mb4` and the local box still has `ascii` — harmless for this
  join (ascii coerces to utf8mb4), but worth knowing before assuming the repo
  describes the disk.

## Future work, deliberately not done

- **Cohort windowing.** `funnel_summary` takes no arguments today. A windowed
  version should bound `entity.ctime`, not the milestone timestamps, and would
  need `WINDOWLESS_VIEWS` and the caption removed together.
- **Time-to-onboard.** Blocked until enough non-`approx` onboarded rows exist
  to be worth measuring — which is roughly one signup cohort after deploy.
