#!/bin/bash
# =========================================================
# file-move-backfill.sh
#
# Nạp lại batch artifact cho cross-hub file-thread move vào các DB
# thiếu. Idempotent (mọi file là DROP IF EXISTS + CREATE / CREATE
# TABLE IF NOT EXISTS).
#
# Dùng:
#   ./file-move-backfill.sh --dry-run          # chỉ liệt kê, không ghi
#   ./file-move-backfill.sh --db <db_name>     # một DB
#   ./file-move-backfill.sh --all              # mọi DB sống thiếu artifact
#
# VÌ SAO KHÔNG DÙNG bin/patch-from-file:
#   Script đó truyền --orphan=remove --force. Khi client trả lỗi 1049
#   (unknown database), bin/patch.js:69-76 gọi yp entity_delete →
#   DROP DATABASE + xoá 10 bảng identity, không hỏi. Xảy ra khi entity
#   còn trong yp.entity nhưng schema tạm không truy cập được (đang
#   restore, quyền, tên lệch case). Script này chỉ ghi proc/bảng.
#
#   bin/patch-from-file cũng chạy SET GLOBAL character_set_collations —
#   đổi cấu hình toàn server tới khi restart. Script này không đụng.
#
# Snapshot proc cũ được lưu vào ./backup-<timestamp>/ TRƯỚC khi ghi.
# Đây là đường lùi — KHÔNG dùng full-DB restore để rollback một proc.
# =========================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCHEMAS_DIR="$(dirname "$SCRIPT_DIR")"
MYSQL="${MYSQL_BIN:-mariadb}"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$SCRIPT_DIR/backup-$STAMP"

# Batch artifact 2026-07-26. Thứ tự QUAN TRỌNG: bảng trước, proc phụ
# thuộc sau. mfs_move_all cuối cùng vì nó CALL channel_migrate_moved_scope.
# Mọi proc được liệt kê trong query chọn DB (bên dưới) PHẢI có file tương
# ứng ở đây, nếu không script chọn DB rồi apply thiếu — DB vẫn không đủ.
FILES=(
  "common/tables/channel_migrate_log.sql"
  "common/procedures/channel/channel_migrate_moved_scope.sql"
  "common/procedures/channel/channel_file_thread_rebind_returned_file.sql"
  "common/procedures/channel/channel_file_thread_resolve_access.sql"
  "common/procedures/channel/channel_file_thread_list_by_folder.sql"
  "common/procedures/channel/channel_file_thread_trashed_filename.sql"
  "common/procedures/channel/channel_file_thread_info.sql"
  "common/procedures/channel/channel_file_thread_ensure_root.sql"
  "common/procedures/channel/channel_file_thread_list_messages.sql"
  "common/procedures/channel/channel_file_thread_read_messages.sql"
  "common/procedures/channel/channel_file_thread_post_touch.sql"
  "common/procedures/channel/channel_file_thread_remove_root.sql"
  "common/procedures/mfs/file_move_source_snapshot.sql"
  "common/procedures/mfs/file_move_destination_snapshot.sql"
  "common/procedures/mfs/file_move_return_precheck.sql"
  "common/procedures/mfs/file_move_thread_position.sql"
  "common/procedures/mfs/mfs_move_all.sql"
)

# Proc cần snapshot trước khi ghi đè (để rollback được)
SNAPSHOT_PROCS=(
  "mfs_move_all"
  "channel_migrate_moved_scope"
  "channel_file_thread_rebind_returned_file"
  "file_move_thread_position"
)

DRY_RUN=0
TARGET_DB=""
DO_ALL=0

usage() {
  cat <<'EOF'
file-move-backfill.sh — nap batch artifact cross-hub file-thread move

  --dry-run           liet ke DB can backfill, khong ghi gi
  --db <db_name>      backfill mot DB
  --all               backfill moi DB song thieu artifact
  -h, --help          man hinh nay

Bien moi truong:
  MYSQL_BIN           lenh client (mac dinh: mariadb)

Vi du:
  ./file-move-backfill.sh --dry-run
  ./file-move-backfill.sh --db 6_fb610d28fb610d29
  ./file-move-backfill.sh --all
EOF
  exit "${1:-0}"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --db)      TARGET_DB="${2:-}"; shift 2 ;;
    --all)     DO_ALL=1; shift ;;
    -h|--help) usage 0 ;;
    *) echo "Tham so khong hop le: $1" >&2; usage 2 ;;
  esac
done

# --dry-run mot minh mac dinh la khao sat toan bo — no khong ghi gi nen
# khong can bat buoc chon pham vi.
if [ "$DRY_RUN" -eq 1 ] && [ -z "$TARGET_DB" ]; then
  DO_ALL=1
fi

if [ -z "$TARGET_DB" ] && [ "$DO_ALL" -eq 0 ]; then
  echo "Phai chon --db <name> hoac --all (hoac --dry-run de khao sat)" >&2
  usage 2
fi

# --- Kiểm tra file nguồn tồn tại trước khi làm gì ---
missing=0
for f in "${FILES[@]}"; do
  if [ ! -f "$SCHEMAS_DIR/$f" ]; then
    echo "THIEU FILE NGUON: $SCHEMAS_DIR/$f" >&2
    missing=1
  fi
done
[ "$missing" -eq 1 ] && { echo "Dung: thieu file nguon." >&2; exit 1; }

# --- Xác định danh sách DB ---
if [ -n "$TARGET_DB" ]; then
  DBS="$TARGET_DB"
