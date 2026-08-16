# Stage health check — cross-workspace file move

Kiểm tra sức khoẻ stage `drumee.in` sau đợt làm việc ngày 2026-08-12 trên luồng
move file giữa các workspace.

**Chạy toàn bộ ở chế độ chỉ đọc.** Không có bước nào ghi dữ liệu. Mọi lệnh chạy
trên host stage với quyền đọc MariaDB và `/data/mfs`.

Số liệu tham chiếu (`expect`) đo lúc 2026-08-12 15:09 (+07). Lệch so với cột này
không đương nhiên là hỏng — đọc phần diễn giải kèm theo từng bước.

---

## Bối cảnh: vì sao cần kiểm

Ngày 12/08 có hai việc xảy ra trên stage:

1. Triển khai cơ chế mới cho chat theo file khi move giữa workspace (thread ở
   lại workspace gốc thay vì bị chép qua database khác).
2. Một sự cố: hạ tầng saga cũ bị gỡ khỏi **database dùng chung**, làm hỏng move
   trên các endpoint khác (`main`, `huan`, `liam`, `vudangnt`). Đã khôi phục
   trong ngày.

Ngoài ra tồn tại **một lỗi có từ trước** (dấu vết sớm nhất 01/08): move giữa
workspace không dời thư mục tệp vật lý. Lỗi này **chưa được sửa**.

---

## Bước 1 — Tiến trình và tài nguyên

```bash
sudo -u www-data HOME=/srv/drumee/runtime/server pm2 list
uptime
free -h | head -2
df -h /data /
```

| Kiểm | Expect |
|---|---|
| Tiến trình `online` | 29 |
| Tiến trình `errored` / `stopped` | 0 |
| Load average | < 2.0 |
| `/data` sử dụng | 4% (1.7T/51T) |
| `/` sử dụng | 51% (208G/431G) |

Có tiến trình `errored` → xem log của chính tiến trình đó trước khi đi tiếp.

---

## Bước 2 — Hạ tầng saga (phải còn nguyên)

Saga là cơ chế move cũ. Endpoint `aaron` không dùng nữa, nhưng **`main`,
`huan`, `liam`, `vudangnt` vẫn dùng**. Database dùng chung, nên thiếu bất kỳ
thành phần nào ở đây là hỏng move trên các endpoint đó.

```bash
mysql -N -e "SELECT COUNT(*) FROM information_schema.TABLES
             WHERE TABLE_SCHEMA='yp' AND TABLE_NAME='file_move_saga'"

mysql -N -e "SELECT COUNT(*) FROM information_schema.ROUTINES
             WHERE ROUTINE_NAME LIKE 'file_move_saga%'"

mysql -N -e "SELECT COUNT(*) FROM information_schema.ROUTINES
             WHERE ROUTINE_NAME IN ('file_move_destination_snapshot',
                                    'file_move_return_precheck',
                                    'file_move_thread_position')"

mysql -N -e "SELECT COUNT(*) FROM information_schema.ROUTINES
             WHERE ROUTINE_NAME='mfs_move_all'
               AND ROUTINE_DEFINITION LIKE '%channel_migrate_moved_scope%'"
```

| Kiểm | Expect | Nếu thấp hơn |
|---|---|---|
| Bảng `yp.file_move_saga` | 1 | **Nghiêm trọng** — move hỏng trên 4 endpoint |
| Procedure `file_move_saga*` | 3 | **Nghiêm trọng** — như trên |
| 3 procedure snapshot/precheck/position | 3030 (1010 database × 3) | Thiếu ở database nào thì move hỏng ở workspace đó |
| `mfs_move_all` còn gọi migrate | 1216 | Phải bằng tổng số `mfs_move_all` |

Bản lưu trữ nếu cần khôi phục:
`/srv/drumee/runtime/server/aaron/.backup-260812/` (44 KB)

| Tệp | Dùng để |
|---|---|
| `file_move_saga-archive.sql` | dựng lại bảng `yp.file_move_saga` + dữ liệu |
| `lineage-before-cleanup.sql` | `yp.file_thread_lineage` trước khi dọn |
| `mfs_move_all.bak` | một bản `mfs_move_all` trước khi sửa |
| `orphan-thread-empty.sql` | thread rỗng đã xoá ở Bước 7 |

Bản gốc còn ở `/tmp/p4-260812-113810/` kèm dump toàn bộ routine 1.4 GB
(`mfs_move_all-all.bak`). `/tmp` mất khi khởi động lại máy — cần dump lớn đó
thì chép đi trước.

---

## Bước 3 — Procedure mới của cơ chế thread

