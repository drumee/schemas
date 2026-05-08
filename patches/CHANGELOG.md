# Changelog

## [Unreleased] — 2026-05-07

### Activity panel — persistent dismiss
- **New column**: `yp.contact_activity.dismissed_at` (idempotent ALTER in `patches/alter_contact_activity_add_dismissed_at.sql`)
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
