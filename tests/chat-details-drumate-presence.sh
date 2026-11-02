#!/usr/bin/env bash
# chat-details-drumate-presence.sh — drumate_presence(_ids JSON): one row per
# EXISTING user in the list, online from a live socket, last_seen the newest
# session-cookie mtime (live yp.socket has no mtime), 0 when unknown.
#   tests/chat-details-drumate-presence.sh
set -euo pipefail
db=chat_details_test_yp
repository_root=$(cd "$(dirname "$0")/.." && pwd)
mariadb -e "DROP DATABASE IF EXISTS $db; CREATE DATABASE $db CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci"
sql() { mariadb --batch --skip-column-names "$db" -e "$1"; }
sql "CREATE TABLE drumate (id VARCHAR(16), email VARCHAR(255), firstname VARCHAR(128), lastname VARCHAR(128), fullname VARCHAR(255));
CREATE TABLE socket (id VARCHAR(32), uid VARCHAR(32), ctime INT NOT NULL DEFAULT 0);
CREATE TABLE cookie (id VARCHAR(64), uid VARCHAR(64), mtime INT NOT NULL DEFAULT 0);
INSERT INTO drumate VALUES ('a','a@x','An','A','An A'),('b','b@x','Bo','B','Bo B');
INSERT INTO socket VALUES ('s1','a',5),('s2','a',6);
INSERT INTO cookie VALUES ('k1','a',100),('k2','b',700),('k3','b',300)"
mariadb "$db" < "$repository_root/yellow_page/procedures/drumate/drumate_presence.sql"
got=$(sql "CALL drumate_presence('[\"a\",\"b\",\"zz\"]')" | cut -f1,6,7)
want=$'a\t1\t100\nb\t0\t700'
mariadb -e "DROP DATABASE $db"
[[ "$got" == "$want" ]] || { echo "FAIL presence: expected '$want', got '$got'" >&2; exit 1; }
echo "PASS chat-details-drumate-presence"
