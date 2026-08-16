---
title: "Phase 3: Khảo sát prod (read-only)"
status: todo
phase: 3
priority: P1
effort: "2h"
dependencies: []
---

# Phase 3: Khảo sát prod (read-only)

# BLOCKED — cần user cung cấp prod host

`~/.ssh/config` chỉ có `drumee` (drumee.in, chính là stage) và `csmlog`. Thiếu thông tin này thì phase không chạy được.

**Chạy song song Phase 1/2 ngay khi có host** — phase này read-only, đo mức phơi nhiễm khách hàng. Kết quả có thể đảo ưu tiên toàn plan: nếu prod có saga tồn đọng với file thật thì đó là P0, không phải chứng minh flow.

## Overview

Đo trạng thái prod theo **toàn bộ batch artifact** của lần deploy 26/07, không chỉ một proc. Chỉ đọc, không ghi.

## Requirements

**Functional**
- Biết prod thiếu artifact nào, ở bao nhiêu DB sống
- Biết prod có saga tồn đọng không, ở state nào, ảnh hưởng file thật nào
- Biết tính năng đã reachable trên prod chưa (không chỉ grep code)
- Biết prod có `file_thread` mồ côi, staging tồn đọng không

**Non-functional**
- Tuyệt đối read-only: chỉ `SELECT`, `SHOW`, `ls`, `stat`
- Ghi lại toàn bộ output để Phase 4 so sánh

## Architecture

### Vì sao đo một proc là không đủ

Cơ chế hụt (DB tạo từ template dump trước lúc patch) làm hụt **cả batch**, không riêng `mfs_move_all`. Batch 26/07 gồm (từ `patches/manifest.txt`):

- Bảng: `hub/tables/file_thread.sql`, `common/tables/channel_migrate_log.sql`
- Cột: `channel.file_thread_id`
- Proc: `channel_migrate_moved_scope`, `mfs_move_all`, `file_move_thread_position`, `channel_file_thread_rebind_returned_file`, `file_move_source_snapshot`, `file_move_destination_snapshot`, `file_move_return_precheck`, 7 proc `channel_file_thread_*`

`channel_migrate_moved_scope.sql:112-118` degrade **im lặng** khi thiếu bảng/cột:
```sql
SET _thread_infra_ok = IF(_src_has_ft_tbl = 1 AND _dest_has_ft_tbl = 1 AND _dest_has_ft_col = 1, 1, 0);
```
`_thread_infra_ok=0` → Step 2c/5/6 bị bỏ → đích không có `file_thread` row → verify fail. Query chỉ đo `mfs_move_all` trả 0 trong trường hợp này.

**Lưu ý drumate:** patch DDL `drumate/patches/2026-07-10-file-thread-drumate.sql` (thêm `channel.file_thread_id`, bảng `file_thread`) **không có trong `patches/manifest.txt`** — không đảm bảo drumate DB nào đã nhận.

### Cơ chế hụt rộng hơn dự đoán ban đầu

Đọc `offline/factory/index.js`:
- `checkSanity():100-107` xoá template mỗi lần factory khởi động → template chỉ rebuild khi **factory restart**, không theo lịch. Cửa sổ hụt = từ lúc patch tới lần restart kế tiếp — trên prod **không biết**, có thể là tuần
- `make_template():157-179` dump từ một DB **bất kỳ** (`LIMIT 1`). Nếu DB đó đã hụt patch, mọi DB pool sau đó thừa kế defect
- DB được pre-create vào pool rồi mới claim → `entity.ctime` (lúc claim) ≠ lúc build schema

Bằng chứng khớp: stage có 1 DB tạo sau 26/07 18:50 vẫn mang bản cũ (pool carryover), và `1_cb18b513cb18b514` có `entity ctime 07/08` nhưng `proc modified 26/07`.

**Kết luận: không suy đoán prod theo cửa sổ thời gian. Đo trực tiếp.**

## Related Code Files

- Không sửa gì. Tham chiếu: `patches/manifest.txt`, `offline/factory/index.js`, `common/procedures/channel/channel_migrate_moved_scope.sql:112-118`

## Implementation Steps

1. **Xác định prod host** (chờ user) — ghi cách truy cập, quyền DB.
2. **Kiểm tính năng đã reachable chưa** — cả ba lớp:
   - `grep -c "move_cross_hub" <prod>/service/private/media.js`
   - entry trong `acl/media.json`
   - front-end đã deploy `selectCrossWorkspaceMoveService` chưa
   Cả ba đều phải có mới là "đã bật".
