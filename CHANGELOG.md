# Changelog

## [Unreleased] — 2026-07-31

### LAUNCH30 promo — free 1-month Team trial, no card, no Stripe
- **Added**: `yellow_page/tables/promo_launch30.sql` — per-payer claim/seen tracking (`unclaimed`/`claimed`/`expired`)
- **Added**: `yellow_page/procedures/promo/promo_launch30_get_state.sql` — caller's own row
- **Added**: `yellow_page/procedures/promo/promo_launch30_mark_seen.sql` — idempotent "shown once" flag per surface (home/billing)
- **Added**: `yellow_page/procedures/promo/promo_launch30_grant.sql` — Team-plan `yp.quota` row (source=`promo-launch30`, `period_end`=+30d) for the org `org_provision` bootstrapped, plus the claim bookkeeping row
- **Added**: `yellow_page/procedures/promo/promo_launch30_due.sql` — claimed trials past `trial_ends_at`
- **Added**: `yellow_page/procedures/promo/promo_launch30_mark_expired.sql` — flips a row once the worker has cleared the org's entitlement
- **Updated**: `patches/manifest.txt` — registers the files above

## [Unreleased] — 2026-07-30

### Admin console — Persist “ask for admin access” requests
- **Added**: `yellow_page/tables/admin_access_request.sql` — pending/dismissed/granted rows per `(domain_id, requester_uid)` so owner-side banners survive reload / offline (no longer WS-only)
- **Added**: `yellow_page/procedures/adminpannel/admin_access_request_create.sql` — idempotent upsert of a pending request (re-ask refreshes `mtime`)
- **Added**: `yellow_page/procedures/adminpannel/admin_access_request_list.sql` — pending requests for a domain with requester name/email from `drumate`
- **Added**: `yellow_page/procedures/adminpannel/admin_access_request_dismiss.sql` — dismiss one requester or every pending row for the domain
- **Added**: `yellow_page/procedures/adminpannel/admin_access_request_get.sql` — caller’s own pending row so the member upsell shows “Request sent” after reload
- **Added**: `yellow_page/patches/2026-07-30-admin_access_request_granted_cols.sql` — `granted_by` / `granted_at` columns
- **Added**: `yellow_page/procedures/adminpannel/admin_access_request_grant.sql` — mark pending row granted after org privilege elevation
- **Updated**: `patches/manifest.txt` — registers the files above (YP only; admin-api calls via `this.yp.await_proc`)

## [Unreleased] — 2026-07-10

### Billing — Pro per-seat: standalone seed patch
- **Added**: `yellow_page/patches/2026-07-10-plan-pro-seat-rows.sql` — targeted `INSERT IGNORE` of the two `pro_seat` add-on rows for existing/prod DBs, so seeding no longer relies on re-running the whole `tables/plan.sql` (whose `CREATE TABLE IF NOT EXISTS` is a no-op once the table exists). Additive + idempotent; no ALTER (entity_type `addon` already exists); `stripe_price_id` stays NULL (set out-of-band per environment)

## [Unreleased] — 2026-07-09

### Billing — Pro per-seat (C1)
- **Updated**: `yellow_page/tables/plan.sql` — seed `pro_seat` add-on rows (month/year): one extra Pro seat per unit (`quota.$.seat=1`, no disk); Pro base already carries `$.seat=5` included
- **Updated**: `yellow_page/procedures/subscription/payment_get_addon.sql` — also return `seat` so the webhook reducer can classify seat add-ons vs storage add-ons
- **Updated**: `yellow_page/procedures/subscription/payment_apply_entitlement.sql` — individual branch records the resolved seat total (`$.seat`) when greater than the plan default (Pro included 5 + purchased extra seats)
- **Updated**: `yellow_page/procedures/subscription/payment_get_subscription.sql` — expose `seats` + `organization` from the entitlement quota for the billing UI status line

## [Unreleased] — 2026-07-09

### Admin console — Storage totals (workspace = user distribution)
- **Updated**: `yellow_page/procedures/adminpannel/get_org_storage_stats.sql` — live `SUM(media.filesize)` per org hub (all owners) so TOTAL HUB STORAGE matches user roll-up
- **Updated**: `yellow_page/procedures/adminpannel/get_org_user_storage.sql` — attribute bytes by `owner_id` across org hubs; include domain members + external collaborators + orphan owners (`is_external`)
- **Updated**: `yellow_page/procedures/adminpannel/get_org_user_storage_count.sql` — count matches the user-storage roster (domain members + external/orphan owners with files)
- **Updated**: `hub/procedures/admin/get_hub_user_storage.sql` — include non-member file owners so hub user rows reconcile with `hub_used_bytes`

