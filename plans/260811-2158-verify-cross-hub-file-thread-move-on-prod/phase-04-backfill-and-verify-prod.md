---
title: "Phase 4: Backfill + verify prod"
status: todo
phase: 4
priority: P1
effort: "3-5h"
dependencies: [2, 3]
---

# Phase 4: Backfill + verify prod

## Overview

Đưa prod về trạng thái mọi DB sống move được, verify bằng dữ liệu. Chỉ chạy sau khi Phase 2 chứng minh flow đúng và Phase 3 cho biết prod cần gì.

Nội dung cụ thể **phụ thuộc kết quả Phase 3** — phase này định nghĩa khung và ràng buộc; số liệu thật điền sau khảo sát.

## Requirements

**Functional**
- Mọi DB sống trên prod có đủ batch artifact (không chỉ `mfs_move_all`)
- Saga/lineage/file mồ côi tồn đọng được xử lý hoặc user quyết định bỏ qua
- Có ít nhất một move thật trên prod `committed`, verified — nếu tính năng đã bật

**Non-functional**
- Backup có `--routines`, verify đọc được — bắt buộc
- Ngoài giờ cao điểm
- Mỗi bước có đường lùi khả thi (không phải full-DB restore)
- Thao tác lên dữ liệu khách cần user duyệt từng ca

## Architecture

Cùng cơ chế Phase 2, khác mức thận trọng: prod có dữ liệu thật.

### Thứ tự: xử lý dữ liệu hỏng trước, backfill sau

Lý do **không** phải "backfill trigger retry" — không có cơ chế nào như vậy. Không worker nền nào đụng `file_move_saga`; retry chỉ xảy ra khi client gọi lại kèm `operation_id`, và saga terminal bị chặn ngay (`media.js:660-662`).

Lý do thật: xử lý dữ liệu khách là việc cần user duyệt và có thể mất thời gian. Backfill trước làm thay đổi hành vi hệ thống giữa lúc đang điều tra một sự cố dữ liệu — khó truy nguyên nếu có gì đó lệch.

### Rủi ro không lùi được

`file_move_saga_transition.sql:58-67` không có transition **ra khỏi** `committed`/`compensated`/`failed`/`expired`/`compensation_failed`. Cộng với `media.js:709` chặn saga mới trên lineage không `active`, và `file_move_saga_transition.sql:115-118` chỉ reset lineage cho `failed`/`expired` — **không** cho `compensation_failed`.

Nghĩa là: một lần test hỏng trên prod → file đó **bị khoá vĩnh viễn** khỏi cross-hub move, không có proc gỡ. Bước test thật (bước 7) phải dùng workspace/file dùng-một-lần, và chấp nhận saga row là rác vĩnh viễn. **Không test trên file khách hàng.**

### Gap precondition-check

`_beginCrossHubMove` (`media.js:672-748`) **không kiểm tra DB đích có đủ procedure** trước khi khởi saga. Đây là lý do lỗi biểu hiện thành "move mất file" thay vì "từ chối move ngay từ đầu".

Fix code (`server-team`), khác bản chất với phase vận hành. Xem Open Question #4 ở `plan.md`.

## Related Code Files

- Sửa (nếu user chọn làm trong plan này): `server-team/service/private/media.js` — precondition check trong `_beginCrossHubMove`
- Đọc: `common/procedures/mfs/mfs_move_all.sql`
- Tạo: report tại `plans/reports/`

## Implementation Steps

1. **Gate** — xác nhận Phase 2 có saga `committed` (cả ca 1 và ca 2) và Phase 3 report đã xong. Thiếu → dừng.
2. **Backup prod** — `mysqldump --routines` cho DB liên quan + `yp.file_move_saga` + `yp.file_thread_lineage`. Verify dump chứa `CREATE PROCEDURE`.
3. **Snapshot proc cũ** — `SHOW CREATE PROCEDURE` cho mọi proc sắp thay, từng DB. Đây là đường lùi.
4. **Xử lý tồn đọng** (nếu Phase 3 tìm thấy) — với mỗi saga không terminal-success:
   - Xác định file thật ở đâu (media row, file vật lý, staging)
   - Trình bày với user từng ca: mất gì, khôi phục được không, đề xuất cách
   - **Chờ user duyệt từng ca.** Dùng `mv`/copy, không `DELETE`
