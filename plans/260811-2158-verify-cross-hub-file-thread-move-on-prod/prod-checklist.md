# Checklist triển khai prod — cross-hub file-thread move

Dùng khi có người truy cập được prod. Đọc hết trước khi chạy bước đầu tiên.

**Trạng thái hiện tại: flow này CHƯA từng chạy thành công ở đâu.** Trên stage không có saga nào `committed`. Checklist này giả định điều đó vẫn đúng cho tới khi Phase 1/2 của plan chứng minh ngược lại.

## Kết quả chạy audit trên stage (2026-08-11)

Đã chạy `file-move-audit.sql` trên stage `drumee.in`. Số liệu thật:

| Chỉ số | Kết quả |
|---|---|
| DB sống (`entity.status='active'`) | 837 |
| DB thiếu ≥1 proc | **144** |
| — thiếu `file_move_thread_position` / `rebind` / `snapshot` / `ft_resolve_access` | **139** |
| — thiếu `mfs_move_all` bản mới | 5 |
| DB thiếu bảng/cột (Q2) | **0** ✓ |
| YP-level artifacts (Q0) | đủ 6 proc + 2 bảng ✓ |

**Phân bố theo ngày tạo của 139 DB thiếu:**

| Ngày | Số DB mới thiếu proc |
|---|---|
| 2026-08-11 (hôm nay) | 1 |
| 2026-08-10 | 1 |
| 2026-08-08 | 1 |
| 2026-08-07 | 1 |
| 2026-08-06 | 5 |
| 2026-08-05 | 5 |
| 2026-08-04 | 21 |
| 2026-08-03 | 26 |
| 2026-08-02 | 27 |
| 2026-08-01 | 51 |

### Lỗi đang TIẾP DIỄN, không phải sự cố quá khứ

Workspace tạo **hôm nay** vẫn thiếu proc. Nghĩa là factory template hiện tại của stage đang phát tán defect — mỗi workspace mới sinh ra đều hụt.

Cơ chế (`offline/factory/index.js`):
- `checkSanity():100-107` xoá template mỗi lần factory khởi động → template chỉ rebuild khi **factory restart**, không theo lịch
- `make_template():157-179` dump từ một DB **bất kỳ** (`LIMIT 1`). Nếu DB đó đã hụt patch → mọi DB pool sau thừa kế
- DB pre-create vào pool rồi mới claim → `entity.ctime` ≠ lúc build schema

**Hệ quả cho prod: backfill là vá tạm.** Không rebuild template thì DB mới vẫn tiếp tục hụt. Xem Phần B bước 7.

Con số trên prod có thể khác — phải chạy audit riêng, không suy từ stage.

---

## Phần A — Kiểm tra (read-only, an toàn chạy bất cứ lúc nào)

```bash
mariadb < patches/file-move-audit.sql > /tmp/audit-prod-$(date +%Y%m%d).txt
```

Đọc kết quả theo thứ tự. Mỗi query có dòng `EXPECT` ngay trên nó trong file SQL.

| Query | EXPECT | Lệch nghĩa là |
|---|---|---|
| Q0 | 6 proc + 2 bảng ở `yp` đều = 1 | Hạ tầng saga chưa deploy → tính năng chưa dùng được, rủi ro = 0 |
| Q1 | 0 dòng | DB sống thiếu proc → move vào/ra DB đó sẽ hỏng |
| Q2 | 0 dòng | DB sống thiếu bảng/cột → **degrade im lặng**, nguy hiểm hơn thiếu proc |
| Q3 | chỉ `committed`/`compensated` | Có file đang ở trạng thái không xác định |
| Q4 | chỉ `active` | Có file bị khoá khỏi cross-hub move |
| Q5 | in ra lệnh — chạy thủ công | Tìm `file_thread` mồ côi |
| Q6 | tổng kết | `saga_thanh_cong = 0` + `saga_tong > 0` = flow chưa từng chạy đúng trên instance này |

**Q2 quan trọng hơn Q1.** `channel_migrate_moved_scope.sql:112-118` đặt `_thread_infra_ok=0` khi thiếu bảng/cột và **bỏ qua Step 2c/5/6 mà không báo lỗi** — move "thành công" nhưng thread không sang. Kiểm proc mà không kiểm bảng/cột sẽ bỏ sót ca này.

