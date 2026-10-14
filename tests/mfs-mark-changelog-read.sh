#!/usr/bin/env bash
set -euo pipefail

db_name=${1:?usage: mfs-mark-changelog-read.sh <disposable-db>}
case "$db_name" in
  mfs_mark_changelog_read_test_*) ;;
  *) echo "refusing non-test database: $db_name" >&2; exit 2 ;;
esac

repository_root=$(cd "$(dirname "$0")/.." && pwd)

sql() {
  mariadb --batch --skip-column-names "$db_name" -e "$1"
}

sql "DROP TABLE IF EXISTS mfs_changelog, mfs_ack, contact_activity, p2p_time, p2p_read"
sql "CREATE TABLE mfs_changelog (id INT UNSIGNED NOT NULL AUTO_INCREMENT, PRIMARY KEY (id))"
mariadb "$db_name" < "$repository_root/drumate/tables/mfs_ack.sql"
mariadb "$db_name" < "$repository_root/drumate/tables/p2p_time.sql"
mariadb "$db_name" < "$repository_root/drumate/tables/p2p_read.sql"
sql "CREATE TABLE contact_activity (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  target_uid VARCHAR(16) NOT NULL,
  dismissed_at INT UNSIGNED DEFAULT NULL,
  PRIMARY KEY (id)
)"

sed "s/yp\./\`$db_name\`./g" \
  "$repository_root/drumate/procedures/mfs_mark_changelog_read.sql" | mariadb "$db_name"

sql "INSERT INTO mfs_changelog VALUES (), (), ()"
sql "INSERT INTO contact_activity(target_uid) VALUES ('recipient')"
sql "INSERT INTO p2p_time(peer_id, ref_ctime) VALUES ('peer', 99)"

# No last_id: the pointer moves to the newest changelog row.
returned=$(sql "CALL mfs_mark_changelog_read('recipient', 0)" | cut -f2,4)
if [[ "$returned" != $'3\tok' ]]; then
  echo "FAIL returned row: expected last_read_id 3 and ok, got '$returned'" >&2
  exit 1
fi

# An explicit last_id is stored as given, as mfs_mark_all_read stores it.
sql "CALL mfs_mark_changelog_read('recipient', 2)" >/dev/null
pointer=$(sql "SELECT last_read_id FROM mfs_ack WHERE user_id='recipient'")
if [[ "$pointer" != '2' ]]; then
  echo "FAIL explicit last_id: expected 2, got '$pointer'" >&2
  exit 1
fi

# Task, Meeting and Other notifications stay unread.
unread_contact=$(sql "SELECT COUNT(*) FROM contact_activity WHERE dismissed_at IS NULL")
if [[ "$unread_contact" != '1' ]]; then
  echo "FAIL contact_activity row was marked read" >&2
  exit 1
fi

# Direct chats stay unread.
chat_pointers=$(sql "SELECT COUNT(*) FROM p2p_read")
if [[ "$chat_pointers" != '0' ]]; then
  echo "FAIL a p2p read pointer was advanced" >&2
  exit 1
fi

echo 'mfs mark changelog read tests: PASS'
