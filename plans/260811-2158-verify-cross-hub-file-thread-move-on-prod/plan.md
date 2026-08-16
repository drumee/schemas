---
title: "Verify cross-hub file thread move on prod"
description: "Chẩn đoán đúng nguyên nhân forward-move fail, chứng minh flow trên stage, rồi đảm bảo prod an toàn"
status: pending
priority: P1
effort: "2-3d"
tags: [mfs, file-thread, cross-hub-move, deployment]
created: 2026-08-11
---

# Verify cross-hub file thread move on prod

## Overview

Flow `media.move_cross_hub` (move 1 file có chat thread sang workspace khác) **chưa từng chạy thành công lần nào** — `yp.file_move_saga` trên stage không có dòng `state='committed'`.

**Nguyên nhân forward-move fail hiện CHƯA XÁC ĐỊNH.** Plan này bắt đầu bằng chẩn đoán, không bằng sửa.

## Hiện trạng đã kiểm chứng

### Hai vấn đề RIÊNG BIỆT

**(A) Compensation fail — đã xác định**

`_compensateCrossHubMove` gọi `mfs_move_all` của **DB ĐÍCH** (`server-team/service/private/media.js:940-946`). DB đích `6_fb610d28fb610d29` thiếu bản mới (không có `channel_migrate_moved_scope`) → compensation di chuyển được media row nhưng không mang `channel`/`file_thread` ngược về nguồn → `channel_file_thread_rebind_returned_file` trả failed → `COMPENSATION_THREAD_REBIND_FAILED`.

Bằng chứng trạng thái hiện tại ở đích:

| file_nid | root_message_id | media row | channel rows |
|---|---|---|---|
| `9e4794599e47945d` | 25db0c3525db0c37 | **0** | 2 |
| `d9708dcdd9708dd2` | d30195dbd30195e2 | **0** | 2 |

Media đi (compensation làm được), thread ở lại (compensation không làm được) → mồ côi.

**(B) Forward verify fail — CHƯA XÁC ĐỊNH**

Forward move gọi `mfs_move_all` của **DB NGUỒN** (`media.js:814-820`). Nguồn `a_99728fec99728fed` **CÓ** bản mới (verified). Đích có đủ mọi artifact cần cho forward:

| Artifact ở đích | Có? |
|---|---|
| `channel_migrate_moved_scope` proc | ✓ |
| bảng `file_thread` | ✓ |
| cột `channel.file_thread_id` | ✓ |
| bảng `channel_migrate_log` | ✓ |

Hơn nữa, migrate **đã chạy thành công** — `CALL 6_fb610d28fb610d29.file_move_thread_position('d9708dcdd9708dd2', NULL)` trả:

```
root_identity_count = 1
stale_child_identity_count = 0
```

Đúng hai điều kiện mà `isCompleteMfsThreadMigration` (`server-team/service/lib/mfs-move-result.js:24-28`) yêu cầu. `channel_migrate_log` ở đích **rỗng** — mà proc chỉ ghi log khi có lỗi hoặc leftover > 0, nên rỗng nghĩa là migrate chạy sạch.

**Vậy tại sao verify fail?** Điều kiện thứ ba là `!sourcePosition` — nguồn phải rỗng. Chưa đo được trạng thái nguồn tại thời điểm verify (chỉ đo được sau khi compensation đã chạy). Đây là điều Phase 1 phải xác định.

### Giả thuyết bị loại bỏ (đã kiểm chứng — đừng lặp lại)

1. **"DB đích thiếu `mfs_move_all` gây forward fail"** — SAI. Forward dùng proc của nguồn (`media.js:814-820`); nguồn có bản mới. Thiếu ở đích chỉ ảnh hưởng compensation.
2. **"`channel_migrate_moved_scope` cũ"** — SAI. Chênh lệch 26642 vs 37622 bytes **chỉ là comment**. Feature markers (`_f9_orphans`, `capture_then_delete`, `read_channel`, `_migrate_src_file_thread`, `_src_has_ft_col`, `_thread_infra_ok`) khớp số lần xuất hiện giữa deployed và source.
3. **"Template factory chứa bản cũ"** — SAI. `templates/factory/hub.sql:17722`, `drumate.sql:21441` đều có lời gọi.
4. **"Lệch schema `file_thread`"** — SAI. `DESC` hai bên khớp.

### Phạm vi backfill (cho vấn đề A)

`mfs_move_all` thiếu bản mới ở 121/1202 DB, phân loại theo `yp.entity`:
- **5 DB sống** — phạm vi thật
- **116 DB mồ côi** — không entity, `media=0`, `file_thread=0`, proc từ 2024-06-14. Rác

