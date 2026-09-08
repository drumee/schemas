#!/usr/bin/env bash
set -euo pipefail

db_name=${1:?usage: notification-activity-bookmark.sh <disposable-db>}
case "$db_name" in
  notification_activity_bookmark_test_*) ;;
  *) echo "refusing non-test database: $db_name" >&2; exit 2 ;;
esac

repository_root=$(cd "$(dirname "$0")/.." && pwd)
key='aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'

mariadb "$db_name" < "$repository_root/drumate/tables/notification_activity_bookmark.sql"
mariadb "$db_name" < "$repository_root/drumate/procedures/notification/notification_activity_bookmark_add.sql"
mariadb "$db_name" < "$repository_root/drumate/procedures/notification/notification_activity_bookmark_remove.sql"
mariadb "$db_name" < "$repository_root/drumate/procedures/notification/notification_activity_bookmark_list.sql"

sql() {
  mariadb --batch --skip-column-names "$db_name" -e "$1"
}

sql "CALL notification_activity_bookmark_add('$key')" >/dev/null
sql "CALL notification_activity_bookmark_add('$key')" >/dev/null
count=$(sql 'SELECT COUNT(*) FROM notification_activity_bookmark')
if [[ "$count" != '1' ]]; then
  echo "FAIL bookmark idempotency: expected 1, got $count" >&2
  exit 1
fi

listed=$(sql 'CALL notification_activity_bookmark_list()')
if [[ "$listed" != "$key" ]]; then
  echo "FAIL bookmark list" >&2
  exit 1
fi

sql "CALL notification_activity_bookmark_remove('$key')" >/dev/null
count=$(sql 'SELECT COUNT(*) FROM notification_activity_bookmark')
if [[ "$count" != '0' ]]; then
  echo "FAIL bookmark remove" >&2
  exit 1
fi

{
  printf 'INSERT INTO notification_activity_bookmark(bookmark_key,ctime) VALUES '
  for i in $(seq 1 1000); do
    [[ "$i" == '1' ]] || printf ','
    printf "('%064x',%d)" "$i" "$i"
  done
  printf ';\n'
} | mariadb "$db_name"

newest='ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff'
sql "CALL notification_activity_bookmark_add('$newest')" >/dev/null
count=$(sql 'SELECT COUNT(*) FROM notification_activity_bookmark')
if [[ "$count" != '1000' ]]; then
  echo "FAIL bookmark cap: expected 1000, got $count" >&2
  exit 1
fi
oldest=$(printf '%064x' 1)
oldest_count=$(sql "SELECT COUNT(*) FROM notification_activity_bookmark WHERE bookmark_key='$oldest'")
newest_count=$(sql "SELECT COUNT(*) FROM notification_activity_bookmark WHERE bookmark_key='$newest'")
if [[ "$oldest_count" != '0' || "$newest_count" != '1' ]]; then
  echo "FAIL bookmark eviction: oldest=$oldest_count newest=$newest_count" >&2
  exit 1
fi

sql 'DELETE FROM notification_activity_bookmark'
{
  printf 'INSERT INTO notification_activity_bookmark(bookmark_key,ctime) VALUES '
  for i in $(seq 1 999); do
    [[ "$i" == '1' ]] || printf ','
    printf "('%064x',%d)" "$i" "$i"
  done
  printf ';\n'
} | mariadb "$db_name"

pids=()
for i in $(seq 1001 1020); do
  concurrent_key=$(printf '%064x' "$i")
  mariadb "$db_name" -e "CALL notification_activity_bookmark_add('$concurrent_key')" >/dev/null &
  pids+=("$!")
done
for pid in "${pids[@]}"; do
  wait "$pid"
done
count=$(sql 'SELECT COUNT(*) FROM notification_activity_bookmark')
if [[ "$count" != '1000' ]]; then
  echo "FAIL concurrent bookmark cap: expected 1000, got $count" >&2
  exit 1
fi

echo 'notification activity bookmark tests: PASS'