3. **Đo proc thiếu, LEFT JOIN từ entity**:
   ```sql
   SELECT e.db_name, e.type, e.area,
          MAX(CASE WHEN p.name='mfs_move_all' AND p.body LIKE '%channel_migrate_moved_scope%' THEN 1 ELSE 0 END) AS move_all_ok,
          MAX(CASE WHEN p.name='channel_migrate_moved_scope' THEN 1 ELSE 0 END) AS migrate_ok,
          MAX(CASE WHEN p.name='file_move_thread_position' THEN 1 ELSE 0 END) AS position_ok,
          MAX(CASE WHEN p.name='channel_file_thread_rebind_returned_file' THEN 1 ELSE 0 END) AS rebind_ok
   FROM yp.entity e LEFT JOIN mysql.proc p ON p.db = e.db_name
   WHERE e.status = 'active'
   GROUP BY e.db_name HAVING move_all_ok=0 OR migrate_ok=0 OR position_ok=0 OR rebind_ok=0;
   ```
   `LEFT JOIN` từ `entity` + `status='active'` — quan trọng: `INNER JOIN mysql.proc` bỏ sót DB thiếu hẳn proc.
4. **Đo bảng/cột thiếu**:
   ```sql
   SELECT e.db_name,
     (SELECT COUNT(*) FROM information_schema.TABLES t
       WHERE t.TABLE_SCHEMA=e.db_name AND t.TABLE_NAME='file_thread') AS ft_tbl,
     (SELECT COUNT(*) FROM information_schema.COLUMNS c
       WHERE c.TABLE_SCHEMA=e.db_name AND c.TABLE_NAME='channel' AND c.COLUMN_NAME='file_thread_id') AS ft_col,
     (SELECT COUNT(*) FROM information_schema.TABLES t
       WHERE t.TABLE_SCHEMA=e.db_name AND t.TABLE_NAME='channel_migrate_log') AS log_tbl
   FROM yp.entity e WHERE e.status='active' HAVING ft_tbl=0 OR ft_col=0 OR log_tbl=0;
   ```
   Query này nặng (scan `information_schema` per DB) — chạy giờ thấp tải.
5. **Kiểm saga tồn đọng**:
   ```sql
   SELECT state, COUNT(*) FROM yp.file_move_saga GROUP BY state;
   SELECT operation_id, state, failure_code, source_hub_id, destination_hub_id,
          source_file_nid, destination_file_nid, FROM_UNIXTIME(ctime)
   FROM yp.file_move_saga WHERE state NOT IN ('committed','compensated') ORDER BY ctime DESC;
   ```
6. **Kiểm hệ quả từng saga tồn đọng** — media row còn ở đâu (nguồn/đích/không đâu), `file_thread` mồ côi không, staging còn file không. Staging nằm dưới `destinationStorage.home_dir`.
7. **Kiểm lineage** — `SELECT state, COUNT(*) FROM yp.file_thread_lineage GROUP BY state`. Đếm số `compensation_failed` (không có đường gỡ).
8. **Kiểm `channel_migrate_log`** ở các DB có saga tồn đọng — đây là nơi proc ghi lỗi nội bộ.
9. **Report** vào `plans/reports/` với toàn bộ số liệu + khuyến nghị Phase 4.

## Success Criteria

- [ ] Bảng DB sống thiếu artifact, phân theo từng artifact (không gộp thành một con số)
- [ ] Bảng phân bố `file_move_saga.state` (hoặc xác nhận bảng rỗng/không tồn tại)
- [ ] Mỗi saga không terminal-success được phân loại: file ở đâu, thread ở đâu, mồ côi không
- [ ] Kết luận rõ tính năng đã reachable trên prod chưa, dựa trên cả ba lớp
- [ ] Số lượng lineage `compensation_failed` (bị khoá vĩnh viễn)
- [ ] Report có khuyến nghị rõ cho Phase 4
- [ ] Rà lại lịch sử lệnh: không có thao tác ghi nào

## Risk Assessment

| Rủi ro | Tín hiệu | Phản ứng |
|---|---|---|
| Vô tình ghi lên prod | — | Chỉ `SELECT`/`SHOW`. Đọc lại từng lệnh. Dùng tài khoản read-only nếu có |
| Không có quyền DB prod | Lệnh bị từ chối | Dừng, báo user. Không vòng qua quyền |
| Prod có saga tồn đọng với file khách | `state NOT IN (committed, compensated)`, media row không tìm thấy | **Nâng P0.** Mất dữ liệu thật. Báo user ngay, không tự quyết. Có thể cần tách plan khôi phục riêng |
| Query `information_schema` làm chậm prod | Prod phản hồi chậm | Chạy giờ thấp tải. Thăm dò bằng `LIMIT` trước khi chạy full |
| Prod dính nhiều hơn stage | Số DB thiếu lớn | Hiểu lại cơ chế trước khi backfill — có thể template pool đang phát tán defect, backfill mà không sửa template là vá tạm |
