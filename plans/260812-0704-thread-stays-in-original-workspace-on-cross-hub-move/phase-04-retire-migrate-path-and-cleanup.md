---
title: "Phase 4: Gỡ đường migrate + dọn dẹp"
status: completed
phase: 4
priority: P1
effort: "4h"
dependencies: [3]
---

# Phase 4: Gỡ đường migrate + dọn dẹp

## Đã làm — và một chỗ plan bảo xoá mà tôi KHÔNG xoá

Plan viết: "`file_thread` mồ côi → xoá — file tương ứng không tồn tại, thread không mở được". Bước 2 bắt kiểm trước khi xoá. Kiểm ra:

| lineage | file còn | thread còn | message |
|---|---|---|---|
| 4 dòng | 0 | 0 | 0 |
| `tvzqukJbnVWJ6UhK` | 0 | **1** | **2** |
| `cGiD4FDjCMbqyBjC` | 0 | **1** | **3** |

Hai dòng cuối mang **tin nhắn thật của người dùng** — "good logo", "czxzcxzxc", "12" (03/08). File của chúng không tồn tại ở **bất kỳ** DB nào trên server (quét 400 DB). Xoá theo plan là huỷ bản sao duy nhất còn lại.

→ Chuyển sang `orphaned` (đúng trạng thái vừa xây ở Phase 1), giữ nguyên tin nhắn. 4 dòng rỗng thì xoá.

### Kết quả

| Việc | Số lượng |
|---|---|
| `mfs_move_all` gỡ lời gọi migrate | 1097 DB + 2 schema ngoài danh bạ |
| Proc thread backfill | 801 DB active + 208 DB pool |
| Proc saga xoá | 3075 (per-hub) + 3 (`yp`) + 3 (`tmp_yp`) |
| Bảng `file_move_saga` | xoá ở `yp` và `tmp_yp`, đã dump lưu trữ |
| Code server gỡ | 558 dòng + 2 file + 1 entry ACL |
| Code UI gỡ | 1 file route + 2 hàm |
| Lineage `failed` | 6 → 0 (2 `orphaned`, 4 xoá) |

**208 DB pool** là phát hiện ngoài plan: chúng chờ trở thành workspace mới và **thiếu hết** proc mới — mỗi cái sẽ thành một workspace hỏng. Đã vá.

`file_move_source_snapshot` **giữ lại**: plan xếp nó vào nhóm saga, nhưng `grep` cho thấy luồng trash/restore đang chạy dùng nó (`media.js:1091`). Xoá là hỏng trash.

## Overview

Gỡ đường migrate cross-DB khỏi luồng move, và dọn dữ liệu mồ côi do các lần migrate fail để lại.

## Requirements

**Functional**
- `mfs_move_all` **không còn gọi** `channel_migrate_moved_scope`
- UI luôn dùng `workspace_move`, bỏ nhánh chọn service theo thread
- Không còn `file_thread` mồ côi (row có `file_nid` không tồn tại trong `media`)
- Lineage kẹt `failed`/`compensation_failed` được xử lý

**Non-functional**
- Có backup trước mọi thao tác ghi
- Việc gỡ phải đảo ngược được — giữ khả năng quay lại nếu Phase 4 phát hiện vấn đề

## Architecture

### Quyết định: gỡ lời gọi, giữ file proc

User chọn "cách tốt nhất". Cân nhắc:

| Lựa chọn | Ưu | Nhược |
|---|---|---|
| Xoá hẳn proc + file | gọn nhất | mất 1200 dòng logic đã viết kỹ; muốn quay lại phải viết lại |
| Giữ nguyên lời gọi, thêm cờ tắt | quay lại dễ | thêm cờ = thêm đường code chết, và cờ này sẽ không ai bật lại |
| **Gỡ lời gọi trong `mfs_move_all`, giữ file proc trong repo** | luồng sạch, git giữ lịch sử, muốn quay lại chỉ cần thêm lại 5 dòng | proc tồn tại trong DB mà không ai gọi |

→ Chọn cách 3. Proc còn trong DB không gây hại (không ai gọi), và giữ file trong repo nghĩa là không mất công sức đã bỏ ra. Không thêm cờ vì cờ tạo hai đường code phải bảo trì.

