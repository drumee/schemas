# Plan feature enforcement — audit

**Date:** 2026-07-28
**Status:** Draft — product / listing decisions pending
**Repos touched:** `schemas` (quota JSON, retention procs), `server-team` (media / desk / channel / secure_share / mfs_api), `admin-api`, `admin-console`, `ui-team` (plan listing / billing copy)

## Summary

Audit of Free / Team / Business plan listing claims against code and live DB. Goal: only sell features that are actually enforced, wire the two half-built entitlement hooks (~1 day), and remove claims that have no implementation.

| Bucket | Count | Listing action |
|---|---|---|
| A — built and enforced | 7 | Keep; sell now |
| B — built, not wired to plan | 2 | Fix (~½ day each), then claim by tier |
| C — not built | 3 | Remove from listing (or Coming soon / Contact sales) |

## A. Built and enforced — sell now (7)

| Feature | Evidence | Notes |
|---|---|---|
| Storage 5 GB / 100 GB / 1 TB | `media.js:754` `before_store` → `chekcDiskLimit()` blocks upload; cascade `disk_limit` | Verified live: upload 13 632 512 bytes; counter moved byte-for-byte |
| Files + folder chat | 7 procs `channel_file_thread_*` + `service/private/channel.js` | Deployed 800/800 DBs |
| Guest access | `secure_share_create` / `delete` / `deny_email` / `access_log` + `secure_share_access_event` | Includes email deny list |
| Permissions (role-based) | bitmask `_K.permission` (owner / admin / write / read / anonymous) + `procedures/role/` (`add` / `delete` / `get` / `rename` / `reposition`) | |
| Admin panel | plugin `admin-console` + `admin-api` | |
| Admin panel + audit logs (Business) | `admin.get_audit_logs`, `export_audit_logs`, `get_hub_audit_logs`, `get_audit_stats` | ACL limit: page 1 per hub, then merge |
| API access (Business) | `mfs_api`: `create_token` / `revoke` / `list`, table `mfs_token`, permission `admin` | **MFS export token**, not a full REST API |

## B. Built but not wired to plan — quick fixes (2)

### 1. Version history 30 days / 1 year — ~½ day

**Already in place:** retention worker, `file_version_purge_expired`, `organisation_{get,set,list}_retention`.

**Gap:** retention days come from `organisation.metadata.$.version_retention_days` with a hard default of **30**. Nothing reads `quota.history_length`, even though the catalog already carries the right values (`team` → 30, `business` → 365).

**Fix:** in `organisation_get_retention`, use `quota.history_length` as the default / ceiling. One proc; worker untouched.

### 2. Workspaces "1 / Multiple" — ~½ day

**Already in place:** `create_hub` declares preproc `check_quota`; `desk.js:147` reads `private_hub` / `share_hub` from `get_quota` and raises `QUOTA_EXCEEDED`.

**Gap:** quota JSON for all three plans omits those keys:

```json
{"plan":"team","disk":100000000000,"seat":10,"organization":1,"history_length":30}
```

So `remain = undefined - used = NaN`, and `NaN <= 0` is `false` → the guard never fires.

**Stage evidence:** Free-plan accounts hold 27 / 10 / 3 workspaces while the listing claims Free = 1.

**Fix:**

1. Add `share_hub` / `private_hub` to the plan quota JSON (and seed / entitlement apply path).
2. Change the guard to `!(remain > 0)` so `NaN` cannot pass.

## C. Not built — do not list (3)

| Feature | Status |
|---|---|
| Members "up to 10 / Unlimited" | No proc and no service enforces seat. `quota.$.seat` is display-only. Hidden on stage because every org still has one member |
| SSO / SAML | No hits in `service/`, `lib/`, `acl/`. Grep `saml\|sso\|oidc` only matches unrelated text inside `stripe_webhook.js` |
| SDK (Sovereign: "Admin panel + SDK", "API access + SDK") | Does not exist |

## Recommended actions

1. **Listing:** ship A as-is; strip C (or mark Coming soon / Contact sales).
2. **Engineering (B):** land the two wiring fixes before claiming version history or workspace caps by tier.
3. **Follow-ups (out of this audit):** seat enforcement for Members; SSO/SAML; real API/SDK product — each needs its own design before any listing claim.

## Success criteria

1. Marketing / billing copy only claims features in bucket A (plus B after the fixes land).
2. `organisation_get_retention` returns 30 for Team and 365 for Business from `quota.history_length` when metadata is unset.
3. Creating a hub on Free fails with `QUOTA_EXCEEDED` once the Free workspace cap is reached; `NaN` no longer bypasses the guard.
4. Bucket C strings are absent from the public plan comparison table.
