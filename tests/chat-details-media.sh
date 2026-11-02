#!/usr/bin/env bash
# chat-details-media.sh — channel_media_stats / channel_media_list against a
# disposable database: team-chat scope only, per-user deletions excluded,
# trashed and other-hub attachments never counted, links cut clean out of HTML.
#
#   mariadb -e "CREATE DATABASE chat_details_test_1 CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci"
#   tests/chat-details-media.sh chat_details_test_1
set -euo pipefail

db_name=${1:?usage: chat-details-media.sh <disposable-db>}
case "$db_name" in
  chat_details_test_*) ;;
  *) echo "refusing non-test database: $db_name" >&2; exit 2 ;;
esac

repository_root=$(cd "$(dirname "$0")/.." && pwd)

sql() {
  mariadb --batch --skip-column-names "$db_name" -e "$1"
}

expect() {
  local label=$1 want=$2 got=$3
  if [[ "$got" != "$want" ]]; then
    echo "FAIL $label: expected '$want', got '$got'" >&2
    exit 1
  fi
  echo "ok $label"
}

sql "DROP TABLE IF EXISTS channel, media, delete_channel"
sed 's/^DROP TABLE.*//' "$repository_root/hub/tables/channel.sql" | mariadb "$db_name"
mariadb "$db_name" < "$repository_root/common/tables/media.sql"
sql "CREATE TABLE delete_channel (uid VARCHAR(16), ref_sys_id INT)"
mariadb "$db_name" < "$repository_root/common/procedures/channel/channel_media_stats.sql"
mariadb "$db_name" < "$repository_root/common/procedures/channel/channel_media_list.sql"

sql "INSERT INTO media (id, parent_path, user_filename, extension, mimetype, category, status, metadata) VALUES
 ('img1','/','a','png','image/png','image','active','{}'),
 ('img2','/','b','svg','image/svg+xml','vector','active','{}'),
 ('vid1','/','c','mp4','video/mp4','video','active','{\"duration\":32}'),
 ('doc1','/','Q1.docx','docx','application/x','document','active','{}'),
 ('gone','/','old','png','image/png','image','deleted','{}')"
sql "INSERT INTO channel (author_id, message, message_id, attachment, status, ctime, file_thread_id) VALUES
 ('u1','pics','m1','[{\"hub_id\":\"h\",\"nid\":\"img1\"},{\"hub_id\":\"h\",\"nid\":\"img2\"}]','active',100,NULL),
 ('u1','clip','m2','[{\"hub_id\":\"h\",\"nid\":\"vid1\"}]','active',200,NULL),
 ('u1','doc','m3','[{\"hub_id\":\"h\",\"nid\":\"doc1\"}]','active',300,NULL),
 ('u1','trashed file','m4','[{\"hub_id\":\"h\",\"nid\":\"gone\"}]','active',400,NULL),
 ('u1','other hub','m5','[{\"hub_id\":\"x\",\"nid\":\"nothere\"}]','active',500,NULL),
 ('u1','see <a href=\"https://x.io/a\">x</a>','m6',NULL,'active',600,NULL),
 ('u1','plain https://y.io/b ok','m7',NULL,'active',700,NULL),
 ('u1','thread link https://z.io','m8',NULL,'active',800,'ft1'),
 ('u1','deleted for me https://w.io','m9',NULL,'active',900,NULL)"
sql "INSERT INTO delete_channel (uid, ref_sys_id) SELECT 'me', sys_id FROM channel WHERE message_id='m9'"

expect "stats photos/videos/files/links" $'2\t1\t1\t2' "$(sql "CALL channel_media_stats('me')")"
expect "photo page newest first" $'img2\nimg1' "$(sql "CALL channel_media_list('me','photo',1)" | cut -f1)"
expect "video page duration" $'vid1\t32' "$(sql "CALL channel_media_list('me','video',1)" | cut -f1,6)"
expect "file page" 'doc1' "$(sql "CALL channel_media_list('me','file',1)" | cut -f1)"
expect "link urls cut clean from HTML" $'m7\thttps://y.io/b\nm6\thttps://x.io/a' \
  "$(sql "CALL channel_media_list('me','link',1)" | cut -f1,4)"
expect "page 2 empty" '' "$(sql "CALL channel_media_list('me','photo',2)")"
expect "unknown kind empty" '' "$(sql "CALL channel_media_list('me','bogus',1)")"
echo "PASS chat-details-media"