### Kiểm tính năng đã bật chưa — cả ba lớp

```bash
grep -c "move_cross_hub" <prod>/service/private/media.js     # lớp 1: code
grep -c "move_cross_hub" <prod>/acl/media.json                # lớp 2: ACL
grep -rc "selectCrossWorkspaceMoveService" <ui-build>         # lớp 3: front-end
```

Cả ba > 0 mới là "đã bật". Chỉ lớp 1 → service tồn tại nhưng chưa reachable → rủi ro thấp.

**Nếu Q0 thiếu, hoặc lớp 2/3 = 0: dừng ở đây.** Tính năng chưa dùng được, không có gì cần sửa gấp. Ghi nhận và chờ Phase 1/2 xác định nguyên nhân forward-fail trước khi deploy.

---

## Phần B — Backfill (có ghi)

### Điều kiện tiên quyết

- [ ] Phase 1 của plan đã kết luận nguyên nhân forward-verify fail
- [ ] Phase 2 đã có ≥1 saga `committed` trên stage, cả ca 1 và ca 2
- [ ] Đã đọc kết quả Phần A, biết chính xác prod thiếu gì
- [ ] Saga tồn đọng (Q3) đã được xử lý hoặc user quyết định bỏ qua
- [ ] Làm ngoài giờ cao điểm

Thiếu bất kỳ mục nào → **không chạy Phần B**. Backfill khi chưa biết nguyên nhân forward-fail chỉ sửa được đường compensation, không sửa được lỗi chính.

### Quy trình

```bash
# 1. Backup — BẮT BUỘC có --routines
#    mysqldump mặc định KHÔNG dump stored procedure.
mysqldump --routines --single-transaction <db> > backup-<db>-$(date +%Y%m%d).sql
mysqldump --routines yp file_move_saga file_thread_lineage > backup-yp-saga.sql

# Verify backup thật sự có proc
grep -c "CREATE PROCEDURE" backup-<db>-*.sql   # phải > 0

# 2. Xem trước, không ghi
patches/file-move-backfill.sh --dry-run

# 3. Chạy một DB trước, quan sát
patches/file-move-backfill.sh --db <db_name>

# 4. Smoke test: move file trong CÙNG workspace
#    Bắt lỗi patch làm hỏng đường move thường.

# 5. Nếu ổn, chạy phần còn lại
patches/file-move-backfill.sh --all

# 6. Kiểm lại
mariadb < patches/file-move-audit.sql

# 7. BẮT BUỘC — rebuild factory template, nếu không DB mới vẫn tiếp tục hụt
#    Xem "Lỗi đang TIẾP DIỄN" ở đầu file. Backfill mà bỏ bước này = vá tạm.
drumee stop factory
#    Template tự rebuild khi factory khởi động lại (checkSanity() xoá template cũ).
#    Nhưng make_template() dump từ một DB BẤT KỲ (LIMIT 1) — nên phải backfill
#    XONG toàn bộ trước khi restart, để DB được chọn chắc chắn đã đủ proc.
drumee start factory

# 8. Verify template mới đã đúng: tạo 1 workspace test, chạy lại audit,
#    workspace đó phải KHÔNG xuất hiện trong Q1.
```

### Rollback

Script tự lưu snapshot proc cũ vào `patches/backup-<timestamp>/<db>.sql`.

```bash
mariadb <db> < patches/backup-<timestamp>/<db>.sql
```

**Không dùng full-DB restore để rollback một proc** — sẽ mất mọi dữ liệu người dùng phát sinh sau lúc dump.

---

## Phần C — Điều TUYỆT ĐỐI KHÔNG làm

### 1. Không dùng `bin/patch-from-file` cho việc này

```bash
# bin/patch-from-file dòng 18:
$script_dir/patch.js ... --orphan=remove --force
```

`bin/patch.js:69-76`: khi client trả lỗi 1049 (unknown database) → gọi `entity_delete` → `DROP DATABASE` + xoá 10 bảng identity (`entity`, `disk_usage`, `vhost`, `corporate`, `share_box`, `dmz_token`, `privilege`, `map_role`, `hub`/`drumate`, `cookie`). `--force` đã bỏ prompt xác nhận.

Kích hoạt được khi entity còn trong `yp.entity` nhưng schema tạm không truy cập (đang restore, quyền, tên lệch case).

