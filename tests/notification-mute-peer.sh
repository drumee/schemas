#!/usr/bin/env bash
# notification-mute-peer.sh — per-person popup mute rows: set is idempotent
# and keeps the first ctime; unset one; unset '' clears all; rows are per uid.
#   tests/notification-mute-peer.sh
set -euo pipefail
db=chat_details_test_mutepeer
repository_root=$(cd "$(dirname "$0")/.." && pwd)
mariadb -e "DROP DATABASE IF EXISTS $db; CREATE DATABASE $db CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci"
sql() { mariadb --batch --skip-column-names "$db" -e "$1"; }
expect() { [[ "$3" == "$2" ]] && echo "ok $1" || { echo "FAIL $1: expected '$2', got '$3'" >&2; exit 1; }; }
mariadb "$db" < "$repository_root/yellow_page/tables/notification_mute_peer.sql"
for p in set unset state; do
  mariadb "$db" < "$repository_root/yellow_page/procedures/notification/notification_mute_peer_$p.sql"
done
expect "set returns the row" "pA" "$(sql "CALL notification_mute_peer_set('me','pA')" | cut -f1)"
sql "CALL notification_mute_peer_set('me','pA')" >/dev/null
sql "CALL notification_mute_peer_set('me','pB')" >/dev/null
sql "CALL notification_mute_peer_set('other','pA')" >/dev/null
expect "idempotent, per uid" $'pA\npB' "$(sql "CALL notification_mute_peer_state('me')" | cut -f1)"
expect "unset one" "pB" "$(sql "CALL notification_mute_peer_unset('me','pA')" | cut -f1)"
expect "unset all" "" "$(sql "CALL notification_mute_peer_unset('me','')")"
expect "other user untouched" "pA" "$(sql "CALL notification_mute_peer_state('other')" | cut -f1)"
mariadb -e "DROP DATABASE $db"
echo "PASS notification-mute-peer"
