#!/usr/bin/env bash
# chat-details-presence.sh — hub_member_presence: one row per member however
# many sockets / cookies they hold, online from a live socket, last_seen the
# newest session-cookie mtime (live yp.socket has no mtime), 0 when unknown. yp.* is redirected into the
# disposable database.
#
#   mariadb -e "CREATE DATABASE chat_details_test_2 CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci"
#   tests/chat-details-presence.sh chat_details_test_2
set -euo pipefail

db_name=${1:?usage: chat-details-presence.sh <disposable-db>}
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

sql "DROP TABLE IF EXISTS permission, drumate, socket, cookie;
CREATE TABLE permission (entity_id VARCHAR(16), resource_id VARCHAR(16), permission INT);
CREATE TABLE drumate (id VARCHAR(16), email VARCHAR(255), firstname VARCHAR(128),
  lastname VARCHAR(128), fullname VARCHAR(255));
CREATE TABLE socket (id VARCHAR(32), uid VARCHAR(32), ctime INT NOT NULL DEFAULT 0);
CREATE TABLE cookie (id VARCHAR(64), uid VARCHAR(64), mtime INT NOT NULL DEFAULT 0)"

sed "s/yp\./\`$db_name\`./g" "$repository_root/hub/procedures/members/hub_member_presence.sql" \
  | mariadb "$db_name"

sql "INSERT INTO drumate VALUES
 ('a','a@x','Lucas','Zoe','Lucas Zoe'),
 ('b','b@x','Jul','Lie','Jullie'),
 ('c','c@x','Ca','Sey','Casey T'),
 ('z','z@x','Not','Member','Not Member');
INSERT INTO permission VALUES ('a','*',63),('a','*',63),('b','*',7),('c','*',7),('z','nid1',7);
INSERT INTO socket VALUES ('s1','a',500),('s2','a',900);
INSERT INTO cookie VALUES ('k1','a',100),('k2','b',700),('k3','b',300)"

expect "one row per member, online first, then last_seen" \
  $'a\t1\t100\nb\t0\t700\nc\t0\t0' \
  "$(sql "CALL hub_member_presence()" | cut -f1,6,7)"
echo "PASS chat-details-presence"
