#!/usr/bin/env bash
# chat-p2p-export.sh — p2p_export_count / p2p_export_messages: both sides of a
# DM, oldest first, trashed and other DMs excluded, date window, author names,
# a missing peer DB tolerated.
#   tests/chat-p2p-export.sh
set -euo pipefail
repository_root=$(cd "$(dirname "$0")/.." && pwd)
ME=chat_details_test_me; PEER=chat_details_test_peer
for d in $ME $PEER; do
  mariadb -e "DROP DATABASE IF EXISTS $d; CREATE DATABASE $d CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci"
done
sql() { mariadb --batch --skip-column-names "$1" -e "$2"; }
expect() { [[ "$3" == "$2" ]] && echo "ok $1" || { echo "FAIL $1: expected '$2', got '$3'" >&2; exit 1; }; }
# fake yp.entity + yp.drumate live in $ME; procs are rewritten to read them there
sql $ME "CREATE TABLE entity (id VARCHAR(16), db_name VARCHAR(64), type VARCHAR(16));
INSERT INTO entity VALUES ('uMe','$ME','drumate'),('uPeer','$PEER','drumate');
CREATE TABLE drumate (id VARCHAR(16), firstname VARCHAR(128), lastname VARCHAR(128), fullname VARCHAR(255));
INSERT INTO drumate VALUES ('uMe','Me','Mine','Me Mine'),('uPeer','Ann','Peer','Ann Peer')"
for d in $ME $PEER; do
  sed 's/^DROP TABLE.*//' "$repository_root/drumate/tables/p2p_channel.sql" | mariadb $d
done
sql $ME "INSERT INTO p2p_channel (peer_id,author_id,message,message_id,status,ctime) VALUES
 ('uPeer','uMe','hello','m1','active',100),('uPeer','uMe','oops','m2','trashed',150),
 ('uOther','uMe','other dm','m3','active',120)"
sql $PEER "INSERT INTO p2p_channel (peer_id,author_id,message,message_id,status,ctime) VALUES
 ('uMe','uPeer','hi back','m4','active',200)"
for p in p2p_export_count p2p_export_messages; do
  sed "s/yp\./\`$ME\`./g" "$repository_root/drumate/procedures/chat/$p.sql" | mariadb $ME
done
expect "count both sides, trashed + other DM out" "2" "$(sql $ME "CALL p2p_export_count('uPeer',NULL,NULL)")"
expect "oldest first, both sides" $'m1\tuMe\thello\nm4\tuPeer\thi back' "$(sql $ME "CALL p2p_export_messages('uPeer',NULL,NULL,1)" | cut -f1-3)"
expect "author names" $'Me Mine\nAnn Peer' "$(sql $ME "CALL p2p_export_messages('uPeer',NULL,NULL,1)" | cut -f10)"
expect "date window" "1" "$(sql $ME "CALL p2p_export_count('uPeer',150,NULL)")"
expect "page 2 empty" "" "$(sql $ME "CALL p2p_export_messages('uPeer',NULL,NULL,2)")"
# page 0 = the whole conversation in one call (the export is capped at 10k)
sql $ME "INSERT INTO p2p_channel (peer_id,author_id,message,message_id,status,ctime)
 SELECT 'uPeer','uMe',CONCAT('bulk ',seq),CONCAT('b',seq),'active',1000+seq FROM seq_1_to_50"
expect "page 0 returns every message" "52" "$(sql $ME "CALL p2p_export_messages('uPeer',NULL,NULL,0)" | wc -l)"
expect "page 1 still pages (45)" "45" "$(sql $ME "CALL p2p_export_messages('uPeer',NULL,NULL,1)" | wc -l)"
expect "page 0 honours the date window" "3" "$(sql $ME "CALL p2p_export_messages('uPeer',150,1002,0)" | wc -l)"
sql $ME "DELETE FROM p2p_channel WHERE message_id LIKE 'b%'"
sql $ME "DELETE FROM entity WHERE id='uPeer'"
expect "missing peer DB → viewer side only" "1" "$(sql $ME "CALL p2p_export_count('uPeer',NULL,NULL)")"
for d in $ME $PEER; do mariadb -e "DROP DATABASE $d"; done
echo "PASS chat-p2p-export"
