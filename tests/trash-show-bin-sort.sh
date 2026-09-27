#!/usr/bin/env bash
# Exercises mfs_show_bin_sorted's three sorts and the mfs_show_bin wrapper
# against two throwaway databases (a user DB and one shared hub DB). The
# procs are loaded with yp.entity / yp.trash_expiry_config rewritten to
# tables inside the test DB, so nothing is written to yp. yp.filecap,
# yp.drumate and yp.vhost() are still read from the real yp.
#
#   tests/trash-show-bin-sort.sh trash_show_bin_test_1
set -euo pipefail

db=${1:?usage: trash-show-bin-sort.sh <disposable-db>}
case "$db" in
  trash_show_bin_test_*) ;;
  *) echo "refusing non-test database: $db" >&2; exit 2 ;;
esac
hub_db="${db}_hub"
root=$(cd "$(dirname "$0")/.." && pwd)
uid='tsbuser000000001'
hub='tsbhub0000000001'
other='tsbother00000001'

q() { mariadb --batch --skip-column-names "$1" -e "$2"; }
# Drop the throwaway DBs however the run ends, failures included.
cleanup() { for d in "$db" "$hub_db"; do mariadb -e "DROP DATABASE IF EXISTS \`$d\`"; done; }
trap cleanup EXIT

for d in "$db" "$hub_db"; do
  mariadb -e "DROP DATABASE IF EXISTS \`$d\`;
    CREATE DATABASE \`$d\` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci"
  mariadb "$d" < "$root/common/tables/media.sql"
  mariadb "$d" < "$root/common/tables/trash_media.sql"
done
mariadb "$db" < "$root/common/tables/permission.sql"
mariadb "$db" < "$root/common/procedures/utils/pageToLimits.sql"

q "$db" "CREATE TABLE entity (
    id VARCHAR(16) CHARACTER SET ascii, db_name VARCHAR(255),
    home_dir VARCHAR(512) DEFAULT '', home_id VARCHAR(16), status VARCHAR(16));
  INSERT INTO entity VALUES
    ('$uid', '$db', '/tmp/u', 'tsbuhome00000001', 'active'),
    ('$hub', '$hub_db', '/tmp/h', 'tsbhhome00000001', 'active');
  CREATE TABLE trash_expiry_config (expiry_days INT UNSIGNED NOT NULL);
  INSERT INTO trash_expiry_config VALUES (30);
  INSERT INTO media (id, parent_path, mimetype, category, status, user_filename)
    VALUES ('$hub', '', 'hub', 'hub', 'active', 'Shared');
  INSERT INTO permission (resource_id, entity_id, permission)
    VALUES ('$hub', '$uid', 31);"

load() {
  sed -e "s/yp\.entity/\`$db\`.entity/g" \
      -e "s/yp\.trash_expiry_config/\`$db\`.trash_expiry_config/g" \
      "$root/common/procedures/mfs-trash/$1" | mariadb "$db"
}
load mfs_show_bin_sorted.sql
load mfs_show_bin.sql

# row <db> <sys_id> <id> <name> <days-ago|legacy> <owner>
row() {
  local t="UNIX_TIMESTAMP(CURDATE() - INTERVAL $5 DAY + INTERVAL 12 HOUR)"
  [[ "$5" == legacy ]] && t=0
  q "$1" "INSERT INTO trash_media (sys_id, id, origin_id, owner_id,
      user_filename, parent_id, parent_path, mimetype, category, extension,
      status, trashed_time)
    VALUES ($2, '$3', '$6', '$6', '$4', 'gone000000000001', '/', 'text/plain',
      'document', 'txt', 'deleted', $t)"
}
# Personal drive: days left = 30 - days ago.
row "$db" 1 tsbA100000000001 A1   1  "$uid"   # 29 left
row "$db" 2 tsbA1b0000000001 A1b  1  "$uid"   # 29 left, same instant as A1
row "$db" 3 tsbD240000000001 D24  24 "$uid"   # 6 left: NOT expiring
row "$db" 4 tsbC250000000001 C25  25 "$uid"   # 5 left: expiring (boundary)
row "$db" 5 tsbB260000000001 B26  26 "$uid"   # 4 left
row "$db" 6 tsbL000000000001 L0   legacy "$uid" # unknown time
row "$db" 7 tsbT000000000001 __trash__ 26 "$uid" # never listed
# Shared hub: only the user's own items are listed.
row "$hub_db" 1 tsbH280000000001 H28 28 "$uid"   # 2 left
row "$hub_db" 2 tsbX270000000001 X27 27 "$other" # someone else's

# filename is column 9 of the result set.
names() { q "$db" "$1" | cut -f9 | paste -sd, -; }
fail=0
expect() {
  local got; got=$(names "$2")
  if [[ "$got" != "$3" ]]; then
    echo "FAIL $1: expected $3, got $got" >&2; fail=1
  fi
}

latest='A1,A1b,D24,C25,B26,H28,L0'
expect latest   "CALL mfs_show_bin_sorted(1, 'latest')"   "$latest"
expect earliest "CALL mfs_show_bin_sorted(1, 'earliest')" 'H28,B26,C25,D24,A1,A1b,L0'
expect expiring "CALL mfs_show_bin_sorted(1, 'expiring')" 'H28,B26,C25'
expect unknown  "CALL mfs_show_bin_sorted(1, 'bogus')"    "$latest"
expect null     "CALL mfs_show_bin_sorted(1, NULL)"       "$latest"
expect wrapper  "CALL mfs_show_bin(1)"                  "$latest"

days=$(q "$db" "CALL mfs_show_bin_sorted(1, 'expiring')" | cut -f22 | paste -sd, -)
[[ "$days" == '2,4,5' ]] || { echo "FAIL days_remaining: expected 2,4,5, got $days" >&2; fail=1; }

# A manifest deploy must ship the sorted proc, and before the wrapper that
# calls it.
m="$root/patches/manifest.txt"
sorted_at=$(grep -n 'mfs-trash/mfs_show_bin_sorted.sql' "$m" | head -1 | cut -d: -f1 || true)
wrapper_at=$(grep -n 'mfs-trash/mfs_show_bin.sql' "$m" | head -1 | cut -d: -f1 || true)
if [[ -z "$sorted_at" || -z "$wrapper_at" || "$sorted_at" -ge "$wrapper_at" ]]; then
  echo "FAIL manifest: expected mfs_show_bin_sorted.sql then mfs_show_bin.sql, got '$sorted_at' '$wrapper_at'" >&2; fail=1
fi

[[ $fail == 0 ]] && echo 'trash show_bin sort tests: PASS' || exit 1
