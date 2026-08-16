---
title: "Normalize move-plan result sets so cross-workspace moves relocate storage"
status: pending
priority: P1
branch: stage/member-management
---

# Move-plan result-set normalization

## Problem

Cross-workspace file moves commit the DB row but never relocate the storage
directory. The file exists in the database and 404s on preview/download. The
user has hit this repeatedly; each occurrence so far needed a manual `cp` to
restore the file.

## Root cause (verified)

Driver `@drumee/server-essentials/lib/addons/array.js:47` `get_rows()`:

- exactly ONE result set -> `a[0].get_rows()` -> flat array of row objects
- MORE than one -> `for (i of a) { i.length===1 ? r.push(i[0]) : r.push(i) }`
  -> mixed nesting: single-row sets flatten to an object, multi-row sets stay
  arrays

`mfs_move_all` emits TWO result sets: the move plan (`SELECT * FROM
_final_media`) plus one from `seo_update_hub`, which ends in a bare
`SELECT ... AS updated_words, ... AS status;` inside a cursor loop.

Consumers iterate the returned value and `switch (node.action)`. When the plan
arrives nested, `node` is an Array, `.action` is `undefined`, no case matches,
the loop completes silently, and the storage relocation never runs. The DB has
already committed.

Production evidence (after an earlier reorder that made the plan SELECT come
first):

```
raw proc result   { first:'[{"nid":"b140f28d...","action":"showone"},{...}]', len:2 }
after_transact    { count:2, actions:['undefined:undefined->undefined', ...] }
```

Reordering changed which garbage arrived, not that garbage arrived. **The bug is
the count of result sets, not their order.**

Introduced 2026-01-13 by commit `c4e6a6c` ("Update hub_id on cross-hub move"),
which added the SEO loop. Silent for 7 months because `switch` on `undefined`
matches nothing and the fallthrough is not logged.

### Differential proof

`mfs_copy_all` is the sibling procedure with the same `_final_media` pattern and
works correctly today. The only delta: no SEO loop, so exactly one result set,
so the driver unwraps it. Copy works, move does not, and result-set count is the
sole difference.

## Why the fix goes in JS, not SQL

The first proposal was to delete the trailing bare `SELECT` from
`seo_update_hub` and likewise from `mfs_create_node`. Reading the callers
disproved the second half:

`server-team/service/media.js:1010 ensureCreateNode` **depends** on that second
result set:

```js
while (node[1] && i < 30) {
  switch (node[1].sqlstate) {
    case '40001': /* deadlock  -> sleep + retry */
    case '23000': /* duplicate -> rename + retry */
```

`node[1]` IS the rollback result set — the deadlock/duplicate retry mechanism
for every upload path. It must stay.

Consequence: `mfs_create_node` is called from inside `mfs_move_all`. Any
rollback there emits an extra result set and silently reproduces this exact
data-loss bug. **The failure mode is latent no matter what is done to
`seo_update_hub`.** Only a consumer-side fix covers it.

Deciding factors:

- Zero DB rollout. No risk to 1216 shared databases or the four other developer
  endpoints (`main`, `huan`, `liam`, `vudangnt`) — decisive, since careless
  rollouts broke their stages twice today.
- Covers every source of an extra result set, present and future.
- The SQL hygiene fix (removing the dead `seo_update_hub` SELECT) stays
  available as separate, optional work.

## Scope

Three consumers parse the move/copy plan; all three have the bug:

| File | Line | Call |
|---|---|---|
| `service/private/media.js` | 199 | `transact()` -> `after_transact` |
| `service/private/channel.js` | 324 | `mfs_copy_all` / `mfs_move_all` |
| `service/private/channel.js` | 449 | `_promote_staged_to_folder` |

A shared helper avoids three copies of the same normalization. Precedent for a
shared helper in this directory: `service/private/_audit.js`.

## Contract

**Outcome:** cross-workspace moves relocate the storage directory; no dead
files; behavior independent of how many result sets the procedure emits.

**Constraints:**
- No DB rollout in this plan.
- Preserve `ensureCreateNode`'s dependence on `node[1]`.
- Keep the existing `mfs_move_all` reorder deployed (harmless; reverting costs
  another 1216-DB rollout for no benefit).

**Non-goals:** thread/lineage logic; orphan storage-directory cleanup (each is
the only copy of a lost file); the optional `seo_update_hub` hygiene fix.

**Acceptance criteria:**
- [ ] `actions` log shows real `move:<nid>-><des_id>` pairs, not `undefined`
- [ ] `relocate called` appears in logs on a cross-workspace move
- [ ] Move A->B then B->A: file opens at both ends, no manual restore
- [ ] Same-workspace move still works (no `move` rows, no regression)
- [ ] Copy path (`mfs_copy_all`) unchanged
- [ ] Chat attachment move (`channel.js:324`) still works
- [ ] `main` endpoint still moves files
- [ ] Zero plan rows with unrecognized `action` in normal operation
- [ ] TEMP-DIAG removed after verification

