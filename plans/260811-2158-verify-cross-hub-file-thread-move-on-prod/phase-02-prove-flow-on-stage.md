---
title: "Phase 2: Sửa + chứng minh flow trên stage"
status: todo
phase: 2
priority: P1
effort: "4h"
dependencies: [1]
---

# Phase 2: Sửa + chứng minh flow trên stage

## Overview

Sửa nguyên nhân Phase 1 tìm ra, backfill `mfs_move_all` cho 5 DB sống (sửa đường compensation), rồi chứng minh flow đúng bằng dữ liệu — bao gồm cả ca dữ liệu khó mà test file-mới không cover.

Đây là gate chặn Phase 4.

## Requirements

**Functional**
- Nguyên nhân forward-verify từ Phase 1 được sửa, verified
- 5 DB sống có `mfs_move_all` bản mới (sửa compensation)
- Move B→C và C→B đều `committed`
- Message nguyên vẹn: đủ số, đúng thứ tự, đúng `author_id`, đúng `ctime`
- Nguồn sạch, staging sạch, không mồ côi

**Non-functional**
- Backup có `--routines` trước khi patch
- Snapshot `SHOW CREATE PROCEDURE` từng DB làm đường lùi
- Không dùng `bin/patch-from-file` mặc định (xem quy trình patch bắt buộc ở `plan.md`)

## Architecture

Hai việc sửa độc lập:

**Sửa A — compensation:** backfill `mfs_move_all` cho 5 DB. Ảnh hưởng: khi forward fail, compensation mới mang được thread về nguồn thay vì để mồ côi.

**Sửa B — forward:** nội dung phụ thuộc Phase 1. Có thể là fix SQL (`channel_migrate_moved_scope` Step 8), fix JS (`mfs-move-result.js`), hoặc backfill artifact khác.

### Ca test bắt buộc

Red-team chỉ ra: test bằng file mới + message mới là tập dữ liệu **duy nhất không reproduce** được H4 (`stale_child_identity_count` false positive với child thiếu `metadata._file_nid`). Nên cần **hai ca**:

- **Ca 1 — file mới**: đường hạnh phúc, chứng minh flow cơ bản
- **Ca 2 — child thiếu `_file_nid`**: chứng minh dữ liệu thật move được

Ca 2 dựng bằng cách: tạo thread rồi `UPDATE channel SET metadata = JSON_REMOVE(metadata, '$._file_nid') WHERE message_id = '<child>'` trên workspace test — mô phỏng message legacy. Nếu Phase 1 xác nhận H4 thì đây là ca chặn; nếu loại trừ H4 thì đây là ca hồi quy.

## Related Code Files

- Sửa (tuỳ Phase 1): `common/procedures/channel/channel_migrate_moved_scope.sql` hoặc `common/procedures/mfs/file_move_thread_position.sql` hoặc `server-team/service/lib/mfs-move-result.js`
- Đọc: `common/procedures/mfs/mfs_move_all.sql`
- Tạo: report tại `plans/reports/`

## Implementation Steps

1. **Backup** — `mysqldump --routines` cho 5 DB sống + `yp.file_move_saga` + `yp.file_thread_lineage`. Verify dump chứa `CREATE PROCEDURE`.
2. **Snapshot proc cũ** — `SHOW CREATE PROCEDURE mfs_move_all` từng DB trong 5 DB, lưu ra file. Đây là đường lùi thật, không phải full-DB restore.
3. **Áp dụng Sửa B** (theo kết luận Phase 1). Nếu là fix SQL trong repo → sửa file nguồn rồi apply; đừng sửa trực tiếp trong DB.
4. **Backfill `mfs_move_all`** cho 5 DB. Chạy từng DB, verify sau mỗi cái.
5. **Verify backfill**:
   ```sql
   SELECT e.db_name, p.body LIKE '%channel_migrate_moved_scope%' AS ok
   FROM yp.entity e LEFT JOIN mysql.proc p ON p.db = e.db_name AND p.name = 'mfs_move_all'
   WHERE e.status = 'active' AND e.db_name IN (...5 DB...);
   ```
   Dùng `LEFT JOIN` từ `entity` — `INNER JOIN mysql.proc` bỏ sót DB thiếu hẳn proc.
