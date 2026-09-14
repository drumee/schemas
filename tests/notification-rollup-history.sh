#!/usr/bin/env bash
set -euo pipefail

db_name=${1:?usage: notification-rollup-history.sh <disposable-db>}
case "$db_name" in
  notification_rollup_history_test_*) ;;
  *) echo "refusing non-test database: $db_name" >&2; exit 2 ;;
esac

repository_root=$(cd "$(dirname "$0")/.." && pwd)

sql() {
  mariadb --batch --skip-column-names "$db_name" -e "$1"
}

mariadb "$db_name" < "$repository_root/drumate/tables/notification_activity_history.sql"
mariadb "$db_name" < "$repository_root/drumate/procedures/notification/notification_history_snapshot.sql"
mariadb "$db_name" < "$repository_root/drumate/procedures/notification/notification_history_hide.sql"

sql "CALL notification_history_snapshot('chat','peer-a','',120,1000)"
sql "CALL notification_history_snapshot('chat','peer-a','',120,900)"
sql "CALL notification_history_snapshot('teamchat','folder-a','hub-a',33,1100)"
sql "CALL notification_history_snapshot('media','folder-b','hub-b',44,1200)"

count=$(sql "SELECT COUNT(*) FROM notification_activity_history")
if [[ "$count" != '2' ]]; then
  echo "FAIL history count: expected 2, got $count" >&2
  exit 1
fi

chat_ctime=$(sql "SELECT ctime FROM notification_activity_history WHERE category='chat'")
if [[ "$chat_ctime" != '1000' ]]; then
  echo "FAIL history duplicate update: expected 1000, got $chat_ctime" >&2
  exit 1
fi

history_id=$(sql "SELECT history_id FROM notification_activity_history WHERE category='chat'")
sql "CALL notification_history_hide($history_id)" >/dev/null
visible=$(sql "SELECT COUNT(*) FROM notification_activity_history WHERE hidden_at IS NULL")
if [[ "$visible" != '1' ]]; then
  echo "FAIL history hide: expected 1 visible, got $visible" >&2
  exit 1
fi

grep -q "'notification_history'" "$repository_root/drumate/procedures/activity_get_feed_all.sql"
grep -q 'notification_history_snapshot' "$repository_root/drumate/procedures/notification/notification_read.sql"
grep -q 'QUOTE(_key_id)' "$repository_root/drumate/procedures/notification/notification_read.sql"
grep -q 'REPLACE(_hub_db' "$repository_root/drumate/procedures/notification/notification_read.sql"
grep -q 'QUOTE(_key_id)' "$repository_root/drumate/procedures/notification/notification_dismiss.sql"
grep -q 'REPLACE(_hub_db' "$repository_root/drumate/procedures/notification/notification_dismiss.sql"
grep -q 'drumate/procedures/notification/notification_dismiss.sql' "$repository_root/patches/manifest.txt"
grep -q "t.last_sys_id, t.utime, 'personal', 'ticket'" \
  "$repository_root/drumate/procedures/notification/notification_center_next.sql"
grep -q 'IF IFNULL(_lock_acquired, 0) <> 1' \
  "$repository_root/drumate/procedures/notification/notification_activity_bookmark_add.sql"

echo 'notification rollup history tests: PASS'