```bash
for p in channel_file_thread_list_in_subtree \
         file_thread_lineage_resolve_holder \
         file_thread_lineage_track_holder \
         file_thread_lineage_orphan_holder; do
  printf "%-42s " "$p"
  mysql -N -e "SELECT COUNT(*) FROM information_schema.ROUTINES
               WHERE ROUTINE_NAME='$p'"
done
```

| Procedure | Expect | Ghi chú |
|---|---|---|
| `channel_file_thread_list_in_subtree` | 1009 | mỗi hub/drumate database một bản |
| `file_thread_lineage_resolve_holder` | 1 | chỉ ở `yp` |
| `file_thread_lineage_track_holder` | 1 | chỉ ở `yp` |
| `file_thread_lineage_orphan_holder` | 1 | chỉ ở `yp` |

Kiểm database nào thiếu:

```bash
for db in $(mysql -N -e "SELECT db_name FROM yp.entity
                         WHERE type IN ('hub','drumate')"); do
  c=$(mysql -N -e "SELECT COUNT(*) FROM information_schema.ROUTINES
                   WHERE ROUTINE_SCHEMA='$db'
                     AND ROUTINE_NAME='channel_file_thread_list_in_subtree'")
  [ "$c" = "0" ] && echo "MISSING $db"
done
```

Thiếu → move file có chat ở workspace đó sẽ không đánh dấu được thread.
Vá bằng cách nạp `common/procedures/channel/channel_file_thread_list_in_subtree.sql`
vào database đó.

---

## Bước 4 — Bảng lineage

```bash
# đếm cột (không lẫn với tên index)
mysql -N -e "SELECT COUNT(*) FROM information_schema.COLUMNS
             WHERE TABLE_SCHEMA='yp' AND TABLE_NAME='file_thread_lineage'
               AND COLUMN_NAME IN ('holder_hub_id','holder_file_nid','file_name')"

# enum state phải có 'orphaned'
mysql -N -e "SELECT COLUMN_TYPE FROM information_schema.COLUMNS
             WHERE TABLE_SCHEMA='yp' AND TABLE_NAME='file_thread_lineage'
               AND COLUMN_NAME='state'"

mysql -e "SELECT state, COUNT(*) FROM yp.file_thread_lineage GROUP BY state"
```

| Kiểm | Expect |
|---|---|
| Số cột `holder_hub_id`/`holder_file_nid`/`file_name` | 3 |
| `state` enum chứa `orphaned` | có |
| Số dòng | 11 |
| Dòng `state='failed'` | 0 |

`state='failed'` xuất hiện → có move hỏng giữa chừng. Không xoá dòng đó: kiểm
xem thread còn tin nhắn không trước đã (xem Bước 7).

---

## Bước 5 — Sức khoẻ theo từng database

```bash
mysql -e "CALL yp.file_move_readiness('<db_name>')"
```

Trả `ready=1, missing=''` là đủ. `missing` liệt kê tên procedure/bảng/cột thiếu.

Quét toàn bộ (chạy vài phút):

```bash
for db in $(mysql -N -e "SELECT db_name FROM yp.entity
                         WHERE type IN ('hub','drumate')"); do
  r=$(mysql -N -e "CALL yp.file_move_readiness('$db')" 2>/dev/null | awk '{print $2}')
  [ "$r" != "1" ] && mysql -N -e "CALL yp.file_move_readiness('$db')"
done
```

Expect: không in ra gì (1009/1009 sẵn sàng).

---

## Bước 6 — Lỗi tệp vật lý **(lỗi đã biết, chưa sửa)**

Đây là lỗi khiến file "hỏng" sau khi move. Nguyên nhân: `MfsTools.move_node`
yêu cầu thư mục đích **tồn tại sẵn**, nhưng đích là node vừa tạo nên chưa có
thư mục. Hàm thoát im lặng — không log, không ném lỗi. Dòng dữ liệu trỏ nid
mới, tệp vẫn nằm ở thư mục nid cũ.

Đo mức độ:

```bash
for h in $(mysql -N -e "SELECT home_dir FROM yp.entity
                        WHERE type IN ('hub','drumate') AND status='active'"); do
  hub=$(basename "$h")
  db=$(mysql -N -e "SELECT db_name FROM yp.entity WHERE id='$hub'")
  disk=$(ls "$h/__storage__/" 2>/dev/null | grep -vc '^.file-move-staging$')
  live=$(mysql -N -e "SELECT COUNT(*) FROM \`$db\`.media
                      WHERE category NOT IN ('folder','hub','root')
                        AND status='active'" 2>/dev/null)
  [ "${disk:-0}" -gt "${live:-0}" ] && echo "$hub disk=$disk live=$live"
done
```