6. **Smoke check** — move một file trong cùng workspace. Bắt lỗi patch làm hỏng đường move thường.
7. **Ca 1 — move B→C với file mới**: chuẩn bị như Phase 1 bước 1, chạy, verify theo Success Criteria.
8. **Ca 1 — move C→B (move-back)**: lặp, thêm kiểm `file_thread_lineage.state='active'` và `current_hub_id = B`.
9. **Ca 2 — child thiếu `_file_nid`**: dựng dữ liệu như mô tả ở Architecture, chạy B→C, verify.
10. **Verify staging cả hai hub** — staging nằm dưới `destinationStorage.home_dir` (`media.js:762-765`), nên mỗi chiều tạo ở hub khác nhau. Kiểm cả hai.
11. **Report** với số liệu trước/sau từng ca.

## Success Criteria

- [ ] Backup có `--routines`, snapshot proc cũ tồn tại
- [ ] Query bước 5 trả `ok=1` cho cả 5 DB
- [ ] Smoke check move cùng-workspace pass
- [ ] `SELECT COUNT(*) FROM yp.file_move_saga WHERE state='committed'` ≥ 2
- [ ] Ca 1: message đích khớp gốc về số lượng, `author_id`, `ctime`, thứ tự `sys_id`
- [ ] Ca 1: nguồn có `media`/`file_thread`/`channel` rows = 0 cho thread đó
- [ ] Ca 1 move-back: `file_thread_lineage.state='active'`, `current_hub_id` = B
- [ ] **Ca 2 pass** — hoặc fail có kết luận rõ ràng và được ghi vào plan như hạn chế đã biết
- [ ] Staging sạch ở **cả hai** hub
- [ ] Không `file_thread` mồ côi ở đích: mọi row có media row tương ứng

## Risk Assessment

| Rủi ro | Tín hiệu | Phản ứng |
|---|---|---|
| Sửa B không đúng, vẫn fail | Saga vẫn không `committed` | **Dừng, không sang Phase 4.** Quay lại Phase 1 với dữ liệu mới |
| Backfill làm hỏng `mfs_move_all` | Smoke check bước 6 fail | Re-apply body cũ từ snapshot bước 2. Chạy từng DB chính là để giới hạn thiệt hại |
| Ca 2 fail | Verify fail với thread có child thiếu `_file_nid` | Đây là bug thật, không phải lỗi test. Hoặc sửa (nới điều kiện `stale_child_identity_count`), hoặc ghi nhận rõ: "thread có message legacy không move được" — và user quyết định |
| Saga `committed` nhưng message thiếu | Số message đích < gốc | Đọc `channel_migrate_log` stage `leftover` — proc ghi `unverified_channel_rows` / `missed_capture_window_rows`. **Dừng**, đây là mất dữ liệu |
| UNIQUE key chặn test lặp | `FILE_MOVE_SAGA_FAILED` | `file_move_saga_replay_uidx`. Đổi folder đích hoặc file khác giữa các lần |
| Test làm khoá lineage vĩnh viễn | Lineage `compensation_failed` | Không có proc gỡ. Dùng file dùng-một-lần, chấp nhận saga row là rác |

**Giả định có thể sai:** "backfill proc ⇒ compensation chạy được". Compensation còn phụ thuộc `channel_file_thread_rebind_returned_file` với 5 điều kiện fail (`RETURNED_NODE_UNAVAILABLE`, `DESTINATION_THREAD_CONFLICT`, `THREAD_LINEAGE_MISMATCH`, `OLD_NODE_STILL_AVAILABLE`, `REBIND_FAILED`). Nếu Phase 2 sửa được forward thì compensation ít khi chạy — nhưng đừng tuyên bố nó đã đúng nếu chưa test riêng.