Script `file-move-backfill.sh` chỉ ghi proc/bảng, không có đường nào tới `entity_delete`.

### 2. Không test cross-workspace move trên file khách hàng

`file_move_saga_transition.sql:58-67` không có transition **ra khỏi** `compensation_failed`. Cộng với `media.js:709` chặn saga mới khi lineage không `active`, và transition chỉ reset lineage cho `failed`/`expired` — **không** cho `compensation_failed`.

Một lần hỏng → file đó bị khoá vĩnh viễn khỏi cross-hub move, không có proc gỡ. Chỉ test bằng file dùng-một-lần trong workspace nội bộ.

### 3. Không backfill khi có saga đang chạy

Kiểm trước:
```sql
SELECT operation_id, state, FROM_UNIXTIME(ctime), FROM_UNIXTIME(expires_at)
FROM yp.file_move_saga
WHERE state IN ('copy_pending','copy_verified','source_removed','compensating');
```
Có dòng → chờ hết `expires_at` hoặc làm ngoài giờ.

---

## Phần D — Verify sau khi deploy

Chạy trên workspace nội bộ, file dùng-một-lần.

### Ca 1 — đường hạnh phúc

1. Upload file mới vào WS A, tạo thread 3 message từ 2 tài khoản khác nhau
2. Ghi lại: `file_nid`, `file_thread_id`, danh sách `message_id` + `author_id` + `ctime`
3. Move A→B qua dialog Move, **chọn đúng 1 đích** (nhiều đích đi đường copy khác)
4. Kiểm:

```sql
-- Saga phải committed VÀ destination_thread_id KHÔNG null
SELECT state, failure_code, destination_file_nid, destination_thread_id
FROM yp.file_move_saga ORDER BY ctime DESC LIMIT 1;

-- channel_migrate_log ở đích: rỗng = migrate sạch; có row = đọc stage/detail
SELECT stage, detail FROM `<dest_db>`.channel_migrate_log ORDER BY ctime DESC LIMIT 10;

-- Message ở đích phải khớp bước 2 về số lượng, author_id, ctime, thứ tự sys_id
SELECT message_id, author_id, ctime FROM `<dest_db>`.channel
WHERE message_id = '<thread_id>' OR file_thread_id = '<thread_id>' ORDER BY sys_id;

-- Nguồn phải sạch: cả 3 đều = 0
SELECT
  (SELECT COUNT(*) FROM `<src_db>`.media WHERE id = '<file_nid>')                AS media,
  (SELECT COUNT(*) FROM `<src_db>`.file_thread WHERE file_nid = '<file_nid>')    AS thread,
  (SELECT COUNT(*) FROM `<src_db>`.channel
    WHERE message_id = '<thread_id>' OR file_thread_id = '<thread_id>')          AS msgs;
```

5. UI: A — file biến mất; nếu đang mở thread thì có popup rồi về `# General`. B — file xuất hiện, thread mở được, message đủ, member B **không** bị đánh dấu unread cho message cũ
6. Staging sạch: `<dest_home_dir>/__storage__/.file-move-staging/` không có thư mục mới

### Ca 2 — dữ liệu thật (BẮT BUỘC)

Ca 1 dùng message mới, luôn có `metadata._file_nid`. Message cũ trong hệ thống có thể không có. `file_move_thread_position.sql:22-26` đếm child thiếu `_file_nid` là `stale` → verify fail.

Dựng ca này trên workspace test:
```sql
UPDATE `<src_db>`.channel SET metadata = JSON_REMOVE(metadata, '$._file_nid')
WHERE message_id = '<một child message>';
```
Rồi chạy lại toàn bộ ca 1.

**Ca 2 fail = dữ liệu thật của khách không move được.** Hoặc sửa (nới điều kiện `stale_child_identity_count`), hoặc ghi nhận rõ hạn chế và để user quyết.

### Ca 3 — move-back

Lặp ca 1 theo chiều B→A. Thêm kiểm:
```sql
SELECT state, current_hub_id FROM yp.file_thread_lineage
WHERE original_file_nid = '<file_nid_ban_dau>';
-- state phải 'active', current_hub_id phải = A
```

Nếu trả lỗi `FILE_MOVE_OLD_NODE_AVAILABLE`: đúng thiết kế (`file_move_return_precheck`) — node gốc ở A vẫn còn. Không phải bug.