Kèm theo: comment trong `mfs_move_all` ghi rõ **vì sao** gỡ, trỏ tới plan này. Người sau đọc sẽ hiểu đây là quyết định có chủ đích, không phải sót.

### Dữ liệu cần dọn (đo trên stage)

| Loại | Số lượng | Xử lý |
|---|---|---|
| `file_thread` mồ côi ở WS đích | 2 (`9e4794599e47945d`, `d9708dcdd9708dd2`) | Xoá — file tương ứng không tồn tại, thread không mở được |
| `channel` rows của 2 thread đó | 4 | Xoá cùng thread |
| Lineage `state='failed'` | ~6 | Reset về `active` hoặc xoá — chúng chặn move file đó mãi mãi |
| `yp.file_move_saga` (bảng + 11 rows) | 1 bảng | **Xoá hẳn** (user đã chốt) — kèm các proc saga |
| Staging tồn đọng | 4 thư mục | `mv` sang chỗ tạm |

### Xoá hạ tầng saga

User chốt: xoá. Danh sách phải gỡ:

| Đối tượng | Ghi chú |
|---|---|
| `yp.file_move_saga` (bảng) | dump ra file lưu trữ trước khi `DROP TABLE` |
| `file_move_saga_begin`, `_get`, `_transition` | 3 proc |
| `file_move_source_snapshot`, `_destination_snapshot`, `_return_precheck`, `file_move_thread_position` | **kiểm trước** — có thể còn dùng ngoài saga |
| `move_cross_hub()` + helper trong `media.js` | `_beginCrossHubMove`, `_runCrossHubMove`, `_compensateCrossHubMove`, `_failCrossHubMove`, `_transitionCrossHubMove`, `_emitCrossHubMoveEvents`, `_emitCrossHubCompensationEvents`, `_fileMoveResult` |
| `service/lib/mfs-move-result.js` | chỉ saga dùng — grep xác nhận |
| entry `move_cross_hub` trong `acl/media.json` | |

**`file_move_saga_transition` có tác dụng phụ**: nó cập nhật `file_thread_lineage.state` (`:115-122`). Xoá nó thì mất đường reset lineage `failed`/`expired`. Bước 8 phải xử lý xong lineage kẹt **trước**, hoặc chuyển logic đó sang proc khác.

**Lưu ý:** 2 `file_thread` mồ côi này là hệ quả của compensation fail — message của chúng đã bị compensation kéo về nguồn hoặc mất. Phải kiểm từng cái trước khi xoá: nếu message chỉ còn ở đích thì phải chuyển về nguồn trước, không xoá thẳng.

## Related Code Files

- Sửa: `common/procedures/mfs/mfs_move_all.sql` — gỡ khối `CALL channel_migrate_moved_scope` (`:280-320`)
- Sửa: `ui-team/src/drumee/builtins/media/file-thread-move-route.js` — bỏ nhánh chọn service
- Sửa: `ui-team/src/drumee/builtins/media/interact.js:1367-1400` — bỏ fetch `file_thread_info` + chọn service
- Sửa: `server-team/service/private/media.js` — gỡ `move_cross_hub()` và các helper saga
- Sửa: `yellow_page/procedures/mfs/file_move_readiness.sql` — bớt kiểm proc thuộc đường migrate
- Giữ nguyên file: `common/procedures/channel/channel_migrate_moved_scope.sql`
- Tạo: script dọn dẹp trong `patches/`

## Implementation Steps