## [Unreleased] — 2026-07-08

### Admin console — Pending Invites counter
- **Fixed**: `yellow_page/procedures/adminpannel/member_list_stats.sql` — `pending_invites` counted never-connected drumate accounts, so inviting someone to a workspace never bumped the number → count non-expired `pending_invitation` rows on the domain's active hubs, the same source as the stat-card popup (`pending_invites_by_domain`)

### Admin console — Audit Logs action filter + target resource
- **Added**: `common/patches/alter_action_log_add_invite_actions.sql` — extends the `action_log.action` enum with `invite_sent` / `invite_accepted` (apply to all hub and drumate DBs; do **not** re-run `common/tables/action_log.sql` on existing DBs)
- **Updated**: `common/tables/action_log.sql` — action enum caught up with `alter_action_log_add_actions.sql` + the two new invite actions (seed for new DBs only)
- **Updated**: `templates/factory/hub.sql`, `templates/factory/drumate.sql` — `action_log.action` enum includes `invite_sent` / `invite_accepted` so newly provisioned DBs match the alter patch
- **Updated**: `common/procedures/action_log/hub_get_audit_logs_window.sql`, `hub_get_audit_logs_count.sql` — new `_action`/`_category` filter params (`''` = no filter) for the Audit tab action filter; window proc also resolves `target_name`/`target_email` (LEFT JOIN `yp.drumate` on `entity_id`) so the FE can show a real Target Resource column
- **Updated**: `yellow_page/procedures/adminpannel/member_list_hubs_by_domain.sql` — adds resolved hub `name` (ident → hub.name → hubname) so the audit aggregator can label rows with the workspace name

### Admin console — External Guest Activity search
- **Updated**: `yellow_page/procedures/secure_share/secure_share_guest_events_by_domain.sql`, `secure_share_guest_events_by_domain_count.sql` — optional search filter for guest email / share owner / workspace name

## [Unreleased] — 2026-07-07

### Admin console — member stat counters
- **Fixed**: `yellow_page/procedures/adminpannel/member_list_stats.sql` — Pending Invites now counts unaccepted members via a NULL-safe category gate; External Guests read the legacy `dmz_token` (never written by secure shares) → `secure_share_access_event`; Admins counted `privilege > 1` (over-counting write-capable members) → count the admin bit (`privilege & 16`), matching `hub_member_stats` and the role labels
- **Updated**: `hub/procedures/admin/hub_member_stats.sql` — adds `_hub_id` param; per-workspace Pending Invites (was hardcoded `0`) now from `yp.pending_invitation`; External Guests (was cross-domain members) now distinct guests from `secure_share_access_event` for the hub
- **Added**: `yellow_page/procedures/adminpannel/pending_invites_by_domain.sql` — lists pending workspace invites (email + workspace + expiry) for the Pending Invites stat-card popup; optional `_hub_id` narrows to one workspace

### Admin console — Storage tab
- **Fixed**: `yellow_page/procedures/adminpannel/get_org_user_storage.sql` — per-user used storage read from the dead `entity.space` column (`0` for every user) → the canonical `yp.disk_usage()` function (owned hubs + personal), the same source `data_usage()`/`disk_free()`/the quota cache use
- **Fixed**: `yellow_page/procedures/adminpannel/get_org_storage_stats.sql` — per-hub used storage read from `entity.space` (`0`) → `disk_usage.size`; resolve blank `hub_name` via the `ident → hub.name → hubname` fallback
- **Added**: `yellow_page/procedures/adminpannel/get_org_quota.sql` — domain storage limit (`yp.quota.disk`) and cached usage (`yp.quota_usage`) for the admin Storage tab quota bar

## [Unreleased] — 2026-06-10

### Hub invite — workspace shown as ID instead of name
- **Fixed**: `drumate/procedures/hubs/join_hub.sql` — use `h.name` instead of `h.hubname` in COALESCE

## [Unreleased] — 2026-05-15

### Manifest & patch cleanup
- **Updated**: `patches/manifest.txt` — complete rewrite; adds all SPs from the activity/notification/audit/contact/conference features; relocates `alter_socket_add_mtime.sql` from root `patches/` to `yellow_page/patches/`; removes stale `history.txt`, `fix_existing_users_mfs_ack.sql`, `desk_build_index.sql`, and `table_quota.sql`

## [Unreleased] — 2026-05-14