| DB | entity | type | area |
|---|---|---|---|
| `6_fb610d28fb610d29` | fb610c4ffb610c57 | hub | share |
| `a_04520acc04520acd` | 045209fa045209fe | organization | public |
| `8_7674131a7674131b` | 767412487674124c | hub | private |
| `a_ced26d2fced26d30` | ced26c4bced26c50 | hub | share |
| `1_cb18b513cb18b514` | cb18b43dcb18b442 | drumate | personal |

**Lưu ý:** `stale_live` chỉ đo một proc. Defect thật là cả batch 26/07 (proc + bảng + cột). Phase 3 phải đo toàn batch, không chỉ `mfs_move_all`.

## Goals

| # | Goal | Priority |
|---|------|----------|
| 1 | Xác định nguyên nhân forward-verify fail bằng thực nghiệm có kiểm soát | P1 |
| 2 | Có ít nhất 1 saga `state='committed'` trên stage | P1 |
| 3 | Đo prod theo toàn batch artifact, không chỉ một proc | P1 |
| 4 | Prod ở trạng thái mọi DB sống move được, verified | P1 |
| 5 | Đóng gap: `_beginCrossHubMove` không precondition-check DB đích | P2 |

## Phases

| # | Phase | Status |
|---|-------|--------|
| 1 | [Phase 1: Chẩn đoán forward-verify fail](./phase-01-start.md) | Pending |
| 2 | [Phase 2: Sửa + chứng minh flow trên stage](./phase-02-prove-flow-on-stage.md) | Pending |
| 3 | [Phase 3: Khảo sát prod (read-only)](./phase-03-survey-prod-readonly.md) | Pending |
| 4 | [Phase 4: Backfill + verify prod](./phase-04-backfill-and-verify-prod.md) | Pending |

Phase 3 **không phụ thuộc** Phase 1/2 — read-only, chạy song song ngay khi có prod host.
Phase 2 chặn Phase 4.

## Success Criteria

- [ ] Phase 1 kết luận được nguyên nhân forward-verify fail, có bằng chứng từ lần chạy được instrument
- [ ] Stage: `SELECT COUNT(*) FROM yp.file_move_saga WHERE state='committed'` ≥ 2
- [ ] Stage: message đủ, thứ tự đúng, tác giả đúng, nguồn sạch, staging sạch — cả hai chiều
- [ ] Stage: test bao gồm ca message **không có** `metadata._file_nid` (xem Risk M1 ở Phase 2)
- [ ] Prod: đo đủ toàn batch artifact, không chỉ `mfs_move_all`
- [ ] Prod: saga tồn đọng (nếu có) được phân loại và user duyệt cách xử lý
- [ ] Backup có `--routines` trước mọi thao tác ghi

## Quy trình patch bắt buộc (áp dụng mọi phase có ghi)

Red-team phát hiện 3 điểm nguy hiểm trong công cụ patch — bắt buộc tuân thủ:

1. **KHÔNG dùng `bin/patch-from-file` như mặc định.** Script truyền `--orphan=remove --force`; `bin/patch.js:69-76` khi gặp lỗi 1049 sẽ gọi `entity_delete` → `DROP DATABASE` + xoá 10 bảng identity, không prompt. Dùng `node bin/patch.js` với cờ tường minh, hoặc `mysql <db> < file`.
2. **Backup phải có `--routines`.** `mysqldump` mặc định không dump stored procedure. Repo tự biết điều này (`bin/make-templates`, `offline/factory/index.js:168`).
3. **Rollback KHÔNG dùng full-DB restore.** Snapshot `SHOW CREATE PROCEDURE` từng DB trước khi patch, re-apply body cũ nếu cần. Restore full-DB sẽ mất dữ liệu người dùng phát sinh sau dump.

Thêm: `bin/patch-from-file:5-8` chạy `SET GLOBAL character_set_collations` — thay đổi cấu hình toàn server, tồn tại tới khi restart. Ghi nhận nếu dùng.

## Open Questions

1. **Prod ở host nào?** `~/.ssh/config` chỉ có `drumee` (drumee.in — chính là stage) và `csmlog`. **Blocking cho Phase 3.**
2. **Move-file-có-thread đã bật trên prod chưa?** Kiểm cả `acl/media.json` và front-end, không chỉ grep `media.js` — grep >0 vẫn có thể chưa reachable.
3. **Có ai khác đang dùng stage `aaron` không?** Phase 1/2 ghi vào instance đó.
4. Phase 4 mục 9 (đóng gap precondition-check) thuộc plan này hay tách riêng? Nó sửa code `server-team`, khác bản chất với phase vận hành.

<!-- slug: verify-cross-hub-file-thread-move-on-prod -->
