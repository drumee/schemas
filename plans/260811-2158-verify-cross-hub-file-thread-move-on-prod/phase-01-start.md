---
title: "Phase 1: Chẩn đoán forward-verify fail"
status: todo
phase: 1
priority: P1
effort: "3h"
dependencies: []
---

# Phase 1: Chẩn đoán forward-verify fail

## Overview

Xác định **vì sao forward move fail verify**, bằng thực nghiệm có kiểm soát. Không sửa gì cho tới khi biết nguyên nhân.

Chẩn đoán ban đầu ("DB đích thiếu `mfs_move_all`") đã bị bác bỏ: forward dùng proc của **nguồn** (`media.js:814-820`), và nguồn có bản mới. Đích có đủ mọi artifact forward cần.

## Requirements

**Functional**
- Biết chính xác `sourcePosition` / `destinationPosition` tại thời điểm verify của một lần chạy thật
- Biết forward fail ở điều kiện nào trong 3 điều kiện của `isCompleteMfsThreadMigration`
- Loại trừ hoặc xác nhận từng giả thuyết dưới đây

**Non-functional**
- Chỉ đọc, hoặc ghi có kiểm soát vào workspace test riêng
- Không backfill gì ở phase này — sửa mù trước khi chẩn đoán là cách đã thất bại một lần

## Architecture

Điều kiện verify (`server-team/service/lib/mfs-move-result.js:24-28`):

```js
!sourcePosition
&& destinationPosition
&& Number(destinationPosition.root_identity_count) === 1
&& Number(destinationPosition.stale_child_identity_count) === 0
```

Đo sau khi compensation đã chạy cho thấy **đích thoả cả 2 điều kiện count** (`root=1, stale=0`). Nên nghi vấn tập trung vào `!sourcePosition` — proc `file_move_thread_position` gọi trên DB nguồn với `(_file_nid=NULL, _thread_id=saga.source_thread_id)` phải trả rỗng.

### Giả thuyết cần kiểm

**H1 — Nguồn chưa sạch tại thời điểm verify.** Step 8 của `channel_migrate_moved_scope` (capture-then-delete, `:664-713`) xoá `file_thread` nguồn qua `INNER JOIN` bảng đích. Nếu join không khớp (id remint ở Step 3?), row nguồn ở lại → `sourcePosition` không rỗng → verify fail. **Kiểm bằng:** đo `file_move_thread_position(NULL, <thread_id>)` trên nguồn ngay sau `mfs_move_all`, trước khi verify chạy.

**H2 — Timing.** `channel_migrate_moved_scope` được `CALL` đồng bộ trong `mfs_move_all` (`mfs_move_all.sql:304-307`), nên về lý thuyết không có async. Red-team lập luận poll 5×50ms là vô nghĩa. Nếu H1 loại trừ mà vẫn fail → xem lại có commit boundary nào giữa hai session không.

**H3 — Failure-isolation nuốt lỗi.** Mỗi step trong migrate proc có `CONTINUE HANDLER` riêng. Kịch bản: Step 4 (insert dest `channel`) fail → 0 channel row đích; Step 5 (insert dest `file_thread`) là block độc lập → thành công; Step 8 thấy row đích tồn tại → xoá row nguồn. Kết quả: đích có `file_thread` mồ côi. **Kiểm bằng:** `channel_migrate_log` ở đích sau lần chạy mới.

**H4 — `stale_child_identity_count` false positive.** `file_move_thread_position.sql:22-26` đếm child có `metadata._file_nid` khác `ft.file_nid` là stale. `channel_migrate_moved_scope.sql:302` cố ý nhận child `metadata IS NULL`, Step 4 (`:401`) biến NULL thành `{}` → `JSON_VALID=1`, `_file_nid` NULL → đếm là stale. Thread có message legacy không mang `_file_nid` sẽ **luôn** fail verify. Dữ liệu hiện có (2 message, cả hai đều có `_file_nid`) không reproduce được. **Kiểm bằng:** ca test riêng ở Phase 2.

