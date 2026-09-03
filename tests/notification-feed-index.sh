#!/usr/bin/env bash
set -euo pipefail

db_name=${1:?usage: notification-feed-index.sh <disposable-db>}
case "$db_name" in
  notification_feed_index_test_*) ;;
  *) echo "refusing non-test database: $db_name" >&2; exit 2 ;;
esac

repository_root=$(cd "$(dirname "$0")/.." && pwd)

sql() {
  mariadb --batch --skip-column-names "$db_name" -e "$1"
}

sql "DROP TABLE IF EXISTS mfs_changelog; CREATE TABLE mfs_changelog (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  timestamp INT UNSIGNED NOT NULL,
  uid VARCHAR(16),
  hub_id VARCHAR(16) CHARACTER SET ascii,
  event VARCHAR(100),
  src JSON,
  dest JSON,
  PRIMARY KEY (id)
)"

mariadb "$db_name" < "$repository_root/yellow_page/patches/add-mfs-changelog-hub-timestamp-index.sql"
mariadb "$db_name" < "$repository_root/yellow_page/patches/add-mfs-changelog-hub-timestamp-index.sql"

index_count=$(sql "SELECT COUNT(*) FROM information_schema.statistics
  WHERE table_schema='$db_name' AND table_name='mfs_changelog'
    AND index_name='idx_hub_timestamp'")
if [[ "$index_count" != '3' ]]; then
  echo "FAIL index columns: expected 3, got $index_count" >&2
  exit 1
fi

sql "INSERT INTO mfs_changelog(timestamp,uid,hub_id,event,src,dest)
  SELECT seq, 'other-user', IF(MOD(seq,20)=0,'hub-a','hub-b'), 'media.new', '{}', '{}'
  FROM seq_1_to_20000"

selected_key=$(sql "EXPLAIN SELECT id,timestamp FROM mfs_changelog
  WHERE hub_id='hub-a' ORDER BY timestamp DESC,id DESC LIMIT 45" | cut -f6)
if [[ "$selected_key" != 'idx_hub_timestamp' ]]; then
  echo "FAIL query index: expected idx_hub_timestamp, got '$selected_key'" >&2
  exit 1
fi

echo 'notification feed index tests: PASS'
