#!/usr/bin/env bash
set -euo pipefail

db_name=${1:?usage: notification-feed-dismissal.sh <disposable-db>}
case "$db_name" in
  notification_feed_dismiss_test_*) ;;
  *) echo "refusing non-test database: $db_name" >&2; exit 2 ;;
esac

repository_root=$(cd "$(dirname "$0")/.." && pwd)

sql() {
  mariadb --batch --skip-column-names "$db_name" -e "$1"
}

sql "DROP TABLE IF EXISTS contact_activity; CREATE TABLE contact_activity (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  timestamp INT UNSIGNED NOT NULL,
  uid VARCHAR(16) NOT NULL,
  target_uid VARCHAR(16) NOT NULL,
  event VARCHAR(100) NOT NULL,
  dismissed_at INT UNSIGNED DEFAULT NULL,
  PRIMARY KEY (id)
)"

sql "INSERT INTO contact_activity(timestamp,uid,target_uid,event,dismissed_at)
  VALUES (UNIX_TIMESTAMP(),'actor','recipient','task_mention',123)"

mariadb "$db_name" < "$repository_root/yellow_page/patches/add-contact-activity-hidden-at.sql"
mariadb "$db_name" < "$repository_root/yellow_page/patches/add-contact-activity-hidden-at.sql"

legacy_hidden=$(sql "SELECT hidden_at FROM contact_activity WHERE id=1")
if [[ "$legacy_hidden" != '123' ]]; then
  echo "FAIL legacy hide backfill: expected 123, got '$legacy_hidden'" >&2
  exit 1
fi

sed "s/yp\.contact_activity/\`$db_name\`.contact_activity/g" \
  "$repository_root/drumate/procedures/contact_activity_dismiss.sql" | mariadb "$db_name"

sql "INSERT INTO contact_activity(timestamp,uid,target_uid,event)
  VALUES (UNIX_TIMESTAMP(),'actor','recipient','task_assigned')"
sql "CALL contact_activity_dismiss('different-user',2)" >/dev/null
cross_user_state=$(sql "SELECT IF(dismissed_at IS NULL,0,1),IF(hidden_at IS NULL,0,1)
  FROM contact_activity WHERE id=2")
if [[ "$cross_user_state" != $'0\t0' ]]; then
  echo "FAIL cross-user contact dismiss changed row: got '$cross_user_state'" >&2
  exit 1
fi
sql "CALL contact_activity_dismiss('recipient',2)" >/dev/null

state=$(sql "SELECT IF(dismissed_at IS NULL,0,1),IF(hidden_at IS NULL,0,1)
  FROM contact_activity WHERE id=2")
if [[ "$state" != $'1\t1' ]]; then
  echo "FAIL contact dismiss state: expected read+hidden, got '$state'" >&2
  exit 1
fi

sql "INSERT INTO contact_activity(timestamp,uid,target_uid,event,dismissed_at)
  VALUES (UNIX_TIMESTAMP(),'actor','recipient','storage_alert',456)"
mariadb "$db_name" < "$repository_root/yellow_page/patches/add-contact-activity-hidden-at.sql"
replay_hidden=$(sql "SELECT IFNULL(hidden_at,0) FROM contact_activity WHERE id=3")
if [[ "$replay_hidden" != '0' ]]; then
  echo "FAIL replay hid a newly read row: expected 0, got '$replay_hidden'" >&2
  exit 1
fi

index_columns=$(sql "SELECT COUNT(*) FROM information_schema.statistics
  WHERE table_schema='$db_name' AND table_name='contact_activity'
    AND index_name='idx_target_hidden_time'")
if [[ "$index_columns" != '4' ]]; then
  echo "FAIL contact history index columns: expected 4, got $index_columns" >&2
  exit 1
fi

grep -q 'c.hidden_at IS NULL' "$repository_root/drumate/procedures/activity_get_feed_all.sql"
grep -q 'dm.changelog_id IS NULL' "$repository_root/drumate/procedures/activity_get_feed_all.sql"

echo 'notification feed dismissal tests: PASS'