Bình thường `disk` phải bằng `live`. Mỗi đơn vị chênh là **một lần move bỏ lại
một thư mục**.

Đo được ngày 12/08:

| Hub | disk | live | chênh |
|---|---|---|---|
| `99728f1799728f1f` | 13 | 2 | 11 |
| `fb610c4ffb610c57` | 1 | 1 | 0 |

**Không xoá các thư mục thừa.** Mỗi thư mục là bản sao duy nhất của một tệp mà
dòng dữ liệu không còn trỏ tới. Đã dùng chúng để khôi phục 3 tệp trong ngày.

Tìm tệp cho một nid đang hỏng:

```bash
# nid trong URL preview bị lỗi
mysql -N -e "SELECT filesize FROM \`<db>\`.media WHERE id='<nid>'"
# tìm thư mục chứa tệp đúng kích thước đó
for d in <home_dir>/__storage__/*/; do
  ls -la "$d" | awk -v s=<filesize> '$5==s {print FILENAME, $NF}' FILENAME="$d"
done
```

---

## Bước 7 — Thread mồ côi (thread còn, tệp mất)

```bash
for db in $(mysql -N -e "SELECT db_name FROM yp.entity
                         WHERE type IN ('hub','drumate') AND status='active'"); do
  c=$(mysql -N -e "SELECT COUNT(*) FROM \`$db\`.file_thread ft
                   WHERE ft.status='active'
                     AND NOT EXISTS (SELECT 1 FROM \`$db\`.media m
                                     WHERE m.id=ft.file_nid)
                     AND NOT EXISTS (SELECT 1 FROM yp.file_thread_lineage l
                                     WHERE l.current_file_nid=ft.file_nid)" 2>/dev/null)
  [ "${c:-0}" != "0" ] && echo "$db: $c"
done
```

Expect: không in ra gì.

Có kết quả → thread trỏ tệp không tồn tại và **không có dòng lineage giải
thích**. Giao diện sẽ hiện thread hỏng thay vì "file đã bị xoá".

Xử lý: **đếm tin nhắn trước, đừng xoá thẳng.**

```bash
mysql -e "SELECT COUNT(*) FROM \`<db>\`.channel
          WHERE file_thread_id='<root_message_id>'
             OR message_id='<root_message_id>'"
```

- Có tin nhắn → tạo dòng lineage `state='orphaned'` để giao diện hiển thị đúng.
  Xoá thread là huỷ bản sao duy nhất của những tin nhắn đó.
- Không tin nhắn → xoá được.

Ngày 12/08 gặp 5 thread mồ côi: 4 thread mang 9 tin nhắn thật (`"good logo"`,
`"ha"`, `"ádasd"`, `"12"`, …) đã chuyển sang `orphaned`; 1 thread rỗng đã xoá.

---

## Bước 8 — Thư mục staging tồn đọng

```bash
find /data/mfs -maxdepth 4 -name ".file-move-staging" -type d 2>/dev/null |
  while read d; do n=$(ls "$d" | wc -l); [ "$n" != "0" ] && echo "$d -> $n"; done
```

Đo được ngày 12/08:

| Đường dẫn | Số thư mục |
|---|---|
| `/data/mfs/fb61/fb610c4ffb610c57/__storage__/.file-move-staging` | 4 |
| `/data/mfs/97b2/97b24b3d97b24b42/__storage__/.file-move-staging` | 1 |
| `/data/mfs/4222/4222452f42224533/__storage__/.file-move-staging` | 1 |

Đây là tệp kẹt lại từ các lần saga cũ thất bại — chúng chứa `orig.jpg`/`orig.png`
thật. **Không xoá** cho tới khi đối chiếu xong với các nid đang thiếu tệp.

---

## Bước 9 — Log ứng dụng

```bash
sudo tail -200 /srv/drumee/runtime/server/.pm2/logs/aaron-service-error-21.log |
  grep -viE "Module payment already exists|at registerModules|at async|^Trace$|ExperimentalWarning|trace-warnings"
```

Hai dòng lọc bỏ ở trên là cảnh báo có sẵn từ trước, vô hại.

Đáng chú ý nếu thấy:

| Dấu hiệu | Nghĩa |
|---|---|
| `ER_SP_DOES_NOT_EXIST` | thiếu procedure — quay lại Bước 2/3 |
| `TEMP-DIAG` | **log chẩn đoán tạm, phải gỡ** (xem Bước 10) |
| `Failed to relocate node storage` | lỗi dời tệp — Bước 6 |
| `file thread ... failed` | thread không đánh dấu được sau move |

