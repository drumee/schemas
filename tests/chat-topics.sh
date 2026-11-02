#!/usr/bin/env bash
# chat-topics.sh — folder chat topics: create (unique per folder), list with
# per-topic unread (own messages never count), topic message page, mark read
# clears one topic only.
#   tests/chat-topics.sh
set -euo pipefail
repository_root=$(cd "$(dirname "$0")/.." && pwd)
db=chat_details_test_topics
mariadb -e "DROP DATABASE IF EXISTS $db; CREATE DATABASE $db CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci"
sql() { mariadb --batch --skip-column-names "$db" -e "$1"; }
expect() { [[ "$3" == "$2" ]] && echo "ok $1" || { echo "FAIL $1: expected '$2', got '$3'" >&2; exit 1; }; }
sed 's/^DROP TABLE.*//' "$repository_root/hub/tables/channel.sql" | mariadb $db
# existing hubs get the indexed topic_id column through the patch (idempotent)
mariadb $db < "$repository_root/patches/channel_topic_id.sql"
mariadb $db < "$repository_root/patches/channel_topic_id.sql"
expect "channel.topic_id is indexed" "1" "$(sql "SELECT COUNT(DISTINCT index_name) FROM information_schema.statistics WHERE table_schema='$db' AND table_name='channel' AND index_name='channel_topic_idx'")"
mariadb $db < "$repository_root/hub/tables/delete_channel.sql"
mariadb $db < "$repository_root/common/tables/read_channel.sql"
for t in channel_topic channel_topic_read; do mariadb $db < "$repository_root/hub/tables/$t.sql"; done
# hub-local helpers the procs use (present in every hub DB)
mariadb $db < "$repository_root/common/procedures/utils/pageToLimits.sql"
mariadb $db < "$repository_root/common/procedures/utils/uniqueId.sql"
mariadb $db < "$repository_root/utils/procedures/read_json_object.sql"
# fake yp.drumate / yp.dmz_user live in $db; procs are rewritten to read them there
sql "CREATE TABLE drumate (id VARCHAR(16), firstname VARCHAR(128), lastname VARCHAR(128), fullname VARCHAR(255), email VARCHAR(255));
CREATE TABLE dmz_user (id VARCHAR(16), name VARCHAR(255), email VARCHAR(255))"
for p in channel_topic_create channel_topic_list channel_topic_get channel_topic_messages channel_topic_mark_read channel_general_messages; do
  sed "s/yp\./\`$db\`./g" "$repository_root/hub/procedures/channel/$p.sql" | mariadb $db
done
T1=$(sql "CALL channel_topic_create('uMe','fA','Design','😀')" | cut -f1)
T2=$(sql "CALL channel_topic_create('uMe','fA','Budget','💰')" | cut -f1)
expect "ids are 16 chars" "16" "${#T1}"
expect "duplicate name (any case) in the same folder" "TOPIC_EXISTS" "$(sql "CALL channel_topic_create('uX','fA','design','🔥')" | tail -1 | awk -F'\t' '{print $NF}')"
expect "same name in another folder is fine" "16" "$(sql "CALL channel_topic_create('uMe','fB','Design','😀')" | cut -f1 | tr -d '\n' | wc -c)"
sql "INSERT INTO channel (author_id,message,message_id,status,ctime,metadata) VALUES
 ('uPeer','t1 a','m1','active',1,'{\"_scope_nid\":\"fA\",\"_topic_id\":\"$T1\"}'),
 ('uPeer','t1 b','m2','active',2,'{\"_scope_nid\":\"fA\",\"_topic_id\":\"$T1\"}'),
 ('uMe','t1 mine','m3','active',3,'{\"_scope_nid\":\"fA\",\"_topic_id\":\"$T1\"}'),
 ('uPeer','t2 a','m4','active',4,'{\"_scope_nid\":\"fA\",\"_topic_id\":\"$T2\"}'),
 ('uPeer','general','m5','active',5,'{\"_scope_nid\":\"fA\"}')"
expect "list: oldest first, own messages never unread" $'Design\t2\nBudget\t1' "$(sql "CALL channel_topic_list('uMe','fA')" | awk -F'\t' '{print $3"\t"$7}')"
expect "topic page: only its messages" $'m1\nm2\nm3' "$(sql "CALL channel_topic_messages('uMe','$T1','asc',1)" | awk -F'\t' '{print $5}' | sort)"
expect "general page: no topic messages" "m5" "$(sql "CALL channel_general_messages('uMe','desc',1)" | awk -F'\t' '{print $5}')"
# 50 more topic messages: a General page must still be full-length (paging)
sql "INSERT INTO channel (author_id,message,message_id,status,ctime,metadata)
 SELECT 'uPeer','bulk',CONCAT('b',seq),'active',10+seq,'{\"_topic_id\":\"$T2\"}' FROM seq_1_to_50"
sql "INSERT INTO channel (author_id,message,message_id,status,ctime,metadata)
 SELECT 'uPeer','g',CONCAT('g',seq),'active',100+seq,'{}' FROM seq_1_to_60"
expect "general page 1 is full (45) despite interleaved topic rows" "45" "$(sql "CALL channel_general_messages('uMe','desc',1)" | wc -l)"
expect "general page 2 continues" "16" "$(sql "CALL channel_general_messages('uMe','desc',2)" | wc -l)"
sql "DELETE FROM channel WHERE message_id LIKE 'b%' OR message_id LIKE 'g%'"
sql "CALL channel_topic_mark_read('uMe','$T1')" >/dev/null
expect "mark_read stamps _seen_ on that topic only" $'m1\t1\nm4\t0\nm5\t0' "$(sql "SELECT message_id, JSON_EXISTS(metadata,'\$._seen_.uMe') FROM channel WHERE message_id IN ('m1','m4','m5') ORDER BY message_id")"
expect "mark_read clears one topic only" $'Design\t0\nBudget\t1' "$(sql "CALL channel_topic_list('uMe','fA')" | awk -F'\t' '{print $3"\t"$7}')"
expect "get: folder is returned for the check" "fA" "$(sql "CALL channel_topic_get('$T1')" | cut -f2)"
mariadb -e "DROP DATABASE $db"
echo "PASS chat-topics"