### P2P Chat
- **Updated**: `drumate/procedures/chat/p2p_delete_me.sql` — recipient-side delete support: accepts `peer_id` in JSON input; new Case 2 lets the non-author trash the message in the peer's DB via a cross-DB prepared UPDATE; returns `SUCCESS=0` only when neither case matches
- **Updated**: `drumate/procedures/chat/contact_chat_rooms.sql` — fix forward-message contact list: join `yp.drumate` on `c.uid` (was `c.entity`), aligning with the logic already used in `chat_rooms`

## [Unreleased] — 2026-05-13

### Conference
- **Updated**: `yellow_page/procedures/conference/conference_revoke.sql` — move callee socket SELECT outside `IF _db_name IS NOT NULL` block; P2P calls (hub_id = caller uid, no matching hub row) no longer leave the callee's ring window stuck after cancel; add fallback to caller's drumate row when `_owner_id` is null so the WS payload still carries display name

### Channel
- **Updated**: `hub/procedures/channel/channel_notify_messages.sql` — filter by delivered-to-uid rather than the global seen key; each recipient only receives notifications for messages addressed to them

### Disk usage trigger
- **Updated**: `yellow_page/triggers/disk_usage_sync_quota_cache.sql` — guard the INSERT path against negative `_delta`; the INSERT VALUES previously used bare `_delta` (unlike the ON DUPLICATE KEY UPDATE branch which already had `GREATEST(0, …)`), causing `ER_WARN_DATA_OUT_OF_RANGE` under `STRICT_TRANS_TABLES` when no `quota_usage` row existed for the domain

### Contacts
- **New procedure**: `drumate/procedures/contact/my_contact_email_in_use.sql` — validates that a proposed additional email is not already in use; called from the edit-contact form before saving

## [Unreleased] — 2026-05-12

### Activity panel — duplicate hub invitations + dismiss routing
- **Updated**: `yellow_page/procedures/contact/contact_log_activity.sql` — idempotent for `hub_invite_received` and `invite_received`. Re-invites refresh the existing undismissed row instead of stacking new ones.
- **Updated**: `drumate/procedures/notification/notification_hub_invites.sql` — dedupes per `(inviter, hub_id)` via `MAX(id) GROUP BY` join.
- **Updated**: `server-team/service/private/hub.js` (`invite_received_get`) — mirrors the same dedupe so both callers see identical data.
- **New patch**: `yellow_page/patches/cleanup_duplicate_hub_invites.sql` — one-time data clean-up that stamps `dismissed_at` on existing duplicate hub-invite rows (keep `MAX(id)` per inviter/hub).
- **Updated**: `ui-team/src/drumee/builtins/panel/activity/index.js` (`updatePriorityListUnified`) — sets `e.item_type = it.category` so `_dismissActivity` routes hub_invite / contact / chat / teamchat / ticket dismisses to the right server endpoint. Previously every row fell back to `mfs` and persisted nothing on the recipient's `contact_activity` row.

### Audit integration
- **New procedure**: `common/procedures/action_log/hub_get_audit_logs_window.sql` — returns up to N most recent audit rows per hub (window-based, no per-hub pagination); the YP aggregator fetches a window from each hub, merges by `ctime DESC`, then slices the requested page — this enables correct cross-hub pagination
- **New procedure**: `common/procedures/permission/hub_count_admins.sql` — counts distinct entities holding hub-level admin (`resource_id='*'`, permission bit 16); feeds the bus-factor check in the Security Score (hubs with exactly one admin are flagged as a single point of failure)
- **New procedure**: `yellow_page/procedures/adminpannel/get_security_signals.sql` — org-wide security inputs (total members, MFA rate, active members, total hubs, external exposure via share_box + guest invites) for the audit-logs Security Score formula
- **Updated**: `yellow_page/procedures/adminpannel/get_audit_stats.sql` — integrates the new signal inputs from `get_security_signals` and `hub_count_admins`

### P2P Chat — inbox & notifications
- **New procedure**: `drumate/procedures/chat/p2p_get_message.sql` — thread-lookup helper; validates and fetches thread context when a reply targets a P2P message (stored in `p2p_channel`, not `channel`)
- **Updated**: `drumate/procedures/chat/chat_rooms.sql` — include same-domain colleagues via `yp.drumate` JOIN so peers without a formal contact entry appear in the chat inbox; change `nocontact`/`memory` INSERTs to `INSERT IGNORE` to avoid duplicate-key errors
- **Updated**: `drumate/procedures/notification/notification_center.sql` — replace `INNER JOIN contact` with `INNER JOIN yp.drumate` so unread P2P message notifications appear for colleague peers

## [Unreleased] — 2026-05-11