---

## Bước 10 — Trạng thái mã nguồn đang chạy

```bash
grep -c "TEMP-DIAG" /srv/drumee/runtime/server/aaron/service/private/media.js
grep -c "_relocateNodeStorage" /srv/drumee/runtime/server/aaron/service/private/media.js
grep -c "async move_cross_hub" /srv/drumee/runtime/server/aaron/service/private/media.js
```

| Kiểm | Hiện tại | Mong muốn |
|---|---|---|
| `TEMP-DIAG` | **6** | **0** — log chẩn đoán tạm, chưa gỡ |
| `_relocateNodeStorage` | 2 | 2 — bản vá dời tệp (chưa xác nhận hoạt động) |
| `async move_cross_hub` | 1 | 1 — lối chuyển tiếp cho client cũ |

**`TEMP-DIAG` đang bật.** Nó ghi log mỗi lần move. Vô hại nhưng làm bẩn log —
phải gỡ trước khi coi stage là sạch.

---

## Bước 11 — Lệch mã giữa repo và stage

Stage **không phải git checkout**, chỉ là thư mục tệp. Không có cơ chế nào bảo
đảm mã đang chạy khớp repo. Kiểm bằng checksum:

```bash
# trên máy dev
git ls-files 'service/**' 'acl/**' 'router/**' 'client/**' 'offline/**' |
  grep -E '\.(js|json|tpl)$' > /tmp/filelist.txt
while read f; do [ -f "$f" ] && md5 -q "$f" | tr -d '\n' && echo "  $f"; done \
  < /tmp/filelist.txt | sort -k2 > /tmp/local.md5

scp /tmp/filelist.txt drumee:/tmp/
ssh drumee 'cd /srv/drumee/runtime/server/aaron &&
  while read f; do [ -f "$f" ] && md5sum "$f" || echo "MISSING $f"; done \
  < /tmp/filelist.txt' | awk '{print $1"  "$2}' | sort -k2 > /tmp/stage.md5

join -j 2 -o 0,1.1,2.1 /tmp/local.md5 /tmp/stage.md5 | awk '$2!=$3 {print "DIFF  "$1}'
```

Đo ngày 12/08 (nhánh `fix/file-move-precondition-check`): 259/263 khớp.

4 tệp lệch — `hub.js`, `stripe_webhook.js`, `backup.js`, `_revenue_live.js` —
thuộc mảng khác (thanh toán, backup), do người khác triển khai. Không chạm
luồng move.

**Lệch đã biết ở `schemas`:** `mfs_move_all` trong database là bản gốc từ git,
tệp trong repo là bản đã gỡ lời gọi migrate. Cố ý — bản gốc được khôi phục để
không làm hỏng các endpoint khác. Đừng "đồng bộ" mù theo repo.

---

## Tóm tắt: cái gì đang hỏng

| Vấn đề | Trạng thái | Ảnh hưởng |
|---|---|---|
| Tệp vật lý không dời khi move | **Chưa sửa** | File "hỏng" ở workspace đích; tệp còn ở thư mục nid cũ, khôi phục tay được |
| `TEMP-DIAG` còn trong mã chạy | **Chưa gỡ** | Bẩn log |
| 11 thư mục mồ côi (hub `9972`) | Giữ nguyên có chủ đích | Chiếm chỗ; là bản sao duy nhất của tệp mất |
| 6 thư mục staging tồn đọng | Giữ nguyên có chủ đích | Như trên |
| Hạ tầng saga | Đã khôi phục | — |
| Cơ chế thread mới | Đang chạy | Chat ở lại workspace gốc, khôi phục khi file quay về |

---

## Việc cần làm tiếp

1. **Tìm nguyên nhân tệp không dời.** Log chẩn đoán cho thấy `after_transact`
   nhận 2 dòng nhưng mọi trường đều `undefined` — không có `action`, `nid`,
   `des_id`. Procedure `mfs_move_all` khi gọi trực tiếp *có* trả đủ 9 cột. Dữ
   liệu mất hình dạng ở giữa; đã cài log để xác định chỗ nào.
2. **Gỡ `TEMP-DIAG`** sau khi có kết luận.
3. **Đối chiếu thư mục mồ côi với nid thiếu tệp**, khôi phục được cái nào thì
   khôi phục, rồi mới dọn.
4. **Chuyển bản lưu trữ khỏi `/tmp`** trên stage trước lần khởi động lại máy
   tiếp theo.