## Related Code Files

- Đọc: `server-team/service/private/media.js:780-870` (đường forward + verify)
- Đọc: `server-team/service/lib/mfs-move-result.js`
- Đọc: `common/procedures/channel/channel_migrate_moved_scope.sql` (Step 3, 4, 5, 8)
- Đọc: `common/procedures/mfs/file_move_thread_position.sql`
- Không sửa file nào

## Implementation Steps

1. **Chuẩn bị workspace test riêng** — hai workspace mới hoặc dùng lại B/C nhưng file mới. Upload file, tạo thread 2-3 message. Ghi `file_nid`, `file_thread_id`, danh sách `message_id`.
2. **Snapshot trước move** — trên nguồn và đích: `file_move_thread_position` cả hai chiều, `COUNT` của `media`/`file_thread`/`channel` cho thread đó, `channel_migrate_log` count.
3. **Bật log chi tiết nếu có** — kiểm `drumee log aaron/service` hoặc pm2 log level, để bắt được `warn` từ `_compensateCrossHubMove`.
4. **Chạy move B→C** qua UI.
5. **Ngay sau khi UI trả kết quả**, đo lại toàn bộ bước 2 cộng:
   ```sql
   SELECT operation_id, state, failure_code, destination_file_nid, destination_thread_id
   FROM yp.file_move_saga WHERE operation_id = '<op_id ghi từ log>';
   SELECT stage, detail, FROM_UNIXTIME(ctime)
   FROM <dest_db>.channel_migrate_log ORDER BY ctime DESC LIMIT 20;
   ```
6. **Phân định**:
   - `channel_migrate_log` có row → H3, đọc `stage`/`detail`
   - log rỗng + nguồn còn `file_thread` row → H1
   - log rỗng + nguồn sạch + đích đủ count → verify lẽ ra phải pass; xem lại `findMfsMoveResult` có trả `des_id` không (`destinationFileNid` null cũng đi vào compensate, `media.js:848-853`)
7. **Ghi report** vào `plans/reports/` với toàn bộ số đo, kết luận giả thuyết nào đúng.

## Success Criteria

- [ ] Có bộ số đo trước/sau của một lần chạy thật
- [ ] Kết luận rõ forward fail ở điều kiện nào trong 3 điều kiện, hoặc fail sớm hơn (`destinationFileNid` null)
- [ ] Mỗi giả thuyết H1–H4 được đánh dấu: xác nhận / loại trừ / chưa kiểm được
- [ ] Report đủ để Phase 2 biết phải sửa gì
- [ ] Không thay đổi gì ngoài workspace test

## Risk Assessment

| Rủi ro | Tín hiệu | Phản ứng |
|---|---|---|
| Lần chạy này lại làm mất file test | Media row biến mất cả hai phía | Chấp nhận — dùng file test bỏ được. File vật lý còn trong staging, khôi phục được nếu cần |
| Lineage của file test bị khoá `failed` sau lần chạy | Không move lại được file đó | Đúng thiết kế. Dùng file mới cho lần chạy tiếp. `file_move_saga_transition.sql:115-118` reset lineage cho `failed`/`expired` nhưng **không** cho `compensation_failed` |
| Không bắt được `operation_id` | Log không ghi | Query `yp.file_move_saga ORDER BY ctime DESC LIMIT 1` ngay sau move; lưu ý `ctime` là giây nên tránh chạy 2 move sát nhau |
| UNIQUE key chặn saga | `FILE_MOVE_SAGA_FAILED` | `file_move_saga_replay_uidx (lineage_id, source_hub_id, source_file_nid, destination_hub_id, destination_parent_nid)`. Đổi folder đích hoặc dùng file khác |

**Giả định có thể sai:** "đích thoả điều kiện count tại thời điểm verify". Số đo hiện có là **sau** compensation, không phải tại thời điểm verify. Bước 5 đo đúng thời điểm mới kết luận được.