5. **Backfill artifact thiếu** theo danh sách Phase 3. Theo lô nhỏ, verify sau mỗi lô. Dùng `node bin/patch.js` với cờ tường minh hoặc `mysql <db> < file` — **không** `bin/patch-from-file` mặc định (mang `--orphan=remove --force`, có thể `DROP DATABASE`).
6. **Verify backfill** — chạy lại query Phase 3 bước 3+4, phải trả rỗng.
7. **Smoke test** — move một file cùng-workspace, xác nhận đường move thường không hỏng.
8. **Test thật cross-workspace** — nếu tính năng đã bật: workspace nội bộ, file test dùng-một-lần, chạy đủ checklist Phase 2 (cả ca 1 và ca 2).
9. **Dọn staging tồn đọng** — `mv` sang chỗ tạm, giữ 7 ngày. Kiểm cả hai hub mỗi chiều move.
10. **Gap precondition-check** — theo quyết định user: implement, hay tách plan riêng và ghi nhận ở đây.
11. **Report cuối** — trạng thái trước/sau, đã làm gì, còn lại gì.

## Success Criteria

- [ ] Backup prod có `--routines`, verify đọc được
- [ ] Snapshot proc cũ tồn tại cho mọi DB sắp thay
- [ ] Query Phase 3 bước 3+4 trả rỗng sau backfill
- [ ] Smoke test move cùng-workspace pass
- [ ] Mọi saga tồn đọng có kết luận: đã xử lý / user quyết bỏ qua / chuyển plan khác
- [ ] Nếu tính năng đã bật: ≥1 saga `committed` trên prod, đủ bằng chứng như Phase 2
- [ ] Không file khách nào mất thêm trong quá trình
- [ ] Report cuối có số liệu trước/sau

## Risk Assessment

| Rủi ro | Tín hiệu | Phản ứng |
|---|---|---|
| `bin/patch-from-file` xoá entity prod | Entity biến mất khỏi `yp.entity` | **Phòng ngừa:** không dùng script đó. `patch.js:69-76` gặp lỗi 1049 → `entity_delete` → `DROP DATABASE` + xoá 10 bảng identity, `--force` bỏ prompt. Xảy ra khi entity còn nhưng schema tạm không truy cập được |
| Backfill hỏng proc → chặn cả move thường | Smoke test bước 7 fail | Re-apply body cũ từ snapshot bước 3. Lô nhỏ để giới hạn thiệt hại |
| Xử lý tồn đọng làm mất thêm dữ liệu | — | Không `DELETE`. `mv`/copy. Mọi thao tác lên dữ liệu khách phải user duyệt |
| Test bước 8 khoá vĩnh viễn file | Lineage `compensation_failed` | Chỉ dùng file test dùng-một-lần. Không test trên file khách |
| User đang move giữa chừng lúc backfill | Saga `copy_pending`/`source_removed` ctime gần | Chờ saga kết thúc (`expires_at`) hoặc làm ngoài giờ |
| `SET GLOBAL character_set_collations` đổi cấu hình server | — | `bin/patch-from-file:5-8` làm việc này, tồn tại tới restart. Nếu buộc phải dùng: ghi lại giá trị cũ trước |
| Backfill xong vẫn fail vì nguyên nhân riêng của prod | Bước 8 fail dù stage pass | Dừng. So sánh môi trường: version server, version proc, schema. Không chạy lại patch một cách mù quáng |
| Template pool vẫn phát tán defect | Backfill xong nhưng DB mới tạo lại thiếu | Backfill là vá tạm. Cần verify template hiện tại của prod đã đúng — hoặc restart factory để rebuild template |

**Giả định có thể sai:** "prod cùng bản chất vấn đề với stage". Phase 3 bước 2–4 kiểm version code và artifact. Nếu prod khác → viết lại phase này theo thực tế prod, không copy từ stage.
