#!/usr/bin/env bash
# channel-search-scoped.sh — chat-header search: matches message text OR an
# attachment's filename, wildcards in the query are literal, scope + per-user
# delete still apply, match_filename names the hit. Runs twice: in a
# general_ci database and in one created with the server default (uca1400 on
# MariaDB 11.8), where the proc's own variables would otherwise clash with the
# general_ci table columns (ERROR 1267, search silently empty).
#   tests/channel-search-scoped.sh
set -euo pipefail
repository_root=$(cd "$(dirname "$0")/.." && pwd)
run() {
db=$1
mariadb -e "DROP DATABASE IF EXISTS $db; CREATE DATABASE $db $2"
sql() { mariadb --batch --skip-column-names "$db" -e "$1"; }
expect() { [[ "$3" == "$2" ]] && echo "ok $1" || { echo "FAIL $1: expected '$2', got '$3'" >&2; exit 1; }; }
sed 's/^DROP TABLE.*//' "$repository_root/hub/tables/channel.sql" | mariadb $db
mariadb $db < "$repository_root/hub/tables/delete_channel.sql"
mariadb $db < "$repository_root/common/tables/media.sql"
# fake yp.drumate / yp.dmz_user live in $db; the proc is rewritten to read them there
sql "CREATE TABLE drumate (id VARCHAR(16), firstname VARCHAR(128), lastname VARCHAR(128));
CREATE TABLE dmz_user (id VARCHAR(16), name VARCHAR(255))"
sed "s/yp\./\`$db\`./g" "$repository_root/common/procedures/channel/channel_search_scoped.sql" | mariadb $db
sql "INSERT INTO drumate VALUES ('uA','Ann','Lee')"
sql "INSERT INTO media (id,user_filename,parent_path,mimetype,category,status,file_path) VALUES
 ('f1','Q3 Budget','/','application/pdf','document','active','/a'),
 ('f2','Résumé final','/','application/pdf','document','active','/b'),
 ('f3','old budget','/','application/pdf','document','deleted','/c'),
 ('f4','file_v2','/','text/plain','document','active','/d')"
sql "INSERT INTO channel (author_id,message,message_id,status,ctime,attachment,file_thread_id) VALUES
 ('uA','the budget is late','m1','active',1,NULL,NULL),
 ('uA','','m2','active',2,'[{\"nid\":\"f1\",\"hub_id\":\"H\"}]',NULL),
 ('uA',NULL,'m3','active',3,'[\"f2\"]',NULL),
 ('uA','see file','m4','active',4,'[{\"nid\":\"f3\",\"hub_id\":\"H\"}]',NULL),
 ('uA','50% done','m5','active',5,NULL,NULL),
 ('uA','500 rows','m6','active',6,NULL,NULL),
 ('uA','file_v2 attached','m7','active',7,'[{\"nid\":\"f4\"}]',NULL),
 ('uA','fileXv2 typo','m8','active',8,NULL,NULL),
 ('uA','budget in a thread','m9','active',9,NULL,'T1'),
 ('uA','budget I deleted','m10','active',10,NULL,NULL),
 ('uA','budget trashed','m11','trashed',11,NULL,NULL)"
sql "INSERT INTO delete_channel (uid,ref_sys_id,ctime) SELECT 'uMe', sys_id, 1 FROM channel WHERE message_id='m10'"
ids() { sql "CALL channel_search_scoped('uMe','$1',$2)" | awk -F'\t' '{print $3}' | paste -sd, -; }
expect "text OR active filename; deleted media, other thread, own-deleted, trashed excluded" "m2,m1" "$(ids budget NULL)"
expect "bare-string attachment + accent/case fold" "m3" "$(ids RESUME NULL)"
expect "match_filename names the matching attachment" $'m2\tQ3 Budget' "$(sql "CALL channel_search_scoped('uMe','q3',NULL)" | awk -F'\t' '{print $3"\t"$7}')"
expect "match_filename is NULL for a text-only hit" "NULL" "$(sql "CALL channel_search_scoped('uMe','late',NULL)" | awk -F'\t' '{print $7}')"
expect "% is literal" "m5" "$(ids '50%' NULL)"
expect "_ is literal" "m7" "$(ids 'file_v2' NULL)"
expect "file-thread scope" "m9" "$(ids budget "'T1'")"
expect "empty thread id = team chat" "m2,m1" "$(ids budget "''")"
# the filename join must use media's id index, not scan media per attachment:
# 300 attachment messages x 1000 media rows is ~300k row reads when it scans
sql "INSERT INTO media (id,user_filename,parent_path,mimetype,file_path)
 SELECT CONCAT('p',seq), CONCAT('pad ',seq), '/', 'x', CONCAT('/p',seq) FROM seq_1_to_1000"
sql "INSERT INTO channel (author_id,message,message_id,status,ctime,attachment)
 SELECT 'uA','filler',CONCAT('x',seq),'active',100+seq, JSON_ARRAY(JSON_OBJECT('nid',CONCAT('p',seq))) FROM seq_1_to_300"
reads=$(sql "FLUSH STATUS; CALL channel_search_scoped('uMe','budget',NULL); SHOW SESSION STATUS LIKE 'Handler_read_rnd_next'" | tail -1 | cut -f2)
expect "filename join reads few rows ($reads)" "small" "$( (( reads < 20000 )) && echo small || echo large)"
mariadb -e "DROP DATABASE $db"
}
run channel_search_scoped_test "CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci"
run channel_search_scoped_default ""
echo "PASS channel-search-scoped"
