# Changelog

## [Unreleased] — 2026-05-06

### P2P Chat
- **New tables**: `drumate/tables/p2p_channel.sql`, `p2p_read.sql`, `p2p_time.sql`
- **New procedures**: `p2p_post_message`, `p2p_list_messages`, `p2p_acknowledge`, `p2p_delete_me`, `p2p_delete_all`
- **Updated procedures**: `count_yet_read`, `count_yet_read_next`, `chat_rooms`, `chat_room_info`, `contact_chat_rooms`, `tag_chat_count`, `pages_to_read`, `all_read_count`

### File Versioning
- **New table**: `common/tables/file_version.sql`
- **New procedures** (`common/procedures/mfs/versioning/`): `file_version_list`, `file_version_get`, `file_version_delete_old`, `file_version_download`
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