else
  # DB sống thiếu ÍT NHẤT MỘT artifact. Hai điều kiện dễ sai:
  #  - LEFT JOIN từ yp.entity, KHÔNG phải INNER JOIN mysql.proc: DB thiếu
  #    hẳn proc không có row trong mysql.proc nên INNER JOIN bỏ sót nó.
  #  - Danh sách proc ở đây phải khớp CHÍNH XÁC với Q1 của
  #    file-move-audit.sql. Lệch một proc thì backfill bỏ qua DB mà audit
  #    vẫn báo thiếu — âm thầm, không lỗi. (Đã xảy ra thật trên stage với
  #    channel_file_thread_resolve_access.)
  DBS=$($MYSQL -N -B -e "
    SELECT e.db_name
    FROM yp.entity e
    LEFT JOIN mysql.proc p ON p.db = e.db_name
    WHERE e.status = 'active'
    GROUP BY e.db_name
    HAVING MAX(p.name='mfs_move_all'
               AND p.body LIKE '%channel_migrate_moved_scope%') = 0
        OR MAX(p.name='channel_migrate_moved_scope') = 0
        OR MAX(p.name='file_move_thread_position') = 0
        OR MAX(p.name='channel_file_thread_rebind_returned_file') = 0
        OR MAX(p.name='file_move_source_snapshot') = 0
        OR MAX(p.name='file_move_destination_snapshot') = 0
        OR MAX(p.name='file_move_return_precheck') = 0
        OR MAX(p.name='channel_file_thread_resolve_access') = 0
        OR MAX(p.name='channel_file_thread_info') = 0
        OR MAX(p.name='channel_file_thread_list_by_folder') = 0
        OR MAX(p.name='channel_file_thread_ensure_root') = 0;")
fi

if [ -z "$DBS" ]; then
  echo "Khong co DB nao can backfill. Xong."
  exit 0
fi

count=$(echo "$DBS" | wc -w | tr -d ' ')
echo "DB can backfill: $count"
echo "$DBS" | tr ' ' '\n' | sed 's/^/  /'
echo

if [ "$DRY_RUN" -eq 1 ]; then
  echo "--dry-run: khong ghi gi. File se apply cho moi DB:"
  printf '  %s\n' "${FILES[@]}"
  exit 0
fi

# --- Snapshot proc cũ (đường lùi) ---
mkdir -p "$BACKUP_DIR"
echo "Snapshot proc cu vao: $BACKUP_DIR"
for db in $DBS; do
  out="$BACKUP_DIR/$db.sql"
  {
    echo "-- Snapshot $db truoc backfill $STAMP"
    echo "-- Rollback: mariadb $db < $(basename "$out")"
    echo "DELIMITER \$"
    for proc in "${SNAPSHOT_PROCS[@]}"; do
      body=$($MYSQL -N -B -e \
        "SELECT body FROM mysql.proc WHERE db='$db' AND name='$proc'" 2>/dev/null)
      [ -z "$body" ] && continue
      params=$($MYSQL -N -B -e \
        "SELECT param_list FROM mysql.proc WHERE db='$db' AND name='$proc'" 2>/dev/null)
      echo "DROP PROCEDURE IF EXISTS \`$proc\`\$"
      # body/param_list luu \n dang literal — khoi phuc lai xuong dong
      printf 'CREATE PROCEDURE `%s`(%s)\n%s\n$\n' \
        "$proc" \
        "$(printf '%b' "$params")" \
        "$(printf '%b' "$body")"
    done
    echo "DELIMITER ;"
  } > "$out"
  lines=$(wc -l < "$out" | tr -d ' ')
  echo "  $db -> $lines dong"
  if [ "$lines" -lt 4 ]; then
    echo "  CANH BAO: snapshot $db gan nhu rong — DB nay co the thieu han proc." >&2
  fi
done
echo

# --- Apply ---
ok=0; err=0
for db in $DBS; do
  echo "=== $db ==="
  for f in "${FILES[@]}"; do
    out=$($MYSQL "$db" < "$SCHEMAS_DIR/$f" 2>&1)
    if [ -n "$out" ]; then
      echo "  LOI $f: $out" >&2
      err=$((err + 1))
    else
      ok=$((ok + 1))
    fi
  done
done
echo
echo "APPLY XONG: ok=$ok loi=$err"

# --- Verify ---
echo
echo "=== Verify ==="
# Dùng yp.file_move_readiness — cùng một nguồn sự thật với precondition-check
# trong _beginCrossHubMove, nên "verify pass" ở đây nghĩa đúng là "server sẽ
# cho phép move". Tự liệt kê proc ở đây từng khiến verify báo OK cho DB vẫn
# còn thiếu artifact.
verify_fail=0
for db in $DBS; do
  res=$($MYSQL -N -B -e "CALL yp.file_move_readiness('$db');" 2>&1)
  ready=$(echo "$res" | awk '{print $2}')
  if [ "$ready" = "1" ]; then
    echo "  $db: ready"
  else
    echo "  $db: CHUA SAN SANG -> $(echo "$res" | cut -f3-)" >&2
    verify_fail=$((verify_fail + 1))
  fi
done
[ "$verify_fail" -gt 0 ] && echo "CANH BAO: $verify_fail DB van chua san sang." >&2

echo
echo "Neu co loi: rollback tung DB bang"
echo "  mariadb <db> < $BACKUP_DIR/<db>.sql"
echo
echo "Buoc tiep: chay lai audit"
echo "  mariadb < $SCRIPT_DIR/file-move-audit.sql"

[ "$err" -gt 0 ] || [ "$verify_fail" -gt 0 ] && exit 1
exit 0