## Phases

| # | Phase | Status |
|---|---|---|
| 1 | Shared normalization helper | completed |
| 2 | Wire the three consumers | completed |
| 3 | Verify on stage, remove TEMP-DIAG | completed |
| 4 | Apply code-review findings | completed |

## Review findings applied

An independent review found five real defects, three of them created by the
earlier saga removal rather than by this fix:

**C1 — a test suite was left failing.** `offline/test/file-thread-access-events.test.js`
was 2/11 because its loader required `_emitCrossHubMoveEvents`, deleted with the
saga. Restored the four delete-path tests (their contract is still live), removed
the five that asserted saga behavior that no longer exists, and updated the
field-set assertion: the emitter is now shared with the move path, so move-only
keys are present-but-undefined. Now 5/5.

**C2 — `move_cross_hub` ran with no destination permission check.** Its ACL entry
carried only `src: "write"` and no `preproc`, so `pre_transact` never ran,
`srcgrantlst` was empty, and the per-node `delete` check that `workspace_move`
requires was skipped entirely. The deleted saga did its own explicit checks; the
compatibility shim dropped them without replacing them. Given the same
`src: "delete"` / `dest: "write"` / `preproc` block as `workspace_move`, which it
forwards to. This was a real permission hole, introduced by the shim.

**C3 — the table patch was missing from the manifest.** `260812-file-thread-lineage-holder.sql`
sat in `patches/` instead of `yellow_page/patches/` and was absent from
`patches/manifest.txt`, while four procedures depending on its `holder_*` columns
were listed. Moved and inserted immediately after the table definition. Verified
on stage: 11 JS arguments match 11 procedure parameters, all three columns
present, all four procedures deployed.

**H1 — the safety lock was bypassed.** `_relocateNodeStorage` replaced
`move_node`, which calls `check_safety` on both ends and throws
`DIRECTORY_IS_LOCKED`. Skipping `check_base` was correct (the destination
genuinely does not exist yet); skipping `check_safety` was not. Restored on the
source path; verified `MfsTools.check_safety` resolves at runtime on stage.

**H3 — dead code.** Removed `FILE_MOVE_TTL_SECONDS`,
`FILE_MOVE_THREAD_SETTLE_ATTEMPTS`, `FILE_MOVE_THREAD_SETTLE_DELAY_MS` and
`samePhysicalNode`, all orphaned by the saga removal.

**M2/M3 — diagnostics.** `movePlanRows` now keeps rows carrying `failed` so a
rolled-back `mfs_create_node`'s sqlstate still reaches the log, guards against a
nested array rather than treating it as a row, and warns on an empty result —
`call_proc` reports a failed CALL by returning `undefined`, so silence there was
indistinguishable from success.

Reviewer also confirmed independently: `r.action` is a sound discriminator; the
`toArray` removals are safe (all consumers re-apply their own); the `isEmpty`
early return is honest and not a contract change; the driver nests at most one
level, because `get_rows` tests `typeof i[0] !== 'array'` and `typeof` never
returns `"array"` — its deeper branch is dead code.

## Tests

`offline/test/move-plan.test.js` (new) — 10 cases over every shape the driver can
produce, replacing the coverage lost when `offline/test/mfs-move-result.test.js`
was deleted during the saga removal. Full suite: 69/69 across 5 files.

## Note on the deleted prior fix

Commit `033c97c` (2026-08-07) had already diagnosed this exact bug — "the wrapper
can nest operation rows inside a multi-result value" — with a helper
(`service/lib/mfs-move-result.js`) and its own regression tests. Both were
deleted during the saga cleanup because they lived on the saga path. The
multi-result diagnosis was still load-bearing outside it. That deletion is why
this bug returned, and why two earlier attempts today addressed symptoms.

## Open decision

Both a SQL fix (reordering `SELECT * FROM _final_media` before the SEO loop,
already live on 1216 DBs) and this JS fix are now in place. The JS fix alone is
sufficient and covers cases the reorder cannot. The reorder is harmless and
reverting costs another 1216-DB rollout, so it stays — recorded here so the
overlap is deliberate rather than forgotten.

## Risks

**Filter discriminator too narrow.** Mitigated: all four `INSERT INTO
_final_media` statements set `action` explicitly ('show', 'showone', 'move'),
verified by reading the procedure. Column defaults NULL but is never left
default.

**Single-row plan arrives as a bare object, not an array.** `get_rows` flattens
single-row sets. The helper must accept both shapes.

**Dropping rows that matter.** Non-plan rows are warned, not silently discarded
— the silent fallthrough is precisely what hid this bug for 7 months.

## Unresolved

- Advisory supervision (`--advice`) requested but `kongming` died twice on API
  529 overload. Proceeding without it; retry before the final review gate.