### Hub admin & member management
- **Updated**: `hub/procedures/admin/hub_member_stats.sql` — extended member statistics for the admin console
- **Updated**: `hub/procedures/members/hub_get_members_by_type.sql` — expose `user_id` as `drumate_id` / `entity_id` for contacts feature; add `update_time` for entity-level timestamps
- **Updated**: `yellow_page/procedures/adminpannel/member_list_workspaces.sql` — minor additions for member workspace listing

## [Unreleased] — 2026-05-08

### Notification center
- **New procedure**: `drumate/procedures/notification/notification_dismiss.sql` — single entry point for dismissing any notification rollup; routes by `_category` to the right read-pointer or status update (p2p_read advance for chat, dismissed_at stamp for contact, mfs_ack advance for media)
- **New procedure**: `drumate/procedures/notification/notification_read.sql` — marks a rollup as read (advances read pointer) without hiding it from the feed; for chat/teamchat the read and dismiss pointers are the same
- **New procedure**: `yellow_page/procedures/activity_publish.sql` — generic notification creation under the `activity.*` namespace; routes by `_category` to the right underlying table (mfs_changelog, contact_activity, etc.) so integrations can publish without knowing which audit log they belong to
- **New patch**: `drumate/patches/alter_contact_add_dismissed_at.sql` — adds `dismissed_at` to `drumate.contact`; idempotent, guarded by `information_schema` check
- **Updated**: `drumate/tables/contact.sql` — schema definition updated with `dismissed_at` column
- **Updated**: `yellow_page/tables/contact_activity.sql` — schema definition updated with `dismissed_at` column

## [Unreleased] — 2026-05-07

### Activity panel — persistent dismiss
- **New column**: `yp.contact_activity.dismissed_at` (idempotent ALTER in `drumate/patches/alter_contact_activity_add_dismissed_at.sql`)
- **Updated**: `drumate/procedures/mfs_mark_all_read.sql` — also stamps `dismissed_at` on every undismissed `contact_activity` row addressed to the user, so hub/contact invitations don't reappear after reload
- **Updated**: `drumate/procedures/activity_get_log.sql` — filters `c.dismissed_at IS NULL`
- **New procedure**: `drumate/procedures/contact_activity_dismiss.sql` — per-row hide for the new `activity.dismiss_contact_event` endpoint
- **Updated**: `yp.invite_received_get` query in `server-team/service/private/hub.js` — adds `a.dismissed_at IS NULL`

## [Unreleased] — 2026-05-06

### P2P Chat
- **New tables**: `drumate/tables/p2p_channel.sql`, `p2p_read.sql`, `p2p_time.sql`
- **New procedures**: `p2p_post_message`, `p2p_list_messages`, `p2p_acknowledge`, `p2p_delete_me`, `p2p_delete_all`
- **Updated procedures**: `count_yet_read`, `count_yet_read_next`, `chat_rooms`, `chat_room_info`, `contact_chat_rooms`, `tag_chat_count`, `pages_to_read`, `all_read_count`

### File Versioning
- **New table**: `common/tables/file_version.sql`
- **New procedures** (`common/procedures/mfs/versioning/`): `file_version_list`, `file_version_get`, `file_version_delete_old`, `file_version_download`, `file_version_create`, `file_version_purge`
- **Updated**: `common/procedures/mfs/mfs_purge.sql` — cascades file_version row deletion when a media node is permanently purged
- `file_version_create` is the write hook called from `media.save` / `media.replace` to snapshot the pre-overwrite blob; demotes any prior `is_active=1` row and assigns the next `version_num`
- ⚠️ Naming pitfall: the proc uses parameter `_fname`, *not* `_filename`. MariaDB's parser treats `_filename` (and `_binary`, `_utf8`, `_latin1`, …) as charset introducers and rejects them as identifiers in stored-procedure parameter declarations. Avoid underscore-prefixed names that collide with registered charsets.
- Moved from `hub/procedures/admin/` (deleted): `file_version_*` procedures now live under `common/`

### Hub Channel
- **Updated**: `hub/procedures/channel/channel_post_message.sql` — adapted for new channel table structure; renamed from `channel_post_message_next`

### Hub Admin
- **Updated**: `hub/procedures/admin/hub_member_list.sql`
- **New procedures**: `hub/procedures/admin/get_hub_storage_stats.sql`, `get_hub_user_storage.sql`

### Admin Panel
- **New procedure**: `yellow_page/procedures/adminpannel/get_hub_audit_logs.sql`

### Notifications
- **Updated**: `drumate/procedures/notification/notification_center.sql` — replaced `channel.entity_id` with `author_id`
