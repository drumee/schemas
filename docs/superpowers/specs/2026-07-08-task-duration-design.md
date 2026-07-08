# Task duration (start → end range) — design

**Date:** 2026-07-08
**Status:** Approved, implementing
**Origin:** Bug report "tasks-panel__due-duration toggle button isn't working". Root cause: the "Duration" toggle is rendered with a hardcoded `data-on="0"` and no click handler / service / state — it does nothing. Product decision: implement it as a real, persisted start→end date range.

## Root cause (the reported bug)

The `tasks-panel__due-duration` toggle appears in two skeleton blocks — the task detail panel and the create modal:

```js
Skeletons.Box.X({
  className: `${pfx}__toggle`,
  attrOpt: { "data-on": "0" },   // hardcoded off
  kids: [ Skeletons.Box.X({ className: `${pfx}__toggle-knob` }) ],
}),
```

It has no `service`/`uiHandler`, no backing state, and `data-on` never changes. Nothing listens for clicks, so it is inert — not even a visual flip. The SCSS (`skin/index.scss` `&__toggle[data-on="1"]`) *would* animate the knob, but nothing sets it. Contrast the working `__board-toggle`, which puts `service: "board-default"` on its clickable row → handler flips `this._boardDefault` → re-render with `dataset: { on: ... }`.

## Feature semantics

A task gains an optional **start date** in addition to its existing **due date**. The Duration toggle exposes it.

- **OFF (default; all existing tasks):** one "Due date" picker → `due_date`. `start_date` is NULL. Identical to current behavior.
- **ON:** two pickers — "Start date" (`start_date`) and "Due date" (`due_date`, the end). Constraint `start_date ≤ due_date`.
- **Toggle state is derived, not stored separately:** `start_date IS NULL` ⇒ OFF, `start_date` set ⇒ ON. (Chosen over an explicit `has_duration` boolean — NULL already encodes the state; a second column is a sync-bug surface. YAGNI.)
- **ON → OFF** clears `start_date` (send NULL). **OFF → ON** seeds `start_date` = current `due_date` (or blank) so the picker opens sensibly.
- On opening the detail panel, the toggle's initial state is derived from the loaded task's `start_date`.

## Scope guardrails

- Range is **stored and edited only in the create modal and detail panel** this round.
- **Gantt, Calendar, List, Summary views are untouched.** Gantt keeps faking its bar from `[ctime, due_date]`. (Follow-up work can switch Gantt to the real `[start_date, due_date]` range later.)
- Validation `start ≤ end` is enforced in the UI. Server/SP store whatever is sent (no hard DB constraint) — mirrors the existing loose `due_date` handling.

## The five layers (implementation order = dependency order)

### 1. Database — `common` class, table `task`
- `common/tables/task.sql`: add `start_date DATE DEFAULT NULL` after `due_date`.
- New idempotent patch `common/patches/alter_task_add_duration.sql`, following `alter_task_add_fields.sql`: `information_schema`-guarded `ALTER TABLE task ADD COLUMN start_date DATE NULL AFTER due_date`. Safe to re-run.
- Update factory snapshots `templates/factory/hub.sql` and `templates/factory/drumate.sql` (the `task` table appears in both) so fresh installs include the column.

### 2. Stored procedures — `common/procedures/task/`
- `task_create.sql`: add `IN _start_date DATE`; add `start_date` to the INSERT column list + `_start_date` to VALUES; add `t.start_date` to the trailing SELECT.
- `task_update.sql`: add `IN _start_date DATE`; add `start_date = _start_date` to the UPDATE SET (unconditional pass-through, mirroring `due_date` so NULL clears it); add `t.start_date` to the trailing SELECT.

### 3. Server — `server-team/service/private/task.js`
- `create()`: `const start_date = this.input.use('start_date', null);` and add it to the `CALL task_create(...)` arg array (+ one `?`).
- `update()`: same read; add to the `CALL task_update(...)` arg array (+ one `?`).
- Keep `await_run` (not `await_proc`) so NULL stays NULL for the nullable DATE column.

### 4. UI controller — `ui-team/.../tasks/index.js`
- Add `start_date` to: create payload (`_commitTask`), update diff (`_commitDetail`), create-draft defaults, and `_normalizeRow` (coerce incoming to `YYYY-MM-DD`).
- New service case `toggle-duration`: flip a `_durationOn` draft flag; on turn-off clear `start_date`, on turn-on seed it from `due_date`; then re-render.

### 5. UI skeleton — `ui-team/.../tasks/skeleton/index.js`
- Detail block (~L924) and create block (~L1505): give the `__toggle` box `service: "toggle-duration"`, `uiHandler: [ui]`, and drive `data-on` from draft state (`_durationOn`) instead of the hardcoded `"0"`.
- When ON, conditionally render a second `date_picker` for `start_date` (mirror the existing `due_date` picker's config: `dateFormat: "Y-m-d"`, `appendTo: document.body`, service `task-input-changed`).

## Deployment / operational notes

- **Merge ≠ live.** After code changes, apply the ALTER to every local `common`-class instance via `bin/patch-from-file common/patches/alter_task_add_duration.sql common`, then sweep for stragglers.
- **This box serves only `local.drumee`.** Production (`drumee.in`) is not reachable from here; the ALTER patch must be run there separately by someone with access. The patch is idempotent, so re-running is safe.
- Deployed server code runs from `/srv/drumee/runtime`, not the checkout — verify the running copy when testing server changes.

## Success criteria

1. Toggling the Duration switch flips its visual state (knob animates) in both the create modal and detail panel.
2. With the toggle ON, a start date can be entered; on save, `start_date` persists to the `task` table and is echoed back on reload.
3. Reopening a task with a `start_date` shows the toggle ON and both dates populated.
4. Turning the toggle OFF and saving clears `start_date` (NULL) without disturbing `due_date`.
5. Existing tasks (no `start_date`) behave exactly as before (toggle OFF, single due date).
