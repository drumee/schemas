#!/usr/bin/env bash
# chat-details-p2p-media.sh — p2p_media_stats / p2p_media_list: both sides of
# a DM (each message is stored only in its sender's p2p_channel), attachments
# resolved in their own wicket hub, a missing peer DB tolerated.
#   tests/chat-details-p2p-media.sh
set -euo pipefail
repository_root=$(cd "$(dirname "$0")/.." && pwd)
ME=chat_details_test_me; PEER=chat_details_test_peer
SBME=chat_details_test_sboxme; SBPEER=chat_details_test_sboxpeer
for d in $ME $PEER $SBME $SBPEER; do
  mariadb -e "DROP DATABASE IF EXISTS $d; CREATE DATABASE $d CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci"
done
sql() { mariadb --batch --skip-column-names "$1" -e "$2"; }
expect() { [[ "$3" == "$2" ]] && echo "ok $1" || { echo "FAIL $1: expected '$2', got '$3'" >&2; exit 1; }; }

# fake yp.entity lives in $ME; procs are rewritten to read it there
sql $ME "CREATE TABLE entity (id VARCHAR(16), db_name VARCHAR(64), type VARCHAR(16));
INSERT INTO entity VALUES ('uMe','$ME','drumate'),('uPeer','$PEER','drumate'),
 ('hMe','$SBME','hub'),('hPeer','$SBPEER','hub'),('hGone','chat_details_test_gone','hub')"
for d in $ME $PEER; do
  sed 's/^DROP TABLE.*//' "$repository_root/drumate/tables/p2p_channel.sql" | mariadb $d
done
for d in $SBME $SBPEER; do mariadb $d < "$repository_root/common/tables/media.sql"; done
sql $SBME "INSERT INTO media (id,parent_path,user_filename,extension,mimetype,category,status,metadata) VALUES
 ('i1','/','a','png','image/png','image','active','{}'),('d1','/','Q1.docx','docx','x','document','active','{}')"
sql $SBPEER "INSERT INTO media (id,parent_path,user_filename,extension,mimetype,category,status,metadata) VALUES
 ('v1','/','clip','mp4','video/mp4','video','active','{}'),('i2','/','old','png','image/png','image','deleted','{}')"
sql $ME "INSERT INTO p2p_channel (peer_id,author_id,message,message_id,attachment,status,ctime) VALUES
 ('uPeer','uMe','pic','m1','[{\"hub_id\":\"hMe\",\"nid\":\"i1\"},{\"hub_id\":\"hMe\",\"nid\":\"d1\"}]','active',100),
 ('uPeer','uMe','see https://x.io/a','m2',NULL,'active',200),
 ('uOther','uMe','not this dm https://z.io','m3',NULL,'active',300)"
sql $PEER "INSERT INTO p2p_channel (peer_id,author_id,message,message_id,attachment,status,ctime) VALUES
 ('uMe','uPeer','clip','m4','[{\"hub_id\":\"hPeer\",\"nid\":\"v1\"},{\"hub_id\":\"hPeer\",\"nid\":\"i2\"}]','active',400),
 ('uMe','uPeer','gone hub','m5','[{\"hub_id\":\"hGone\",\"nid\":\"x\"}]','active',500)"
for p in p2p_media_stats p2p_media_list; do
  sed "s/yp\./\`$ME\`./g" "$repository_root/drumate/procedures/chat/$p.sql" | mariadb $ME
done
expect "stats both sides, deleted + missing hub skipped" $'1\t1\t1\t1' "$(sql $ME "CALL p2p_media_stats('uPeer')")"
expect "photo row carries its hub" $'i1\thMe' "$(sql $ME "CALL p2p_media_list('uPeer','photo',1)" | cut -f1,2)"
expect "video from the peer's side" $'v1\thPeer' "$(sql $ME "CALL p2p_media_list('uPeer','video',1)" | cut -f1,2)"
expect "links of this DM only" $'m2\thttps://x.io/a' "$(sql $ME "CALL p2p_media_list('uPeer','link',1)" | cut -f1,4)"
sql $ME "DELETE FROM entity WHERE id='uPeer'"
expect "missing peer DB → viewer side only" $'1\t0\t1\t1' "$(sql $ME "CALL p2p_media_stats('uPeer')")"
for d in $ME $PEER $SBME $SBPEER; do mariadb -e "DROP DATABASE $d"; done
echo "PASS chat-details-p2p-media"