---

## Phần E — Vấn đề đã biết, chưa sửa

| Vấn đề | Vị trí | Ảnh hưởng |
|---|---|---|
| Không precondition-check DB đích trước khi khởi saga | `media.js:672-748` `_beginCrossHubMove` | Lỗi biểu hiện thành "move mất file" thay vì từ chối ngay. **Đang sửa trong plan này** |
| `compensation_failed` không có đường ra | `file_move_saga_transition.sql:58-67` | File bị khoá vĩnh viễn, cần can thiệp DB thủ công |
| Không có worker dọn saga tồn đọng / staging | không tồn tại | Rác tích tụ, phải dọn tay |
| `move` folder cả cụm (`workspace_move`) không phát event | `media.js:1336-1341` (có comment giải thích) | UI hai phía không biết thread đã đi; message vẫn migrate đúng ở tầng SQL |
| Kéo-thả sang workspace khác là **copy**, không phải move | `media/core.js:1875-1895` | Khác hành vi với dialog Move; thread không đi theo |
| Factory template phát tán defect — DB mới vẫn thiếu proc | `offline/factory/index.js:100-107, 157-179` | Backfill không rebuild template = vá tạm. Xem Phần B bước 7 |

---

## Phần F — Manh mối cho Phase 1 (chẩn đoán forward-verify fail)

Đo trên stage, có thể tiết kiệm thời gian cho người chẩn đoán:

**Cả 3 saga đều có `destination_thread_id = NULL`.**

`file_move_saga_transition.sql:72` ghi giá trị này qua `COALESCE(_destination_thread_id, destination_thread_id)`. `media.js:855-858` chỉ truyền nó ở transition `copy_verified → source_removed`, tức là **sau khi verify pass**. NULL nghĩa là verify chưa bao giờ pass.

Mà `media.js:848-853`:
```js
if (!destinationFileNid
    || !isCompleteMfsThreadMigration({ sourcePosition, destinationPosition })) {
  saga.destination_thread_id = destinationPosition && destinationPosition.file_thread_id;
  return this._compensateCrossHubMove(...);
}
```
Cả hai giá trị được ghi cùng lúc ở `media.js:847-848` rồi persist qua `_compensateCrossHubMove`. Trong DB:

| Cột | Giá trị |
|---|---|
| `destination_file_nid` | `d9708dcdd9708dd2` — **có** |
| `destination_thread_id` | **NULL** |

Nên loại trừ được `destinationFileNid` null: `findMfsMoveResult` đã hoạt động đúng, `mfs_move_all` đã trả row `action='move'` với `des_id`.

Còn lại: `destinationPosition` **null tại thời điểm verify** — `file_move_thread_position(d9708dcdd9708dd2, NULL)` trên DB đích trả rỗng lúc đó.

Nhưng chạy cùng lệnh bây giờ lại trả row đầy đủ (`root_identity_count=1, stale_child_identity_count=0`). Row `file_thread` ở đích tồn tại và đúng.

**Lưu ý khi đọc `ctime`:** `channel_migrate_moved_scope` Step 5 copy `ft.ctime` từ nguồn, nên `ctime` ở đích là thời điểm thread được tạo ở workspace gốc, **không phải** thời điểm migrate. Đừng dùng nó để suy ra thứ tự sự kiện.

Hướng đáng đào nhất: **visibility giữa hai connection**. `@@GLOBAL.tx_isolation = READ-COMMITTED`, `@@GLOBAL.autocommit = 1`. Nếu `mfs_move_all` (và `CALL dest.channel_migrate_moved_scope` bên trong nó) chạy trong một transaction chưa commit khi verify query chạy trên connection khác, verify sẽ không thấy row vừa insert. Kiểm:

- `mfs_move_all` có `START TRANSACTION` / được gọi qua `transact()` không? (`move_cross_hub` gọi `await_proc` trực tiếp, khác đường `media.move` dùng `this.transact()`)
- Lớp DB có dùng connection pool không — `await_proc` lần sau có chắc cùng connection với lần trước không

Nếu đúng hướng này thì poll 5×50ms vô dụng vì vấn đề không phải thời gian mà là transaction boundary — và fix là commit trước khi verify, hoặc verify trên cùng connection.