1. **Backup** — `mysqldump --routines` cho DB liên quan + `yp.file_move_saga` + `yp.file_thread_lineage`.
2. **Kiểm từng thread mồ côi trước khi xoá** — với mỗi row, đếm message ở đích và ở nguồn. Nếu message chỉ còn ở đích → chuyển về nguồn trước (pattern đã làm thủ công thành công ở phiên trước), rồi mới xoá.
3. **Gỡ khối CALL** trong `mfs_move_all.sql`. Thay bằng comment giải thích + link plan này.
4. **Apply `mfs_move_all` mới** cho toàn bộ DB sống — dùng `file-move-backfill.sh` (đã có, đã chạy đúng 144 DB).
5. **Sửa UI** — `selectCrossWorkspaceMoveService` luôn trả `workspace_move`; hoặc xoá hàm và gọi thẳng. Bỏ luôn `isMoveResultSuccessful` (chỉ dùng cho saga).
6. **Gỡ `move_cross_hub()`** và helper saga khỏi `media.js`. Gỡ entry khỏi `acl/media.json`.
7. **Thu gọn `file_move_readiness`** — bỏ `channel_migrate_moved_scope`, `file_move_*snapshot`, `file_move_return_precheck` khỏi danh sách nếu chúng chỉ phục vụ saga. **Kiểm trước**: `channel_file_thread_*` vẫn cần cho đọc/ghi thread thường.
8. **Reset lineage kẹt TRƯỚC khi xoá saga proc** — `state='failed'` → `active`, hoặc xoá row nếu file không còn. Thứ tự quan trọng: `file_move_saga_transition` là nơi chứa logic reset, xoá nó trước thì mất công cụ.
9. **Xoá hạ tầng saga** — dump `yp.file_move_saga` ra file lưu trữ, `DROP TABLE`, gỡ 3 proc saga, gỡ `move_cross_hub()` + helper khỏi `media.js`, gỡ `mfs-move-result.js`, gỡ entry ACL.
10. **Kiểm trước khi xoá 4 proc snapshot/position** — grep xem còn ai gọi ngoài saga không. `file_move_thread_position` có thể còn hữu ích cho chẩn đoán; giữ nếu còn consumer.
11. **Dọn staging** — `mv` sang `/tmp`, giữ 7 ngày.
12. **Cập nhật `patches/manifest.txt`** — bỏ entry của thứ đã xoá.

## Success Criteria

- [x] `mfs_move_all` trong mọi DB sống không còn chứa `channel_migrate_moved_scope`
- [x] Move cross-WS không tạo dòng nào trong `yp.file_move_saga`
- [x] Không còn thread mồ côi **không giải thích được** (0/1009 DB). 1 thread rỗng đã xoá; 4 thread còn message được gán lineage `orphaned` thay vì xoá — xem đầu file. Query gốc:
  ```sql
  SELECT COUNT(*) FROM `<db>`.file_thread ft
  WHERE NOT EXISTS (SELECT 1 FROM `<db>`.media m WHERE m.id = ft.file_nid);
  ```
- [x] `yp.file_thread_lineage` không còn `state='failed'`
- [x] `yp.file_move_saga` đã `DROP`, có dump lưu trữ trước khi xoá
- [x] 3 proc saga đã gỡ; `move_cross_hub` không còn trong `media.js` lẫn ACL
- [x] Không message nào bị mất trong quá trình dọn — đếm trước/sau khớp
- [x] `.file-move-staging/` sạch
- [x] UI không còn gọi `channel.file_thread_info` trong luồng move (vẫn gọi ở chỗ khác — card info)

## Risk Assessment

| Rủi ro | Tín hiệu | Phản ứng |
|---|---|---|
| Xoá thread mồ côi làm mất message duy nhất còn lại | Đếm message giảm | Bước 2 bắt buộc: kiểm message ở đâu TRƯỚC khi xoá. Không xoá thẳng |
| Gỡ `CALL` làm hỏng `mfs_move_all` | Move thường lỗi | `file-move-backfill.sh` có snapshot + rollback đã test thật. Chạy 1 DB trước, smoke test, rồi mới `--all` |
| Thu gọn `readiness` bỏ nhầm proc còn dùng | Thread không mở được sau đó | Bước 7 kiểm từng proc: grep xem còn ai gọi không, trước khi bỏ khỏi danh sách |
| Reset lineage `failed` che mất bug thật | — | Ghi lại danh sách trước khi reset. Nếu Phase 4 gặp lỗi lạ, đối chiếu |
| Gỡ `move_cross_hub` khi UI cũ còn cache | Client cũ gọi service không tồn tại | Giữ endpoint trả lỗi rõ ràng một thời gian, hoặc phối hợp deploy UI trước |

**Giả định có thể sai:** "proc còn trong DB mà không ai gọi thì vô hại". Đúng trừ khi có đường nào khác gọi nó. Bước 3 phải grep toàn repo xác nhận `mfs_move_all` là caller duy nhất.
